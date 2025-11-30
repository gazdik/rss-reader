export interface RSSFeed {
  id: string;
  url: string;
  title: string;
  description?: string;
  link?: string;
  lastFetched?: Date;
  createdAt: Date;
}

export interface RSSArticle {
  id: string;
  feedId: string;
  title: string;
  link: string;
  description?: string;
  content?: string;
  pubDate?: Date;
  author?: string;
  guid: string;
  imageUrl?: string;
  read: boolean;
  starred: boolean;
  createdAt: Date;
}

export interface FeedWithArticles extends RSSFeed {
  articles: RSSArticle[];
  unreadCount: number;
}
