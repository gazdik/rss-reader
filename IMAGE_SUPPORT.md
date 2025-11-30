# Image Support in RSS Reader

The RSS Reader now automatically extracts and displays images from RSS and Atom feeds.

## How It Works

The application extracts images from multiple sources in RSS/Atom feeds:

### 1. Media RSS (media:content)
```xml
<media:content url="https://example.com/image.jpg" />
```

### 2. Media Thumbnail (media:thumbnail)
```xml
<media:thumbnail url="https://example.com/thumb.jpg" />
```

### 3. Enclosures (for podcasts and media feeds)
```xml
<enclosure url="https://example.com/image.jpg" type="image/jpeg" />
```

### 4. HTML Content Extraction
If no explicit image tags are found, the parser extracts the first `<img>` tag from:
- Article content (`content:encoded`, `content`)
- Article description

## Display Behavior

### Article List View
- Images are displayed at the top of each article card
- Fixed height of 192px (h-48) with object-cover for consistent layout
- Images that fail to load are automatically hidden
- Maintains aspect ratio while filling the container

### Article Detail View
- Full-width image display at the top of the article
- Natural height (h-auto) to preserve aspect ratio
- Rounded corners for visual appeal
- Graceful error handling for broken images

## Technical Implementation

### Data Model
The `RSSArticle` type includes an optional `imageUrl` field:
```typescript
interface RSSArticle {
  // ... other fields
  imageUrl?: string;
}
```

### Image Extraction
The `extractImageUrl()` function in `rssService.ts`:
1. Checks for media:content tags
2. Checks for media:thumbnail tags
3. Checks for image enclosures
4. Falls back to extracting from HTML content
5. Returns undefined if no image is found

### Error Handling
Images include an `onError` handler that:
- Hides the image element if loading fails
- Prevents broken image icons from displaying
- Maintains layout integrity

## Feed Compatibility

The image extraction works with popular feed formats including:
- **RSS 2.0** with Media RSS extensions
- **Atom 1.0** feeds
- Feeds with HTML content containing images
- Podcast feeds with image enclosures

## Examples of Feeds with Images

Try these feeds to see image support in action:
- **TechCrunch**: https://techcrunch.com/feed/
- **The Verge**: https://www.theverge.com/rss/index.xml
- **Wired**: https://www.wired.com/feed/rss
- **Ars Technica**: https://feeds.arstechnica.com/arstechnica/index

## Performance Considerations

- Images are loaded lazily by the browser
- Failed image loads don't block the UI
- Image URLs are stored in IndexedDB for offline reference
- No image processing or resizing is performed (uses original URLs)

## Future Enhancements

Potential improvements for image handling:
- Image caching for offline viewing
- Lazy loading with intersection observer
- Image gallery view for multiple images
- Thumbnail generation
- Image compression proxy
