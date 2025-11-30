import { RSSFeed, RSSArticle } from './types';
import { addArticles, getArticlesByFeed, updateFeed } from './db';

// CORS proxy for fetching RSS feeds
const CORS_PROXY = 'https://api.allorigins.win/raw?url=';

interface ParsedFeed {
  title: string;
  description?: string;
  link?: string;
  items: ParsedItem[];
}

interface ParsedItem {
  title: string;
  link: string;
  description?: string;
  content?: string;
  pubDate?: string;
  author?: string;
  guid?: string;
}

function parseXML(xmlString: string): Document {
  const parser = new DOMParser();
  return parser.parseFromString(xmlString, 'text/xml');
}

function getTextContent(element: Element | null): string {
  return element?.textContent?.trim() || '';
}

function parseRSSFeed(xml: Document): ParsedFeed {
  const channel = xml.querySelector('channel');
  if (!channel) {
    throw new Error('Invalid RSS feed: no channel element found');
  }

  const title = getTextContent(channel.querySelector('title'));
  const description = getTextContent(channel.querySelector('description'));
  const link = getTextContent(channel.querySelector('link'));

  const items: ParsedItem[] = [];
  const itemElements = channel.querySelectorAll('item');

  itemElements.forEach((item) => {
    const parsedItem: ParsedItem = {
      title: getTextContent(item.querySelector('title')),
      link: getTextContent(item.querySelector('link')),
      description: getTextContent(item.querySelector('description')),
      content: getTextContent(item.querySelector('content\\:encoded')) || 
               getTextContent(item.querySelector('content')),
      pubDate: getTextContent(item.querySelector('pubDate')),
      author: getTextContent(item.querySelector('author')) || 
              getTextContent(item.querySelector('dc\\:creator')),
      guid: getTextContent(item.querySelector('guid')) || 
            getTextContent(item.querySelector('link')),
    };
    items.push(parsedItem);
  });

  return { title, description, link, items };
}

function parseAtomFeed(xml: Document): ParsedFeed {
  const feed = xml.querySelector('feed');
  if (!feed) {
    throw new Error('Invalid Atom feed: no feed element found');
  }

  const title = getTextContent(feed.querySelector('title'));
  const subtitle = getTextContent(feed.querySelector('subtitle'));
  const linkElement = feed.querySelector('link[rel="alternate"]') || feed.querySelector('link');
  const link = linkElement?.getAttribute('href') || '';

  const items: ParsedItem[] = [];
  const entryElements = feed.querySelectorAll('entry');

  entryElements.forEach((entry) => {
    const entryLink = entry.querySelector('link[rel="alternate"]') || entry.querySelector('link');
    const parsedItem: ParsedItem = {
      title: getTextContent(entry.querySelector('title')),
      link: entryLink?.getAttribute('href') || '',
      description: getTextContent(entry.querySelector('summary')),
      content: getTextContent(entry.querySelector('content')),
      pubDate: getTextContent(entry.querySelector('published')) || 
               getTextContent(entry.querySelector('updated')),
      author: getTextContent(entry.querySelector('author name')),
      guid: getTextContent(entry.querySelector('id')) || 
            (entryLink?.getAttribute('href') || ''),
    };
    items.push(parsedItem);
  });

  return { title, description: subtitle, link, items };
}

export async function fetchFeed(url: string): Promise<ParsedFeed> {
  try {
    const response = await fetch(CORS_PROXY + encodeURIComponent(url));
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const text = await response.text();
    const xml = parseXML(text);

    // Check for parsing errors
    const parserError = xml.querySelector('parsererror');
    if (parserError) {
      throw new Error('Failed to parse XML: ' + parserError.textContent);
    }

    // Detect feed type and parse accordingly
    if (xml.querySelector('rss') || xml.querySelector('channel')) {
      return parseRSSFeed(xml);
    } else if (xml.querySelector('feed')) {
      return parseAtomFeed(xml);
    } else {
      throw new Error('Unknown feed format');
    }
  } catch (error) {
    console.error('Error fetching feed:', error);
    throw error;
  }
}

export async function refreshFeed(feed: RSSFeed): Promise<number> {
  try {
    const parsedFeed = await fetchFeed(feed.url);
    
    // Update feed metadata
    const updatedFeed: RSSFeed = {
      ...feed,
      title: parsedFeed.title || feed.title,
      description: parsedFeed.description || feed.description,
      link: parsedFeed.link || feed.link,
      lastFetched: new Date(),
    };
    await updateFeed(updatedFeed);

    // Get existing articles for this feed
    const existingArticles = await getArticlesByFeed(feed.id);
    const existingGuids = new Set(existingArticles.map(a => a.guid));

    // Filter out articles that already exist
    const newArticles: RSSArticle[] = parsedFeed.items
      .filter(item => !existingGuids.has(item.guid || item.link))
      .map(item => ({
        id: crypto.randomUUID(),
        feedId: feed.id,
        title: item.title,
        link: item.link,
        description: item.description,
        content: item.content,
        pubDate: item.pubDate ? new Date(item.pubDate) : undefined,
        author: item.author,
        guid: item.guid || item.link,
        read: false,
        starred: false,
        createdAt: new Date(),
      }));

    if (newArticles.length > 0) {
      await addArticles(newArticles);
    }

    return newArticles.length;
  } catch (error) {
    console.error(`Error refreshing feed ${feed.title}:`, error);
    throw error;
  }
}

export async function refreshAllFeeds(feeds: RSSFeed[]): Promise<{ total: number; errors: string[] }> {
  let total = 0;
  const errors: string[] = [];

  for (const feed of feeds) {
    try {
      const newCount = await refreshFeed(feed);
      total += newCount;
    } catch (error) {
      errors.push(`${feed.title}: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  return { total, errors };
}
