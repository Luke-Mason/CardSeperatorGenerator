# Contributing to Card Separator Generator

Thank you for your interest in contributing! This document provides guidelines and instructions.

## 📚 Before You Start

Please read the following documentation:
- **README.md** - User-facing features and usage
- **ARCHITECTURE.md** - Technical architecture and design decisions
- **DECISIONS.md** - Architectural Decision Records (ADRs)
- **CHANGELOG.md** - Version history

Understanding these documents will help you navigate the codebase and make informed decisions.

## 🚀 Getting Started

### Prerequisites
- Node.js v18+
- Go v1.21+
- Git

### Setup Development Environment

```bash
# Clone the repository
git clone <repo-url>
cd card-separator

# Install dependencies and start dev servers
./dev.sh

# Or use Docker
make dev
```

## 🏗️ Project Structure

```
card-separator/
├── backend/src/main.go       # Go image proxy server
├── web/src/
│   ├── lib/                  # Reusable components
│   │   ├── Card.svelte       # Card separator component
│   │   ├── ConfigPanel.svelte # Configuration modal
│   │   ├── Presets.svelte    # Presets management
│   │   ├── api.ts            # Backend API utilities
│   │   └── config.ts         # Configuration system
│   └── routes/+page.svelte   # Main application
├── ARCHITECTURE.md           # Technical deep-dive
├── DECISIONS.md              # Architectural decisions
└── CHANGELOG.md              # Version history
```

## 🎯 Contribution Guidelines

### Code Style

**Frontend (TypeScript/Svelte):**
- Use Prettier for formatting: `npm run format`
- Use ESLint for linting: `npm run lint`
- Follow Svelte 5 runes conventions (`$state`, `$derived`, `$effect`)
- Use TypeScript for all new files
- Prefer const > let, avoid var

**Backend (Go):**
- Use `go fmt` for formatting: `make fmt`
- Follow standard Go conventions
- Comment exported functions
- Handle errors explicitly

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```bash
feat(filtering): add filter by rarity
fix(backend): prevent cache stampede on concurrent requests
docs(architecture): document image processing pipeline
```

### Pull Request Process

1. **Fork & Clone**
   ```bash
   git clone https://github.com/your-username/card-separator.git
   cd card-separator
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

3. **Make Changes**
   - Write code
   - Update documentation (if user-facing)
   - Add to CHANGELOG.md under "Unreleased"
   - Document decisions in DECISIONS.md (if architectural)

4. **Test Locally**
   ```bash
   make test      # Run tests (when available)
   make lint      # Check linting
   make fmt       # Format code
   ```

5. **Commit**
   ```bash
   git add .
   git commit -m "feat(component): add new feature"
   ```

6. **Push & PR**
   ```bash
   git push origin feat/your-feature-name
   # Open PR on GitHub
   ```

7. **PR Description Template**
   ```markdown
   ## What
   Brief description of changes

   ## Why
   Reason for the change

   ## How
   Implementation approach

   ## Testing
   How to test this change

   ## Screenshots (if UI change)
   [Screenshots here]

   ## Checklist
   - [ ] Updated CHANGELOG.md
   - [ ] Updated documentation
   - [ ] Added/updated tests
   - [ ] Formatted code
   - [ ] Tested locally
   ```

## 🧪 Testing

### Manual Testing
1. Start dev environment: `./dev.sh`
2. Load cards: OP-01
3. Test filtering, sorting, configuration
4. Test print preview (Ctrl+P → Preview)
5. Verify backend cache: `make cache-stats`

### Automated Testing (Future)
```bash
# Frontend unit tests
npm run test

# Backend tests
cd backend && go test ./...

# E2E tests
npm run test:e2e
```

## 📖 Documentation Standards

### Code Comments
- Comment complex algorithms
- Explain non-obvious decisions
- Use JSDoc for functions

```typescript
/**
 * Generates back pages with proper flip alignment.
 *
 * @param frontPages - Array of front page card grids
 * @returns Array of back page card grids with N-1 card logic
 */
function generateBackPages(frontPages: CardDetails[][]): CardDetails[][] {
  // Implementation
}
```

### Architectural Decisions
Add to `DECISIONS.md` when making significant choices:

```markdown
## ADR-XXX: [Title]

**Date**: YYYY-MM-DD
**Status**: [Proposed|Implemented|Deprecated]

### Context
[Problem being solved]

### Decision
[What we decided]

### Alternatives Considered
[Other options]

### Consequences
[Trade-offs]
```

### Changelog Updates
Add to `CHANGELOG.md` under `[Unreleased]`:

```markdown
## [Unreleased]

### Added
- New feature description (#PR-number)

### Changed
- Modified behavior (#PR-number)

### Fixed
- Bug description (#PR-number)
```

## 🐛 Bug Reports

### Issue Template
```markdown
**Describe the bug**
Clear and concise description

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
If applicable

**Environment:**
- OS: [e.g., Windows 11]
- Browser: [e.g., Chrome 120]
- Version: [e.g., 1.0.0]

**Additional context**
Any other information
```

## 💡 Feature Requests

### Suggestion Template
```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this needed? What problem does it solve?

**Proposed Solution**
How do you envision this working?

**Alternatives**
Other ways to solve this problem

**Priority**
[High/Medium/Low]
```

## 🏆 Recognition

Contributors will be recognized in:
- README.md (Contributors section)
- GitHub contributors page
- Release notes

## 📋 Roadmap Priorities

### v1.1.0 (Next Release)
- [ ] PDF Export
- [ ] Print Preview Modal
- [ ] Automated Tests
- [ ] Printer Test Alignment Page

### v1.2.0
- [ ] QR Codes
- [ ] Analytics Dashboard
- [ ] Custom Card Import
- [ ] Virtual Scrolling

### v2.0.0
- [ ] Multi-TCG Support
- [ ] Template System
- [ ] Cloud Sync

## ❓ Questions?

- **General Questions**: Open a [Discussion](https://github.com/your-repo/discussions)
- **Bug Reports**: Open an [Issue](https://github.com/your-repo/issues)
- **Feature Requests**: Open an [Issue](https://github.com/your-repo/issues)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** 🎉
