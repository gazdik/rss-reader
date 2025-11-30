# Deployment Guide

## GitHub Pages Deployment

This project is configured to automatically deploy to GitHub Pages using GitHub Actions.

### Initial Setup

1. **Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Initial commit: RSS Reader app"
   git push origin main
   ```

2. **Enable GitHub Pages**:
   - Go to your repository on GitHub
   - Click on **Settings** → **Pages**
   - Under "Build and deployment":
     - Source: Select **GitHub Actions**
   - Save the settings

3. **Trigger the deployment**:
   - The workflow will automatically run on push to `main` branch
   - You can also manually trigger it from the **Actions** tab
   - Click on "Deploy to GitHub Pages" workflow
   - Click "Run workflow"

4. **Access your site**:
   - Once deployed, your site will be available at:
   - `https://[your-username].github.io/rss-reader/`
   - The URL will be shown in the GitHub Pages settings

### Updating the Base Path

If you want to deploy to a different repository name or path:

1. Update `vite.config.ts`:
   ```typescript
   export default defineConfig({
     plugins: [react()],
     base: '/your-repo-name/', // Change this
     // ...
   })
   ```

2. Commit and push the changes

### Manual Deployment

If you prefer to deploy manually:

```bash
# Build the project
npm run build

# The built files will be in the dist/ directory
# Upload these files to any static hosting service
```

### Troubleshooting

**404 errors on refresh**:
- GitHub Pages doesn't support client-side routing by default
- This app is a single-page application, so all routes work correctly

**Build fails**:
- Check the Actions tab for error logs
- Ensure all dependencies are in `package.json`
- Verify the build works locally: `npm run build`

**Assets not loading**:
- Verify the `base` path in `vite.config.ts` matches your repository name
- Check that the repository name is correct in the URL

### Environment Variables

This app doesn't require any environment variables as it's frontend-only.

### Custom Domain

To use a custom domain:

1. Add a `CNAME` file to the `public/` directory with your domain
2. Configure your domain's DNS settings to point to GitHub Pages
3. Enable "Enforce HTTPS" in repository settings

For more details, see: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
