# Card Separator Generator

A high-performance web application for generating printable card separators for trading card game collections. Built with SvelteKit, TypeScript, Tailwind CSS, and Go.

## Features

### Core Features ✅
- **Sequential Card Logic**: Front shows Card N, back shows Card N-1 for proper collection organization
- **Fetch Card Data**: Automatically pulls card information from the OPTCG API (One Piece TCG community database)
- **Double-Sided Printing**: Support for both single and double-sided separator printing
- **Printer Compatibility**: Handles both long-edge (book-style) and short-edge (calendar-style) flip configurations
- **Multi-Resolution Images**: Smart image optimization with 4 quality levels (thumbnail, medium, full, original)
- **Cut Lines & Crop Marks**: Professional print guides (print-only visibility)
- **Card Filtering**: Filter by color (Red, Blue, etc.) and type (Leader, Character, etc.)
- **Card Sorting**: Sort by ID, name, cost, or power
- **Multi-Set Loading**: Batch load multiple sets at once (e.g., "OP-01,OP-02,OP-03") with progress indicator
- **Presets System**: Save, load, export, and import your favorite configurations
- **Print Optimized**: A4/Letter/Legal/Custom page layouts with proper page breaks
- **Generic Design**: Works with any card set - just change the Set ID

### Backend Performance
- **Go Image Proxy**: High-performance Go backend for image processing and caching
- **Automatic Caching**: Downloaded images are cached locally to reduce API load
- **Multi-Resolution Support**: Generates 300px, 600px, 1200px thumbnails on-the-fly
- **Concurrent Processing**: Handles multiple image requests efficiently
- **CDN-Style Serving**: Fast image delivery with proper cache headers

### User Experience
- **Keyboard Shortcuts**: Ctrl+P (Print), Ctrl+K (Config), Shift+P (Presets), Esc (Close)
- **Real-Time Filtering**: Instant results with reactive filtering (<1ms)
- **Progress Indicators**: Always know what's happening during loading
- **Configuration Persistence**: Settings saved automatically to localStorage
- **Responsive Design**: Works on mobile, tablet, and desktop
- **Loading States**: User-friendly progress and error messages
- **In-App Help**: Instructions accordion with detailed usage guide

### Developer Experience
- **One-Command Setup**: `./dev.sh` or `make dev` to start everything
- **Hot Reload**: Frontend with instant Vite HMR updates
- **Docker Support**: Full Docker Compose setup for containerized development
- **Easy Configuration**: Comprehensive configuration system with localStorage persistence
- **TypeScript**: Full type safety across frontend and backend
- **Makefile**: 15+ convenient developer commands
- **Comprehensive Documentation**: ARCHITECTURE.md, DECISIONS.md, CHANGELOG.md (2000+ lines)

## Quick Start

### Prerequisites

- Node.js (v18+)
- Go (v1.21+)
- npm or pnpm
- (Optional) Docker & Docker Compose

### Option 1: Quick Start (Recommended)

```bash
# Clone the repository
git clone <repo-url>
cd card-separator

# Run the dev script (installs dependencies and starts everything)
./dev.sh
```

