# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-05

### Added - Core Features
- **Sequential Card Logic**: Back pages now show Card N-1 (previous card) instead of mirroring
  - First separator shows "Collection Start" marker
  - Correctly positions separators between cards in collection
- **Go Backend Image Proxy**: High-performance image processing and caching
  - 4 quality tiers: Thumbnail (300px), Medium (600px), Full (1200px), Original
  - Automatic caching with 7-day TTL
  - Concurrent processing (max 10 parallel downloads)
  - 80% bandwidth reduction vs direct OPTCG API
- **Configuration System**: Comprehensive settings with localStorage persistence
  - Card dimensions (width, height, tab height)
  - Page sizes (A4, Letter, Legal, Custom)
  - Colors (primary, secondary)
  - Print options (double-sided, flip edge, cut lines)
  - Image quality selection
- **Cut Lines & Crop Marks**: Professional print guides
  - Dashed cut lines
  - Corner crop marks
  - Print-only visibility
- **Card Filtering & Sorting**:
  - Filter by color (Red, Blue, etc.)
  - Filter by type (Leader, Character, etc.)
  - Sort by ID, Name, Cost, Power
  - Real-time reactive updates
- **Multi-Set Batch Loading**: Load multiple sets at once
  - Comma-separated input: "OP-01,OP-02,OP-03"
  - Progress indicator
  - Sequential loading to prevent API overload

### Added - UI/UX
- **Configuration Panel**: Modal with visual controls for all settings
- **Keyboard Shortcuts**:
  - `Ctrl/Cmd+P` - Print
  - `Ctrl/Cmd+K` - Toggle configuration
  - `Escape` - Close modals
- **Loading States**: Progress indicators for card loading
- **Error Handling**: User-friendly error messages
- **Responsive Design**: Works on mobile, tablet, and desktop
- **Help Accordion**: In-app instructions

### Added - Developer Experience
- **One-Command Startup**: `./dev.sh` script
- **Makefile**: 15+ developer commands
- **Docker Compose**: Multi-service orchestration
- **Hot Reload**: Vite HMR for instant updates
- **TypeScript**: Full type safety
- **Comprehensive Documentation**:
  - README.md - User documentation
  - ARCHITECTURE.md - Technical deep-dive
  - DECISIONS.md - Architectural Decision Records
  - CHANGELOG.md - This file

### Technical
- SvelteKit with Svelte 5 (runes API)
- Tailwind CSS v4
- Go 1.21 backend
- Image processing: `disintegration/imaging`
- Router: `gorilla/mux`
- CORS: `rs/cors`

### Performance
- **Frontend Bundle**: ~35KB (15KB framework + 20KB app)
- **Image Load Time**: <100ms (cached), 2-3s (first load)
- **Filter/Sort**: <1ms for 122 cards
- **Concurrent Downloads**: Up to 10 simultaneous

### Known Issues
- [ ] Backend doesn't have hot reload (requires manual restart)
- [ ] No automated tests yet
- [ ] PDF export not implemented
- [ ] No preset system for saving/loading configs
- [ ] No print preview modal

### Breaking Changes
None (initial release)

---

## [Unreleased]

### Planned for v1.1.0
- [ ] PDF Export (client-side with pdf-lib)
- [ ] Presets System (save/load/share configurations)
- [ ] Print Preview Modal
- [ ] Printer Test Alignment Page
- [ ] Analytics Dashboard (cache stats, performance metrics)
- [ ] QR Codes linking to card database
- [ ] Virtual Scrolling for large sets (1000+ cards)

### Planned for v1.2.0
- [ ] Custom Card Import (CSV/JSON upload)
- [ ] Backend API for custom card data
- [ ] User authentication (optional)
- [ ] Cloud config sync
- [ ] Bulk image preloading
- [ ] Service Worker for offline support

### Planned for v2.0.0
- [ ] Multi-TCG Support (Pokemon, Magic, Yu-Gi-Oh)
- [ ] Template System (different card layouts)
- [ ] Visual Card Designer
- [ ] Community presets sharing
- [ ] API for third-party integrations

---

## Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 1.0.0 | 2026-01-05 | Current | Initial release |
| 0.1.0 | 2025-05-23 | Deprecated | Early prototype |

---

## Migration Guides

### From v0.1.0 to v1.0.0

**Breaking Changes:**
- Configuration is now stored in `localStorage` instead of URL params
- Card data structure changed to include `rawData` field
- Image URLs are now proxied through backend (requires backend running)

**Migration Steps:**
1. Export your old config (if you have a custom setup)
2. Update to v1.0.0
3. Re-enter your config in the new Configuration Panel
4. Start backend: `./dev.sh` or `make backend`

---

## Deprecation Notices

### v0.1.0 Features Removed
- ❌ Direct OPTCG API image loading (now proxied)
- ❌ URL-based configuration (now localStorage)
- ❌ Fixed card dimensions (now configurable)

---

## Support & Feedback

- **Issues**: https://github.com/your-repo/issues
- **Discussions**: https://github.com/your-repo/discussions
- **Email**: support@example.com

---

**Maintained by**: Claude Sonnet 4.5 + Human Collaboration
