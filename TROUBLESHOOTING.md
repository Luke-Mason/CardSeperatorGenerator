# Troubleshooting Guide - Card Separator Tests

This guide addresses common issues encountered when setting up and running the acceptance tests.

## Issues We Encountered & Solutions

### 1. Docker Desktop Not Running ❌

**Error:**
```
error during connect: this error may indicate that the docker daemon is not running
```

**Solution:**
1. Open Docker Desktop
2. Wait for it to fully start (whale icon should be steady in system tray)
3. Verify with: `docker ps`
4. If still not working, restart Docker Desktop

**Quick Fix:**
```bash
# Windows
start "Docker Desktop"

# After Docker starts, verify:
docker ps
```

### 2. Minikube/Skaffold Installation Requires Admin Rights ❌

**Error:**
```
Chocolatey detected you are not running from an elevated command shell
Access to the path 'C:\ProgramData\chocolatey\lib-bad' is denied
```

**Solution:**

**Option A: Use Admin PowerShell (Recommended)**
1. Right-click PowerShell
2. Select "Run as Administrator"
3. Run: `choco install minikube skaffold -y`

**Option B: Manual Installation**
1. Download Minikube: https://minikube.sigs.k8s.io/docs/start/
2. Download Skaffold: https://skaffold.dev/docs/install/
3. Add to PATH manually

**Option C: Use Docker Compose Instead (Easiest)**
```powershell
# Skip Kubernetes entirely, use Docker Compose
.\scripts\run-local-tests.ps1
```

### 3. kubectl Already Installed (Conflicting Versions) ⚠️

**Issue:**
Chocolatey tries to install kubernetes-cli but it's already installed

**Solution:**
```bash
# Check current version
kubectl version --client

# If satisfactory (v1.27+), skip installation
# Or force upgrade with choco:
choco upgrade kubernetes-cli -y --force
```

###4. Go Module Dependency Issues ⚠️

**Error:**
```
go: github.com/cucumber/godog@v0.14.0: missing go.sum entry
```

**Solution:**
```bash
cd test
go mod tidy
go mod download
```

### 5. Playwright Browsers Not Installed ⚠️

**Error:**
```
browserType.launch: Executable doesn't exist
```

**Solution:**
```bash
cd e2e
npx playwright install
# Or install specific browser:
npx playwright install chromium
```

### 6. Port Already in Use ⚠️

**Error:**
```
bind: address already in use (port 8080, 5173, or 9000)
```

**Solution:**

**Windows:**
```powershell
# Find process using port
netstat -ano | findstr :8080

# Kill process (replace PID)
taskkill /PID <PID> /F

# Or stop docker-compose
docker-compose down
```

**Linux/macOS:**
```bash
# Find and kill process
lsof -ti:8080 | xargs kill -9

# Or stop docker-compose
docker-compose down
```

### 7. MinIO Container Fails to Start ⚠️

**Error:**
```
ERROR Unable to initialize sub-systems
```

**Solution:**
```bash
# Remove old volumes
docker-compose down -v

# Clean up Docker system
docker system prune -f

# Restart
docker-compose up -d --build
```

### 8. Backend Container Build Fails ❌

**Error:**
```
ERROR [build] failed to solve: failed to compute cache key
```

**Common Causes & Solutions:**

**A. Missing Dockerfile:**
```bash
# Check if Dockerfile exists
ls backend/Dockerfile

# If missing, create one or fix path in docker-compose.yml
```

**B. Network Issues During Build:**
```bash
# Retry with no cache
docker-compose build --no-cache

# Or build separately
cd backend
docker build -t card-separator-backend .
```

**C. Go Module Issues:**
```bash
cd backend
go mod tidy
go mod vendor  # Optional: vendor dependencies
```

### 9. Frontend Container Build Fails ❌

**Error:**
```
npm ERR! code ENOENT
npm ERR! syscall open
npm ERR! path /app/package.json
```

**Solution:**
```bash
# Ensure package.json exists
ls web/package.json

# Check Dockerfile.dev
ls web/Dockerfile.dev

# Try building locally first
cd web
npm install
npm run build
```

### 10. Skaffold Can't Find Minikube Profile ⚠️

**Error:**
```
unable to select a default cluster
```

**Solution:**
```bash
# Start minikube
minikube start

# Set context
kubectl config use-context minikube

# Verify
kubectl cluster-info
```

### 11. Tests Timeout Waiting for Services 🕐

**Issue:**
Tests fail because services take too long to start

**Solution:**
```bash
# Increase timeout in test scripts
# Or wait manually:
docker-compose up -d
sleep 60  # Wait 60 seconds

# Check service health:
curl http://localhost:8080/api/health
curl http://localhost:5173
```

### 12. Godog Tests Can't Connect to Services ❌

**Error:**
```
failed to call endpoint: dial tcp connect: connection refused
```

**Solution:**

**A. Check services are running:**
```bash
docker ps
# All 3 containers should be "Up"
```

**B. Check ports are accessible:**
```bash
curl http://localhost:8080/api/health
# Should return {"status":"ok"...}
```

**C. Wait longer for startup:**
```bash
# In test code, increase sleep/retry time
time.Sleep(30 * time.Second)
```

### 13. WSL2 Issues (Windows Subsystem for Linux) ⚠️

**Error:**
```
Docker Desktop requires WSL2
WslRegisterDistribution failed with error: 0x800701bc
```

**Solution:**

**Option A: Update WSL (Usually fixes it)**
```powershell
# In PowerShell (may need Admin):
wsl --update

# Wait 5-10 minutes for download and installation
# You may see: "Installing: Windows Subsystem for Linux"

# After it completes, restart Docker Desktop
```

