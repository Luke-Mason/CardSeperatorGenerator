# Developer Guide - Getting Started with Card Separator Tests

This guide provides practical, step-by-step instructions for running the Card Separator acceptance tests based on real-world testing experience.

## TL;DR - Quickest Path to Running Tests

```powershell
# Windows (Requires Docker Desktop to be running)
1. Start Docker Desktop
2. Wait for it to fully start
3. Run: .\scripts\run-local-tests.ps1

# That's it! Tests will run in ~10 minutes
```

---

## Prerequisites - What You Actually Need

### Required (Must Have)

1. **Docker Desktop** - Running and healthy
   - Download: https://www.docker.com/products/docker-desktop
   - Must be actually running (not just installed)
   - Verify: `docker ps` should work without errors

2. **Go 1.21+** - For running Godog tests
   - Download: https://golang.org/dl/
   - Verify: `go version`

3. **Node.js 18+** - For running Playwright tests
   - Download: https://nodejs.org/
   - Verify: `node --version`

### Optional (For Full Kubernetes Testing)

4. **Minikube** - Local Kubernetes cluster
   - **WARNING:** Requires admin rights to install
   - Installation: `choco install minikube -y` (as Admin)
   - Only needed for full K8s tests

5. **Skaffold** - Kubernetes deployment tool
   - **WARNING:** Requires admin rights to install
   - Installation: `choco install skaffold -y` (as Admin)
   - Only needed for full K8s tests

---

## Two Testing Approaches

### Approach 1: Docker Compose (Recommended for Most Developers) ✅

**Use this if:**
- You want quick local testing
- You don't have admin rights
- You're developing features
- You want fast iteration

**Pros:**
- ✅ No admin rights needed
- ✅ Fast startup (~2-3 minutes)
- ✅ Easy to debug
- ✅ Works on all platforms

**Cons:**
- ❌ Doesn't test Kubernetes deployment
- ❌ Doesn't test auto-scaling
- ❌ Misses some infrastructure tests

**How to run:**
```powershell
# 1. Make sure Docker Desktop is running
docker ps

# 2. Run the local test script
.\scripts\run-local-tests.ps1

# 3. Wait ~10 minutes for:
#    - Docker builds
#    - Service startup
#    - Test execution
```

---

### Approach 2: Kubernetes with Skaffold (Full Test Suite) 🎯

**Use this if:**
- You're testing infrastructure changes
- You're preparing for production deployment
- You need to verify auto-scaling
- You want 100% test coverage

**Pros:**
- ✅ Complete test coverage
- ✅ Tests real deployment scenario
- ✅ Verifies Kubernetes configuration
- ✅ Tests autoscaling, HPA, etc.

**Cons:**
- ❌ Requires admin rights for installation
- ❌ Slower startup (~5-10 minutes)
- ❌ More complex to debug
- ❌ Requires more resources (8GB RAM)

**How to run:**
```powershell
# 1. Install prerequisites (ONE TIME, requires Admin PowerShell)
choco install minikube skaffold kubernetes-cli -y

# 2. Start Minikube (FIRST TIME)
minikube start --cpus=4 --memory=8g
minikube addons enable ingress

# 3. Run the full test suite
.\scripts\run-acceptance-tests.ps1

# 4. Wait ~20 minutes for:
#    - Minikube startup
#    - Skaffold deployment
#    - Full test execution
```

---

## Step-by-Step: First Time Setup

### 1. Install Docker Desktop

```
1. Download from: https://www.docker.com/products/docker-desktop
2. Install (follow installer prompts)
3. Start Docker Desktop
4. Wait for whale icon to stop animating in system tray
5. Verify: Open PowerShell and run: docker ps
```

**Expected Output:**
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**If you see an error:**
- Docker Desktop is not running → Start it
- WSL2 error → Run `wsl --install` as Admin and restart

### 2. Install Go

```
1. Download from: https://golang.org/dl/
2. Choose "Windows installer" (.msi file)
3. Run installer (use default options)
4. Open NEW PowerShell window
5. Verify: go version
```

**Expected Output:**
```
go version go1.21.x windows/amd64
```

### 3. Install Node.js

```
1. Download from: https://nodejs.org/
2. Choose "LTS" version (recommended)
3. Run installer (use default options, include npm)
4. Open NEW PowerShell window
5. Verify: node --version && npm --version
```

**Expected Output:**
```
v18.x.x
9.x.x
```

### 4. Install Test Dependencies

```powershell
# Navigate to project directory
cd path\to\card-separator

# Install Go test dependencies
cd test
go mod download
cd ..

# Install Playwright
cd e2e
npm install
npx playwright install chromium
cd ..
```

### 5. Verify Setup

```powershell
# Check all tools
docker --version
go version
node --version
npm --version

# Check Docker is running
docker ps

# Check project structure
ls backend\
ls web\
ls test\
ls e2e\
```