This will:
1. Check prerequisites
2. Install frontend and backend dependencies
3. Start the Go backend on :8080
4. Start the Vite frontend on :5173
5. Open [http://localhost:5173](http://localhost:5173) in your browser

### Option 2: Docker Compose

```bash
# Start everything with Docker
make dev
# or
docker-compose up --build
```

### Option 3: Manual Setup

```bash
# Install dependencies
make install
# or manually:
cd web && npm install && cd ..
cd backend && go mod download && cd ..

# Terminal 1: Start backend
make backend
# or
cd backend && go run src/main.go

# Terminal 2: Start frontend
make frontend
# or
cd web && npm run dev
```

## Usage

1. **Load Cards**:
   - Enter a single set ID (e.g., `OP-01`) OR
   - Multiple sets comma-separated (e.g., `OP-01,OP-02,OP-03`)
   - Click "Load Cards" and watch the progress indicator

2. **Filter & Sort** (Optional):
   - Filter by Color: "Red", "Blue", etc.
   - Filter by Type: "Leader", "Character", etc.
   - Sort by: ID, Name, Cost, or Power
   - Clear filters with the ✕ button

3. **Configure Options**:
   - **Config Panel** (Ctrl+K): Full configuration modal
     - Card dimensions, page size, colors
     - Double-sided, flip edge, cut lines
     - Image quality selection
   - **Quick Toggles**: Double-Sided, Images, Cut Lines
   - **Presets** (Shift+P): Save/load favorite configurations

4. **Preview**: Review the generated separators on screen

5. **Print** (Ctrl+P): Click the "Print" button or use keyboard shortcut

### Backend Endpoints

The Go backend provides these endpoints:

- `GET /api/health` - Health check
- `GET /api/images/{size}?url=<image_url>` - Get optimized image (sizes: thumbnail, medium, full, original)
- `GET /api/images?url=<image_url>` - Get all image size URLs as JSON
- `GET /api/cache/stats` - View cache statistics

**Example:**
```bash
# Get a medium-quality image
curl "http://localhost:8080/api/images/medium?url=https://example.com/card.jpg"

# Check cache stats
curl http://localhost:8080/api/cache/stats | jq
```

### Double-Sided Printing Instructions

1. Print all front pages first
2. Take the printed pages and reload them into your printer
3. Print all back pages
4. Your printer's flip edge setting determines alignment:
   - **Long Edge (Book)**: Pages flip like turning a book page
   - **Short Edge (Calendar)**: Pages flip like flipping a calendar

### Testing Printer Flip Edge

Not sure which flip edge your printer uses? Try this:

1. Write "TOP" at the top of a blank page
2. Print something on one side
3. Reload the paper and print on the other side
4. If the prints are both right-side up when you flip like a book → **Long Edge**
5. If the prints are both right-side up when you flip like a calendar → **Short Edge**

## Project Structure

```
card-separator/
├── backend/                 # Go backend service
│   ├── src/
│   │   └── main.go         # Image proxy server with caching
│   ├── cache/              # Local image cache (auto-created)
│   ├── Dockerfile
│   ├── go.mod
│   └── go.sum
├── web/                    # SvelteKit frontend
│   ├── src/
│   │   ├── lib/
│   │   │   ├── Card.svelte # Card separator component
│   │   │   ├── api.ts      # API utilities
│   │   │   └── config.ts   # Configuration system
│   │   ├── routes/
│   │   │   ├── +layout.svelte
│   │   │   └── +page.svelte  # Main app
│   │   └── app.css
│   ├── Dockerfile.dev
│   ├── package.json
│   └── .env
├── docker-compose.yml      # Multi-service orchestration
├── Makefile               # Developer commands
├── dev.sh                 # Quick start script
└── README.md
```

## Keyboard Shortcuts ⌨️

Power user shortcuts for efficiency:

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + P` | Print separators |
| `Ctrl/Cmd + K` | Open configuration panel |
| `Shift + P` | Open presets panel |
| `Escape` | Close modals |

## Make Commands

The Makefile provides convenient shortcuts:

```bash
make help          # Show all available commands
make install       # Install all dependencies
make dev           # Start with Docker Compose (recommended)
make up            # Start services without rebuilding
make down          # Stop all services
make build         # Build Docker images
make clean         # Clean containers, volumes, and cache
make logs          # Show all logs
make backend       # Run backend locally (no Docker)
make frontend      # Run frontend locally (no Docker)
make test          # Run tests
make fmt           # Format code
make lint          # Lint code
make cache-stats   # View image cache statistics
make health        # Check backend health
```

## Customization

### Configuration System

The app includes a comprehensive configuration system with localStorage persistence. All settings are saved automatically:

```typescript
import { loadConfig, saveConfig, type AppConfig } from '$lib/config';

// Load saved config
const config = loadConfig();

// Update config
saveConfig({
  cardDimensions: {
    width: 65,
    height: 95,
    tabHeight: 10
  },
  colors: {
    primary: '#DC2626',
    secondary: '#B91C1C'
  }
});
```

### Card Dimensions

Available in `web/src/lib/config.ts`:

```typescript
export const DEFAULT_CARD_DIMENSIONS = {
  width: 65,        // Card width (mm)
  height: 95,       // Card height (mm)
  tabHeight: 10     // Tab height (mm)
};

export const PAGE_SIZES = {
  a4: { width: 210, height: 297 },
  letter: { width: 216, height: 279 },
  legal: { width: 216, height: 356 },
  custom: { width: 210, height: 297 }
};
```

### Styling

The Card component (`web/src/lib/Card.svelte`) uses a One Piece TCG-inspired design with:
- Red banner with angled edges
- Conditional cost circle (hidden for leaders)
- Card name and ID display
- Lazy-loaded optimized images

Customize colors, fonts, and layout in the component or via the config system.

## API Data Source

This application uses the [OPTCG API](https://optcgapi.com/) - a community-maintained database for One Piece TCG cards.

**Available Endpoints:**
- `https://optcgapi.com/api/sets/{set_id}/` - Get all cards from a specific set
- `https://optcgapi.com/api/sets/card/{card_id}/` - Get a specific card

**Data Fields:**
- card_name, card_set_id, card_cost, card_power
- card_color, card_type, rarity, attribute
- card_image (full URL to card artwork)
- set_id, set_name

## Building for Production

```bash
cd web
npm run build
npm run preview  # Preview production build
```

## Contributing

Feel free to customize this for any trading card game! The design is generic and can work with any card data source by updating the API endpoints.

## License

MIT

---

## Dev Environment (Docker)

The project includes a Docker-based development environment:

### Prerequisites
- dgoss
- docker

### Setup

Install Goss:
```bash
choco install goss
```

Download dgoss from [Goss releases](https://github.com/aelsabbahy/goss/releases)

### Commands

Run Goss Tests:
```bash
dgoss run -it my-arch-dev-env
```

Run Linting:
```bash
hadolint dev.environment.Dockerfile
```