**Option B: Fresh Install (If update doesn't work)**
1. Open PowerShell as Admin
2. Run: `wsl --install`
3. Restart computer
4. Open Docker Desktop settings
5. Enable "Use WSL2 based engine"

**Option C: Set WSL2 as default**
```powershell
wsl --set-default-version 2
```

**Verify WSL is working:**
```powershell
wsl --status
wsl --list --verbose

# Should show:
# * Ubuntu (or other distro) - Running - Version 2
```

### 14. Memory/Resource Limits ⚠️

**Error:**
```
Container killed (OOMKilled)
```

**Solution:**
```bash
# Increase Docker Desktop memory:
# Settings → Resources → Memory → 8GB minimum

# Or reduce services:
docker-compose up backend minio  # Skip frontend
```

---

## Quick Diagnostic Commands

Run these to diagnose issues:

```bash
# 1. Check Docker
docker --version
docker ps
docker-compose --version

# 2. Check Kubernetes tools
kubectl version --client
minikube version
skaffold version

# 3. Check Go/Node
go version
node --version
npm --version

# 4. Check ports
netstat -ano | findstr ":8080 :5173 :9000 :9001"

# 5. Check Docker Compose status
docker-compose ps

# 6. View logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs minio

# 7. Check health endpoints
curl http://localhost:8080/api/health
curl http://localhost:9000/minio/health/live
```

---

## Test Execution Strategies

### Strategy 1: Docker Compose Only (Easiest) ✅

**Best for:** Local development and quick testing

```powershell
# Windows
.\scripts\run-local-tests.ps1

# Linux/macOS
./scripts/run-local-tests.sh
```

**Requires:**
- Docker Desktop running
- docker-compose available

**Time:** 5-10 minutes

---

### Strategy 2: Kubernetes with Minikube (Full Test Suite) 🎯

**Best for:** Full acceptance testing before deployment

```powershell
# Windows (PowerShell as Admin)
.\scripts\run-acceptance-tests.ps1

# Linux/macOS
./scripts/run-acceptance-tests.sh
```

**Requires:**
- Docker Desktop running
- Minikube installed
- Skaffold installed
- 8GB+ RAM available

**Time:** 15-25 minutes (first run)

---

### Strategy 3: Manual Step-by-Step (Debugging) 🔍

**Best for:** Troubleshooting individual components

```bash
# Step 1: Start services
docker-compose up -d --build

# Step 2: Wait for health
sleep 60
curl http://localhost:8080/api/health

# Step 3: Run specific tests
cd test
go test -v -run TestDeployment

cd ../e2e
npx playwright test tests/deployment.spec.ts

# Step 4: Clean up
cd ..
docker-compose down
```

---

## Common Workflows

### First-Time Setup

```bash
# 1. Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# 2. Install Go
# Download from: https://golang.org/dl/

# 3. Install Node.js
# Download from: https://nodejs.org/

# 4. Install dependencies
cd test && go mod download && cd ..
cd e2e && npm install && npx playwright install && cd ..

# 5. Start services
docker-compose up -d --build

# 6. Run tests
.\scripts\run-local-tests.ps1
```

### Daily Development

```bash
# Quick test cycle:
docker-compose up -d          # Start services
# ... make code changes ...
docker-compose restart backend # Restart just backend
# ... run tests ...
docker-compose down           # Stop when done
```

### Before Committing Code

```bash
# Full test suite:
docker-compose down -v        # Clean state
docker-compose up -d --build  # Fresh build
.\scripts\run-local-tests.ps1  # Run tests
docker-compose down           # Clean up
```

---

## Getting Help

If you're still stuck:

1. **Check Logs:**
   ```bash
   docker-compose logs --tail=100 backend
   ```

2. **Check Container Status:**
   ```bash
   docker ps -a
   docker inspect card-separator-backend
   ```

3. **Try Clean Slate:**
   ```bash
   docker-compose down -v
   docker system prune -af
   docker-compose up -d --build
   ```

4. **Check Project Issues:**
   - Review `TEST_SUMMARY.md`
   - Check GitHub issues
   - Look at recent commits

5. **Manual Verification:**
   ```bash
   # Test backend manually:
   curl -X GET http://localhost:8080/api/health
   curl -X GET http://localhost:8080/api/sets
   curl -X POST http://localhost:8080/api/sets/sync

   # Test frontend manually:
   # Open http://localhost:5173 in browser
   ```

---

## Success Checklist

Before running tests, verify:

- ✅ Docker Desktop is running
- ✅ `docker ps` works without errors
- ✅ Ports 8080, 5173, 9000, 9001 are free
- ✅ At least 4GB RAM available
- ✅ Go 1.21+ installed
- ✅ Node.js 18+ installed
- ✅ Test dependencies installed (`go mod download`, `npm install`)

---

## Performance Tips

1. **Use `docker-compose` build cache:**
   ```bash
   # Don't use --no-cache unless necessary
   docker-compose build
   ```

2. **Parallel testing:**
   ```bash
   # Run Godog and Playwright in parallel:
   go test -v -run TestDeployment &
   npx playwright test &
   wait
   ```

3. **Skip slow tests during development:**
   ```bash
   # Run only fast tests:
   go test -v -short
   npx playwright test --grep-invert @slow
   ```

4. **Keep services running between test runs:**
   ```bash
   # Don't stop/start constantly:
   docker-compose up -d
   # Run tests multiple times
   # Only stop when done for the day
   docker-compose down
   ```

---

**Last Updated:** 2026-01-06
**Tested On:** Windows 11, Docker Desktop 24.0.6