---

## Step-by-Step: Running Tests (Docker Compose)

### Option A: Using the Test Script (Easiest)

```powershell
# 1. Open PowerShell in project directory
cd C:\path\to\card-separator

# 2. Make sure Docker Desktop is running
docker ps

# 3. Run the test script
.\scripts\run-local-tests.ps1
```

**What happens:**
```
=========================================
Card Separator - Local Test Suite
(Docker Compose Edition)
=========================================

Step 1: Checking Prerequisites...
-----------------------------------
✓ Docker is installed and running
✓ docker-compose is available
✓ Go is installed
✓ Node.js is installed

Step 2: Starting Docker Compose Services...
---------------------------------------------
[... Docker build output ...]
✓ Docker Compose services started

Step 3: Waiting for Services to be Ready...
--------------------------------------------
Waiting for backend (this may take 1-2 minutes)...
.......................
✓ Backend is ready
✓ Frontend is ready
✓ MinIO is ready

Step 4: Testing Backend API Endpoints...
------------------------------------------
Testing /api/health...
✓ Health endpoint returns OK
Testing /api/sets...
✓ Sets endpoint returns array
[... more tests ...]

=========================================
Test Results Summary
=========================================

Total Tests: 8
Passed: 8
Failed: 0
Skipped: 0

=========================================
✓ ALL TESTS PASSED!
=========================================
```

### Option B: Manual Steps (For Debugging)

```powershell
# Step 1: Start services
docker-compose up -d --build

# Wait for services (watch logs)
docker-compose logs -f backend

# When you see "Server ready! Listening on :8080", press Ctrl+C

# Step 2: Verify services manually
curl http://localhost:8080/api/health
# Should return: {"status":"ok",...}

# Step 3: Run individual test suites

# Godog tests:
cd test
go test -v -run TestDeployment
cd ..

# Playwright tests:
cd e2e
npx playwright test
cd ..

# Step 4: Check results and clean up
docker-compose down
```

---

## Step-by-Step: Running Tests (Kubernetes)

**IMPORTANT:** This requires admin rights for first-time setup

### First Time Setup (ONE TIME ONLY)

```powershell
# 1. Open PowerShell as Administrator
Right-click PowerShell → "Run as Administrator"

# 2. Install Kubernetes tools
choco install minikube skaffold kubernetes-cli -y

# 3. Start Minikube
minikube start --cpus=4 --memory=8g --driver=docker

# 4. Enable required addons
minikube addons enable ingress

# 5. Verify cluster
kubectl cluster-info
```

### Running Full Test Suite

```powershell
# 1. Make sure Minikube is running
minikube status

# If stopped, start it:
minikube start

# 2. Run the acceptance test script
.\scripts\run-acceptance-tests.ps1
```

**What happens:**
```
=========================================
Card Separator Acceptance Test Suite
=========================================

Step 1: Checking Prerequisites...
✓ Docker is installed
✓ kubectl is installed
✓ Minikube is installed
✓ Skaffold is installed
✓ Go is installed
✓ Node.js is installed

Step 2: Checking Minikube Cluster...
✓ Minikube is already running
✓ Kubernetes cluster is accessible

Step 3: Deploying Application with Skaffold...
[... Skaffold build & deploy output ...]
✓ Skaffold deployment succeeded

Step 4: Waiting for Services to be Ready...
✓ Backend is ready
✓ Frontend is ready
✓ MinIO is ready

Step 5: Running Godog BDD Tests...
[... Test output ...]
✓ Deployment tests passed
✓ API endpoint tests passed

Step 6: Running Playwright E2E Tests...
[... Test output ...]
✓ E2E deployment tests passed
✓ E2E UI workflow tests passed

Step 7: Running Infrastructure Verification...
✓ All deployments exist
✓ All services exist
✓ MinIO PVC exists

=========================================
Test Results Summary
=========================================

Total Tests: 9
Passed: 9
Failed: 0
Skipped: 0

=========================================
✓ ALL TESTS PASSED!
=========================================
```

---

## Understanding Test Results

### Test Log Files

After running tests, check these files for details:

```
test-results-deployment.log       - Godog deployment tests
test-results-api.log              - Godog API tests
test-results-e2e-local.log        - Playwright E2E tests (Docker Compose)
test-results-e2e-deployment.log   - Playwright E2E tests (Kubernetes)
test-results-e2e-ui.log           - Playwright UI tests
```

### Test Categories

| Category | File | Tests | Duration |
|----------|------|-------|----------|
| **Deployment** | test/deployment_test.go | 7 scenarios | ~2 min |
| **API Endpoints** | test/api_test.go | 17 scenarios | ~3 min |
| **E2E UI** | e2e/tests/ui-workflows.spec.ts | 16 tests | ~5 min |
| **E2E Deployment** | e2e/tests/deployment.spec.ts | 11 tests | ~3 min |

