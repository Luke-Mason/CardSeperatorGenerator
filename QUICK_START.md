# Quick Start - Getting Tests Running NOW

## Current Status: WSL Update in Progress ⏳

Your `wsl --update` command is currently running. This typically takes 5-10 minutes.

---

## What Happens Next (Step-by-Step)

### Step 1: Wait for WSL Update to Complete ⏳

**What's happening now:**
- Windows is downloading WSL2 components
- Installing Windows Subsystem for Linux
- This may take 5-10 minutes

**How to check if it's done:**
```powershell
# In a NEW PowerShell window, run:
wsl --status

# If you see version information, it's done!
# If you see an error, it's still installing
```

---

### Step 2: Restart Docker Desktop (if needed) 🔄

**After WSL update completes:**

```powershell
# Option A: Restart Docker Desktop from system tray
1. Right-click Docker Desktop icon (whale in system tray)
2. Select "Restart"
3. Wait 1-2 minutes for it to fully restart

# Option B: If Docker Desktop isn't running
1. Search for "Docker Desktop" in Windows Start menu
2. Click to open it
3. Wait for whale icon to appear and stop animating
```

**Verify Docker is working:**
```powershell
docker ps

# Should show empty list or running containers
# Should NOT show connection errors
```

---

### Step 3: Run the Tests! 🎉

**Once Docker is running:**

```powershell
# Navigate to project directory (if not already there)
cd C:\Users\lukey\workspaces\card-seperator

# Run the Docker Compose tests
.\scripts\run-local-tests.ps1
```

**Expected output:**
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
[Building images...]
✓ Docker Compose services started

Step 3: Waiting for Services to be Ready...
--------------------------------------------
Waiting for backend (this may take 1-2 minutes)...
...................
✓ Backend is ready
✓ Frontend is ready
✓ MinIO is ready

Step 4: Testing Backend API Endpoints...
------------------------------------------
Testing /api/health...
✓ Health endpoint returns OK
Testing /api/sets...
✓ Sets endpoint returns array
Testing /api/cache/stats...
✓ Cache stats endpoint works

... [more tests] ...

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

---

## If Something Goes Wrong

### Problem: WSL update fails

**Solution:**
```powershell
# Try as Administrator:
1. Right-click PowerShell → "Run as Administrator"
2. Run: wsl --update
3. Wait for completion
```

### Problem: Docker still won't start

**Solution:**
```powershell
# Check WSL status:
wsl --status

# Should show version 2.x.x
# If not, you may need to restart your computer
```

### Problem: docker ps still shows error

**Error:**
```
error during connect: this error may indicate that the docker daemon is not running
```

**Solution:**
1. Close Docker Desktop completely
2. Restart computer (yes, really - WSL sometimes needs this)
3. Start Docker Desktop
4. Wait 2-3 minutes
5. Try `docker ps` again

### Problem: Tests fail with connection errors

**Solution:**
```powershell
# Wait longer for services to start:
docker-compose up -d
sleep 120  # Wait 2 minutes

# Check logs:
docker-compose logs backend
docker-compose logs frontend

# Then run tests again:
.\scripts\run-local-tests.ps1
```

---

## Timeline

Here's what to expect:

```
[Now]      WSL update running (5-10 min)
  ↓
[+10 min]  WSL update complete
  ↓
[+11 min]  Restart Docker Desktop
  ↓
[+13 min]  Docker is running, ready for tests
  ↓
[+15 min]  Run test script
  ↓
[+18 min]  Docker images building (first time: 3-5 min)
  ↓
[+23 min]  Services starting (2-3 min)
  ↓
[+25 min]  Tests running (5-7 min)
  ↓
[+32 min]  ✅ TESTS COMPLETE!
```

**Total time from now:** ~30-35 minutes (first time)
**Future runs:** ~10-15 minutes (cached builds)

---

## Commands Cheat Sheet

```powershell
# Check WSL status
wsl --status

# Check Docker status
docker ps

# Start services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Run tests
.\scripts\run-local-tests.ps1

# Stop services
docker-compose down

# Clean restart
docker-compose down -v && docker-compose up -d --build
```

---

## Success Checklist

Before running tests, verify:

- [ ] WSL update completed successfully
- [ ] Docker Desktop is running (whale icon steady)
- [ ] `docker ps` works without errors
- [ ] You're in project directory: `C:\Users\lukey\workspaces\card-seperator`
- [ ] PowerShell is open

Then run:
```powershell
.\scripts\run-local-tests.ps1
```

---

## What You'll Get

After tests complete, you'll have:

1. **Test Results** - Pass/fail for each test
2. **Service URLs:**
   - Frontend: http://localhost:5173
   - Backend: http://localhost:8080/api/health
   - MinIO: http://localhost:9001
3. **Log Files** - Detailed test output
4. **Running Services** - Ready to manually explore

---

## Next Steps After Tests Pass

1. **Explore the Application:**
   ```
   Open browser to: http://localhost:5173
   ```

2. **Test Backend API:**
   ```powershell
   curl http://localhost:8080/api/health
   curl http://localhost:8080/api/sets
   curl http://localhost:8080/api/cache/stats
   ```

3. **View Logs:**
   ```powershell
   docker-compose logs -f
   ```

4. **Make Changes:**
   - Edit code in `backend/` or `web/`
   - Restart: `docker-compose restart backend`
   - Re-run tests

5. **Stop Services:**
   ```powershell
   docker-compose down
   ```

---

## Help

**Stuck?** Check these files:
- `TROUBLESHOOTING.md` - 14 common issues
- `DEVELOPER_GUIDE.md` - Complete setup guide
- `REAL_WORLD_STATUS.md` - Honest project assessment

**Still stuck?** Look at container logs:
```powershell
docker-compose logs backend --tail=50
```

---

**You're on the right track! Just waiting for WSL to finish updating...**

🎯 **Next command to run (after WSL finishes):** `docker ps`

---

**Last Updated:** 2026-01-06 (Based on your actual setup progress)
