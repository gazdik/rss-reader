# RSS Reader

A modern, frontend-only RSS reader application built with React, TypeScript, and IndexedDB. Manage your RSS feeds and read articles in a clean, intuitive interface.

## Features

- **Frontend-Only Architecture**: No backend required - everything runs in your browser
- **IndexedDB Storage**: All feeds and articles are stored locally in your browser
- **RSS & Atom Support**: Compatible with both RSS and Atom feed formats
- **CORS Proxy**: Automatically fetches feeds through a CORS proxy
- **Feed Management**: Add, delete, and refresh RSS feeds
- **Article Reading**: Read articles with a clean interface
- **Mark as Read/Unread**: Track which articles you've read
- **Star Articles**: Bookmark important articles
- **Responsive Design**: Modern UI built with TailwindCSS

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm or yarn

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/rss-reader.git
cd rss-reader
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

4. Open your browser and navigate to `http://localhost:5173`

### Building for Production

```bash
npm run build
```

The built files will be in the `dist` directory.

### Preview Production Build

```bash
npm run preview
```

## Usage

### Adding RSS Feeds

1. Enter an RSS feed URL in the input field at the top of the sidebar
2. Click the "+" button to add the feed
3. The feed will be fetched and articles will be loaded automatically

### Managing Feeds

- **Refresh Feed**: Click the refresh icon next to a feed to fetch new articles
- **Refresh All**: Click the refresh icon at the top to refresh all feeds
- **Delete Feed**: Click the trash icon next to a feed to remove it

### Reading Articles

- Click on an article in the list to view its details
- Click the star icon to bookmark an article
- Click the circle/check icon to mark as read/unread
- Click "Open Original Article" to view the article on its source website

## Deployment

This project is configured to automatically deploy to GitHub Pages using GitHub Actions.

### Setup GitHub Pages Deployment

1. Go to your repository settings
2. Navigate to "Pages" in the sidebar
3. Under "Build and deployment", select "GitHub Actions" as the source
4. Push to the `main` branch to trigger deployment

The site will be available at `https://yourusername.github.io/rss-reader/`

### Manual Deployment

You can also deploy manually to any static hosting service:

```bash
npm run build
```

Then upload the contents of the `dist` directory to your hosting provider.

## Technology Stack

- **React 18**: UI framework
- **TypeScript**: Type-safe JavaScript
- **Vite**: Build tool and dev server
- **TailwindCSS**: Utility-first CSS framework
- **IndexedDB (idb)**: Browser database for local storage
- **Lucide React**: Icon library
- **date-fns**: Date formatting utilities

## Project Structure

```
rss-reader/
├── src/
│   ├── components/          # React components
│   │   ├── ui/             # Reusable UI components
│   │   ├── ArticleDetail.tsx
│   │   ├── ArticleList.tsx
│   │   └── FeedList.tsx
│   ├── lib/                # Utility functions
│   ├── App.tsx             # Main application component
│   ├── db.ts               # IndexedDB operations
│   ├── rssService.ts       # RSS fetching and parsing
│   ├── types.ts            # TypeScript type definitions
│   ├── main.tsx            # Application entry point
│   └── index.css           # Global styles
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions workflow
├── index.html              # HTML entry point
├── vite.config.ts          # Vite configuration
├── tailwind.config.js      # Tailwind configuration
├── tsconfig.json           # TypeScript configuration
└── package.json            # Project dependencies

```

## Browser Support

This application requires a modern browser with support for:
- IndexedDB
- ES2020+ JavaScript features
- CSS Grid and Flexbox

Tested on:
- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## Known Limitations

- **CORS Proxy**: The app uses a public CORS proxy (allorigins.win) which may have rate limits
- **Local Storage**: All data is stored locally in your browser - clearing browser data will delete your feeds
- **No Sync**: Feeds and articles are not synchronized across devices

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Acknowledgments

- RSS feed parsing inspired by various RSS reader implementations
- UI design inspired by modern news aggregators
- Icons provided by Lucide React
