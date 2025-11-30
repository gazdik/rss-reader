import { useState, useEffect } from 'react';
import { RSSFeed, RSSArticle } from './types';
import {
  getAllFeeds,
  addFeed as dbAddFeed,
  deleteFeed as dbDeleteFeed,
  getAllArticles,
  getArticlesByFeed,
  markArticleAsRead,
  toggleArticleStar,
  getUnreadCountByFeed,
} from './db';
import { fetchFeed, refreshFeed, refreshAllFeeds } from './rssService';
import { FeedList } from './components/FeedList';
import { ArticleList } from './components/ArticleList';
import { ArticleDetail } from './components/ArticleDetail';

function App() {
  const [feeds, setFeeds] = useState<RSSFeed[]>([]);
  const [articles, setArticles] = useState<RSSArticle[]>([]);
  const [selectedFeedId, setSelectedFeedId] = useState<string | null>(null);
  const [selectedArticle, setSelectedArticle] = useState<RSSArticle | null>(null);
  const [unreadCounts, setUnreadCounts] = useState<Record<string, number>>({});
  const [isLoading, setIsLoading] = useState(true);

  // Load feeds and articles on mount
  useEffect(() => {
    loadData();
  }, []);

  // Update unread counts when feeds or articles change
  useEffect(() => {
    updateUnreadCounts();
  }, [feeds, articles]);

  // Load articles when selected feed changes
  useEffect(() => {
    loadArticles();
  }, [selectedFeedId]);

  async function loadData() {
    try {
      const loadedFeeds = await getAllFeeds();
      setFeeds(loadedFeeds);
      await loadArticles();
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setIsLoading(false);
    }
  }

  async function loadArticles() {
    try {
      const loadedArticles = selectedFeedId
        ? await getArticlesByFeed(selectedFeedId)
        : await getAllArticles();
      setArticles(loadedArticles);
    } catch (error) {
      console.error('Error loading articles:', error);
    }
  }

  async function updateUnreadCounts() {
    const counts: Record<string, number> = {};
    for (const feed of feeds) {
      counts[feed.id] = await getUnreadCountByFeed(feed.id);
    }
    setUnreadCounts(counts);
  }

  async function handleAddFeed(url: string) {
    try {
      // Fetch feed to validate and get metadata
      const parsedFeed = await fetchFeed(url);

      const newFeed: RSSFeed = {
        id: crypto.randomUUID(),
        url,
        title: parsedFeed.title || url,
        description: parsedFeed.description,
        link: parsedFeed.link,
        createdAt: new Date(),
      };

      await dbAddFeed(newFeed);
      setFeeds([...feeds, newFeed]);

      // Refresh the feed to load articles
      await handleRefreshFeed(newFeed.id);
    } catch (error) {
      console.error('Error adding feed:', error);
      throw error;
    }
  }

  async function handleDeleteFeed(feedId: string) {
    try {
      await dbDeleteFeed(feedId);
      setFeeds(feeds.filter((f) => f.id !== feedId));
      if (selectedFeedId === feedId) {
        setSelectedFeedId(null);
      }
    } catch (error) {
      console.error('Error deleting feed:', error);
    }
  }

  async function handleRefreshFeed(feedId: string) {
    try {
      const feed = feeds.find((f) => f.id === feedId);
      if (!feed) return;

      const newCount = await refreshFeed(feed);
      await loadArticles();
      await updateUnreadCounts();

      if (newCount > 0) {
        console.log(`Added ${newCount} new articles from ${feed.title}`);
      }
    } catch (error) {
      console.error('Error refreshing feed:', error);
      throw error;
    }
  }

  async function handleRefreshAll() {
    try {
      const result = await refreshAllFeeds(feeds);
      await loadArticles();
      await updateUnreadCounts();

      if (result.total > 0) {
        alert(`Added ${result.total} new articles`);
      } else {
        alert('No new articles');
      }

      if (result.errors.length > 0) {
        console.error('Errors refreshing feeds:', result.errors);
      }
    } catch (error) {
      console.error('Error refreshing all feeds:', error);
    }
  }

  async function handleToggleRead(articleId: string, read: boolean) {
    try {
      await markArticleAsRead(articleId, read);
      setArticles(
        articles.map((a) => (a.id === articleId ? { ...a, read } : a))
      );
      if (selectedArticle?.id === articleId) {
        setSelectedArticle({ ...selectedArticle, read });
      }
    } catch (error) {
      console.error('Error toggling read status:', error);
    }
  }

  async function handleToggleStar(articleId: string) {
    try {
      await toggleArticleStar(articleId);
      setArticles(
        articles.map((a) =>
          a.id === articleId ? { ...a, starred: !a.starred } : a
        )
      );
      if (selectedArticle?.id === articleId) {
        setSelectedArticle({ ...selectedArticle, starred: !selectedArticle.starred });
      }
    } catch (error) {
      console.error('Error toggling star:', error);
    }
  }

  function handleSelectArticle(article: RSSArticle) {
    setSelectedArticle(article);
    if (!article.read) {
      handleToggleRead(article.id, true);
    }
  }

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <p className="text-lg text-muted-foreground">Loading...</p>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden">
      <FeedList
        feeds={feeds}
        selectedFeedId={selectedFeedId}
        onSelectFeed={setSelectedFeedId}
        onAddFeed={handleAddFeed}
        onDeleteFeed={handleDeleteFeed}
        onRefreshFeed={handleRefreshFeed}
        onRefreshAll={handleRefreshAll}
        unreadCounts={unreadCounts}
      />
      <ArticleList
        articles={articles}
        onToggleRead={handleToggleRead}
        onToggleStar={handleToggleStar}
        selectedArticle={selectedArticle}
        onSelectArticle={handleSelectArticle}
      />
      <ArticleDetail
        article={selectedArticle}
        onClose={() => setSelectedArticle(null)}
      />
    </div>
  );
}

export default App;