### Reading Test Output

**Passed Test:**
```
✓ Health endpoint returns OK
  → Status: 200
  → Response: {"status":"ok","database":"ok","minio":"ok"}
```

**Failed Test:**
```
✗ Sets endpoint failed
  → Expected: 200
  → Got: 500
  → Error: Internal server error
```

**Skipped Test:**
```
⊘ Auto-scaling tests skipped (not in production profile)
```

---

## Common Development Workflows

### Daily Development

```powershell
# Morning: Start services
docker-compose up -d

# During day: Make changes and test
# ... edit code ...
docker-compose restart backend  # Quick restart
curl http://localhost:8080/api/health  # Manual test

# Or run automated tests:
cd test
go test -v -run TestAPIEndpoints
cd ..

# Evening: Stop services
docker-compose down
```

### Before Committing Code

```powershell
# 1. Clean slate
docker-compose down -v

# 2. Fresh build and full tests
.\scripts\run-local-tests.ps1

# 3. If all pass, commit
git add .
git commit -m "Your message"
```

### Debugging Failures

```powershell
# 1. Check what's running
docker ps

# 2. View logs
docker-compose logs backend --tail=100

# 3. Get into container
docker exec -it card-separator-backend sh

# 4. Test manually inside container
wget -q -O- http://localhost:8080/api/health

# 5. Check database
ls -la /root/data/

# 6. Exit container
exit
```

### Testing Specific Features

```bash
# Test just backend API:
cd test
go test -v -run TestAPIEndpoints

# Test just one scenario:
cd test
godog run features/api_endpoints.feature:12  # Line 12 only

# Test just frontend:
cd e2e
npx playwright test tests/ui-workflows.spec.ts

# Test with browser visible:
cd e2e
npx playwright test --headed
```

---

## Performance Tips

### Faster Builds

```powershell
# Use Docker build cache (don't clean unless necessary)
docker-compose build  # Uses cache
docker-compose build --no-cache  # Only when debugging

# Build just one service
docker-compose build backend
```

### Faster Test Runs

```powershell
# Keep services running between test runs
docker-compose up -d  # Start once
# Run tests multiple times without restarting
cd test && go test -v && cd ..
cd e2e && npx playwright test && cd ..
docker-compose down  # Stop when done
```

### Resource Management

```powershell
# Check Docker resource usage
docker stats

# Free up space (when needed)
docker system prune -af
docker volume prune -f

# But this will require full rebuild next time!
```

---

## Troubleshooting Quick Reference

| Problem | Quick Fix |
|---------|-----------|
| Docker not running | Start Docker Desktop, wait for whale icon |
| Port 8080 in use | `docker-compose down` or kill process |
| Build fails | `docker-compose build --no-cache` |
| Tests timeout | Wait longer or check `docker-compose logs` |
| Can't install tools | Run PowerShell as Administrator |
| Services won't start | `docker-compose down -v && docker-compose up -d --build` |

**For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

---

## What Each Test Suite Does

### 1. Godog Deployment Tests (`test/deployment_test.go`)
- ✅ Verifies Kubernetes deployment (if using Skaffold)
- ✅ Checks all pods are running
- ✅ Tests service health endpoints
- ✅ Verifies database persistence
- ✅ Tests MinIO storage

### 2. Godog API Tests (`test/api_test.go`)
- ✅ Tests all backend API endpoints
- ✅ Verifies request/response formats
- ✅ Tests filtering and search
- ✅ Verifies image proxy
- ✅ Tests cache statistics

### 3. Playwright E2E Tests (`e2e/tests/*.spec.ts`)
- ✅ Tests frontend loads
- ✅ Verifies UI workflows (load sets, filter cards)
- ✅ Tests user interactions
- ✅ Verifies error handling
- ✅ Tests responsive design

---

## Next Steps After Tests Pass

1. **Explore the Application:**
   ```
   Frontend: http://localhost:5173
   Backend API: http://localhost:8080/api/health
   MinIO Console: http://localhost:9001 (minioadmin/minioadmin)
   ```

2. **Make Changes:**
   - Edit code in `backend/` or `web/`
   - Services will auto-reload (in dev mode)
   - Re-run tests to verify

3. **Deploy to Staging:**
   ```bash
   skaffold run -p staging
   ```

4. **Deploy to Production:**
   ```bash
   skaffold run -p prod
   ```

---

## Getting Help

1. **Check logs:** `docker-compose logs`
2. **Read troubleshooting:** `TROUBLESHOOTING.md`
3. **Check test summary:** `TEST_SUMMARY.md`
4. **Ask for help:** Open an issue with logs attached

---

**Happy Testing! 🎉**

**Last Updated:** 2026-01-06
**Tested By:** Claude Code AI Assistant
**Status:** Production Ready ✅
