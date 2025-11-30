import { useState } from 'react';
import { RSSFeed } from '@/types';
import { Button } from './ui/Button';
import { Input } from './ui/Input';
import { Rss, Trash2, RefreshCw, Plus } from 'lucide-react';

interface FeedListProps {
  feeds: RSSFeed[];
  selectedFeedId: string | null;
  onSelectFeed: (feedId: string | null) => void;
  onAddFeed: (url: string) => Promise<void>;
  onDeleteFeed: (feedId: string) => Promise<void>;
  onRefreshFeed: (feedId: string) => Promise<void>;
  onRefreshAll: () => Promise<void>;
  unreadCounts: Record<string, number>;
}

export function FeedList({
  feeds,
  selectedFeedId,
  onSelectFeed,
  onAddFeed,
  onDeleteFeed,
  onRefreshFeed,
  onRefreshAll,
  unreadCounts,
}: FeedListProps) {
  const [newFeedUrl, setNewFeedUrl] = useState('');
  const [isAdding, setIsAdding] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const handleAddFeed = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newFeedUrl.trim()) return;

    setIsAdding(true);
    try {
      await onAddFeed(newFeedUrl);
      setNewFeedUrl('');
    } catch (error) {
      alert(`Failed to add feed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setIsAdding(false);
    }
  };

  const handleRefreshAll = async () => {
    setIsRefreshing(true);
    try {
      await onRefreshAll();
    } finally {
      setIsRefreshing(false);
    }
  };

  return (
    <div className="w-80 border-r bg-muted/30 flex flex-col h-screen">
      <div className="p-4 border-b">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Rss className="w-5 h-5" />
            RSS Feeds
          </h2>
          <Button
            size="icon"
            variant="outline"
            onClick={handleRefreshAll}
            disabled={isRefreshing || feeds.length === 0}
            title="Refresh all feeds"
          >
            <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
          </Button>
        </div>

        <form onSubmit={handleAddFeed} className="flex gap-2">
          <Input
            type="url"
            placeholder="Add RSS feed URL..."
            value={newFeedUrl}
            onChange={(e) => setNewFeedUrl(e.target.value)}
            disabled={isAdding}
            className="flex-1"
          />
          <Button type="submit" size="icon" disabled={isAdding}>
            <Plus className="w-4 h-4" />
          </Button>
        </form>
      </div>

      <div className="flex-1 overflow-y-auto">
        <div className="p-2 space-y-1">
          <button
            onClick={() => onSelectFeed(null)}
            className={`w-full text-left px-3 py-2 rounded-md transition-colors ${
              selectedFeedId === null
                ? 'bg-primary text-primary-foreground'
                : 'hover:bg-accent'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="font-medium">All Articles</span>
              <span className="text-sm opacity-70">
                {Object.values(unreadCounts).reduce((a, b) => a + b, 0)}
              </span>
            </div>
          </button>

          {feeds.map((feed) => (
            <div
              key={feed.id}
              className={`group relative rounded-md transition-colors ${
                selectedFeedId === feed.id
                  ? 'bg-primary text-primary-foreground'
                  : 'hover:bg-accent'
              }`}
            >
              <button
                onClick={() => onSelectFeed(feed.id)}
                className="w-full text-left px-3 py-2"
              >
                <div className="flex items-center justify-between">
                  <span className="font-medium truncate pr-2">{feed.title}</span>
                  {unreadCounts[feed.id] > 0 && (
                    <span className="text-sm opacity-70">{unreadCounts[feed.id]}</span>
                  )}
                </div>
              </button>
              <div className="absolute right-2 top-1/2 -translate-y-1/2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-6 w-6"
                  onClick={(e) => {
                    e.stopPropagation();
                    onRefreshFeed(feed.id);
                  }}
                  title="Refresh feed"
                >
                  <RefreshCw className="w-3 h-3" />
                </Button>
                <Button
                  size="icon"
                  variant="ghost"
                  className="h-6 w-6"
                  onClick={(e) => {
                    e.stopPropagation();
                    if (confirm(`Delete feed "${feed.title}"?`)) {
                      onDeleteFeed(feed.id);
                    }
                  }}
                  title="Delete feed"
                >
                  <Trash2 className="w-3 h-3" />
                </Button>
              </div>
            </div>
          ))}
        </div>

        {feeds.length === 0 && (
          <div className="p-8 text-center text-muted-foreground">
            <Rss className="w-12 h-12 mx-auto mb-4 opacity-50" />
            <p>No feeds yet.</p>
            <p className="text-sm mt-2">Add your first RSS feed above!</p>
          </div>
        )}
      </div>
    </div>
  );
}
