import { openDB, DBSchema, IDBPDatabase } from 'idb';
import { RSSFeed, RSSArticle } from './types';

interface RSSReaderDB extends DBSchema {
  feeds: {
    key: string;
    value: RSSFeed;
    indexes: { 'by-created': Date };
  };
  articles: {
    key: string;
    value: RSSArticle;
    indexes: { 
      'by-feed': string;
      'by-date': Date;
      'by-read': number;
      'by-starred': number;
    };
  };
}

let dbInstance: IDBPDatabase<RSSReaderDB> | null = null;

export async function getDB(): Promise<IDBPDatabase<RSSReaderDB>> {
  if (dbInstance) {
    return dbInstance;
  }

  dbInstance = await openDB<RSSReaderDB>('rss-reader-db', 1, {
    upgrade(db) {
      // Create feeds store
      const feedStore = db.createObjectStore('feeds', { keyPath: 'id' });
      feedStore.createIndex('by-created', 'createdAt');

      // Create articles store
      const articleStore = db.createObjectStore('articles', { keyPath: 'id' });
      articleStore.createIndex('by-feed', 'feedId');
      articleStore.createIndex('by-date', 'pubDate');
      articleStore.createIndex('by-read', 'read');
      articleStore.createIndex('by-starred', 'starred');
    },
  });

  return dbInstance;
}

// Feed operations
export async function addFeed(feed: RSSFeed): Promise<void> {
  const db = await getDB();
  await db.add('feeds', feed);
}

export async function updateFeed(feed: RSSFeed): Promise<void> {
  const db = await getDB();
  await db.put('feeds', feed);
}

export async function deleteFeed(id: string): Promise<void> {
  const db = await getDB();
  const tx = db.transaction(['feeds', 'articles'], 'readwrite');
  
  // Delete feed
  await tx.objectStore('feeds').delete(id);
  
  // Delete all articles from this feed
  const articles = await tx.objectStore('articles').index('by-feed').getAllKeys(id);
  for (const articleId of articles) {
    await tx.objectStore('articles').delete(articleId);
  }
  
  await tx.done;
}

export async function getFeed(id: string): Promise<RSSFeed | undefined> {
  const db = await getDB();
  return db.get('feeds', id);
}

export async function getAllFeeds(): Promise<RSSFeed[]> {
  const db = await getDB();
  return db.getAll('feeds');
}

// Article operations
export async function addArticle(article: RSSArticle): Promise<void> {
  const db = await getDB();
  await db.add('articles', article);
}

export async function addArticles(articles: RSSArticle[]): Promise<void> {
  const db = await getDB();
  const tx = db.transaction('articles', 'readwrite');
  
  for (const article of articles) {
    await tx.store.put(article);
  }
  
  await tx.done;
}

export async function updateArticle(article: RSSArticle): Promise<void> {
  const db = await getDB();
  await db.put('articles', article);
}

export async function deleteArticle(id: string): Promise<void> {
  const db = await getDB();
  await db.delete('articles', id);
}

export async function getArticle(id: string): Promise<RSSArticle | undefined> {
  const db = await getDB();
  return db.get('articles', id);
}

export async function getArticlesByFeed(feedId: string): Promise<RSSArticle[]> {
  const db = await getDB();
  return db.getAllFromIndex('articles', 'by-feed', feedId);
}

export async function getAllArticles(): Promise<RSSArticle[]> {
  const db = await getDB();
  const articles = await db.getAll('articles');
  return articles.sort((a, b) => {
    const dateA = a.pubDate?.getTime() || 0;
    const dateB = b.pubDate?.getTime() || 0;
    return dateB - dateA;
  });
}

export async function getUnreadArticles(): Promise<RSSArticle[]> {
  const db = await getDB();
  const articles = await db.getAllFromIndex('articles', 'by-read', 0);
  return articles.sort((a, b) => {
    const dateA = a.pubDate?.getTime() || 0;
    const dateB = b.pubDate?.getTime() || 0;
    return dateB - dateA;
  });
}

export async function getStarredArticles(): Promise<RSSArticle[]> {
  const db = await getDB();
  const articles = await db.getAllFromIndex('articles', 'by-starred', 1);
  return articles.sort((a, b) => {
    const dateA = a.pubDate?.getTime() || 0;
    const dateB = b.pubDate?.getTime() || 0;
    return dateB - dateA;
  });
}

export async function markArticleAsRead(id: string, read: boolean): Promise<void> {
  const db = await getDB();
  const article = await db.get('articles', id);
  if (article) {
    article.read = read;
    await db.put('articles', article);
  }
}

export async function toggleArticleStar(id: string): Promise<void> {
  const db = await getDB();
  const article = await db.get('articles', id);
  if (article) {
    article.starred = !article.starred;
    await db.put('articles', article);
  }
}

export async function getUnreadCountByFeed(feedId: string): Promise<number> {
  const db = await getDB();
  const articles = await db.getAllFromIndex('articles', 'by-feed', feedId);
  return articles.filter(a => !a.read).length;
}
