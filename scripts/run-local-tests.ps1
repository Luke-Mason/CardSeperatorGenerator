# Simplified Local Test Runner (Docker Compose)
# This script uses Docker Compose instead of Kubernetes for easier local testing

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Card Separator - Local Test Suite" -ForegroundColor Cyan
Write-Host "(Docker Compose Edition)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Test results tracking
$TESTS_PASSED = 0
$TESTS_FAILED = 0
$TESTS_SKIPPED = 0

function Print-Status {
    param (
        [string]$Status,
        [string]$Message
    )

    switch ($Status) {
        "PASS" {
            Write-Host "✓ $Message" -ForegroundColor Green
        }
        "FAIL" {
            Write-Host "✗ $Message" -ForegroundColor Red
        }
        "SKIP" {
            Write-Host "⊘ $Message" -ForegroundColor Yellow
        }
        "INFO" {
            Write-Host "ℹ $Message" -ForegroundColor Cyan
        }
        default {
            Write-Host $Message
        }
    }
}

function Check-Prerequisites {
    Write-Host "Step 1: Checking Prerequisites..." -ForegroundColor Cyan
    Write-Host "-----------------------------------"

    # Check Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Print-Status "FAIL" "Docker is not installed"
        exit 1
    }

    # Check if Docker daemon is running
    $dockerRunning = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Print-Status "FAIL" "Docker daemon is not running. Please start Docker Desktop."
        Write-Host ""
        Write-Host "To fix this:" -ForegroundColor Yellow
        Write-Host "  1. Open Docker Desktop" -ForegroundColor Yellow
        Write-Host "  2. Wait for it to fully start" -ForegroundColor Yellow
        Write-Host "  3. Run this script again" -ForegroundColor Yellow
        exit 1
    }
    Print-Status "PASS" "Docker is installed and running"

    # Check docker-compose
    $dockerComposeCmd = $null
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        $dockerComposeCmd = "docker-compose"
    } elseif (docker compose version 2>&1 | Select-String "Docker Compose") {
        $dockerComposeCmd = "docker compose"
    }

    if (-not $dockerComposeCmd) {
        Print-Status "FAIL" "docker-compose is not available"
        exit 1
    }
    Print-Status "PASS" "docker-compose is available ($dockerComposeCmd)"
    $script:dockerComposeCmd = $dockerComposeCmd

    # Check Go
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Print-Status "FAIL" "Go is not installed"
        exit 1
    }
    Print-Status "PASS" "Go is installed"

    # Check Node
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Print-Status "FAIL" "Node.js is not installed"
        exit 1
    }
    Print-Status "PASS" "Node.js is installed"

    Write-Host ""
}

function Start-DockerCompose {
    Write-Host "Step 2: Starting Docker Compose Services..." -ForegroundColor Cyan
    Write-Host "---------------------------------------------"

    Print-Status "INFO" "Stopping any existing containers..."
    if ($script:dockerComposeCmd -eq "docker-compose") {
        docker-compose down -v 2>&1 | Out-Null
    } else {
        docker compose down -v 2>&1 | Out-Null
    }

    Print-Status "INFO" "Building and starting services..."
    Write-Host ""

    if ($script:dockerComposeCmd -eq "docker-compose") {
        docker-compose up -d --build
    } else {
        docker compose up -d --build
    }

    if ($LASTEXITCODE -ne 0) {
        Print-Status "FAIL" "Failed to start Docker Compose services"
        exit 1
    }

    Print-Status "PASS" "Docker Compose services started"
    Write-Host ""
}

function Wait-ForServices {
    Write-Host "Step 3: Waiting for Services to be Ready..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------"

    # Wait for backend health check
    Print-Status "INFO" "Waiting for backend (this may take 1-2 minutes)..."
    $maxAttempts = 60
    $attempt = 0
    $backendReady = $false

    while ($attempt -lt $maxAttempts -and -not $backendReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 2 2>&1
            if ($response.StatusCode -eq 200) {
                $backendReady = $true
            }
        } catch {
            # Ignore errors, keep waiting
        }

        if (-not $backendReady) {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
            $attempt++
        }
    }
    Write-Host ""

    if (-not $backendReady) {
        Print-Status "FAIL" "Backend did not become ready after $($maxAttempts * 2) seconds"
        Write-Host ""
        Print-Status "INFO" "Checking container logs..."
        if ($script:dockerComposeCmd -eq "docker-compose") {
            docker-compose logs backend
        } else {
            docker compose logs backend
        }
        exit 1
    }
    Print-Status "PASS" "Backend is ready"

    # Check frontend
    Print-Status "INFO" "Checking frontend..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing -TimeoutSec 5 2>&1
        Print-Status "PASS" "Frontend is ready"
    } catch {
        Print-Status "FAIL" "Frontend is not accessible"
        $script:TESTS_FAILED++
    }

    # Check MinIO
    Print-Status "INFO" "Checking MinIO..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9001" -UseBasicParsing -TimeoutSec 5 2>&1
        Print-Status "PASS" "MinIO is ready"
    } catch {
        Print-Status "FAIL" "MinIO is not accessible"
        $script:TESTS_FAILED++
    }

    Write-Host ""
}

function Test-BackendEndpoints {
    Write-Host "Step 4: Testing Backend API Endpoints..." -ForegroundColor Cyan
    Write-Host "------------------------------------------"

    # Test health endpoint
    Write-Host "Testing /api/health..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method Get
        if ($response.status -eq "ok") {
            Print-Status "PASS" "Health endpoint returns OK"
            $script:TESTS_PASSED++
        } else {
            Print-Status "FAIL" "Health endpoint returned unexpected status: $($response.status)"
            $script:TESTS_FAILED++
        }
    } catch {
        Print-Status "FAIL" "Health endpoint failed: $_"
        $script:TESTS_FAILED++
    }

    # Test sets endpoint
    Write-Host "Testing /api/sets..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/sets" -Method Get
        if ($response -is [System.Array] -or $response -eq $null) {
            Print-Status "PASS" "Sets endpoint returns array"
            $script:TESTS_PASSED++
        } else {
            Print-Status "FAIL" "Sets endpoint did not return array"
            $script:TESTS_FAILED++
        }
    } catch {
        Print-Status "FAIL" "Sets endpoint failed: $_"
        $script:TESTS_FAILED++
    }

    # Test cache stats endpoint
    Write-Host "Testing /api/cache/stats..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/cache/stats" -Method Get
        if ($response.total_sets -ne $null) {
            Print-Status "PASS" "Cache stats endpoint works"
            $script:TESTS_PASSED++
            Write-Host "  → Total sets: $($response.total_sets)" -ForegroundColor Gray
            Write-Host "  → Total cards: $($response.total_cards)" -ForegroundColor Gray
        } else {
            Print-Status "FAIL" "Cache stats endpoint returned unexpected format"
            $script:TESTS_FAILED++
        }
    } catch {
        Print-Status "FAIL" "Cache stats endpoint failed: $_"
        $script:TESTS_FAILED++
    }

    Write-Host ""
}

function Test-FrontendLoading {
    Write-Host "Step 5: Testing Frontend Loading..." -ForegroundColor Cyan
    Write-Host "-------------------------------------"

    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5173" -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Print-Status "PASS" "Frontend page loads successfully"
            $script:TESTS_PASSED++

            # Check if content looks like HTML
            if ($response.Content -match "<html" -or $response.Content -match "<!DOCTYPE") {
                Print-Status "PASS" "Frontend returns HTML content"
                $script:TESTS_PASSED++
            } else {
                Print-Status "FAIL" "Frontend does not return HTML content"
                $script:TESTS_FAILED++
            }
        } else {
            Print-Status "FAIL" "Frontend returned status code: $($response.StatusCode)"
            $script:TESTS_FAILED++
        }
    } catch {
        Print-Status "FAIL" "Frontend loading failed: $_"
        $script:TESTS_FAILED++
    }

    Write-Host ""
}

function Test-DatabasePersistence {
    Write-Host "Step 6: Testing Database Persistence..." -ForegroundColor Cyan
    Write-Host "-----------------------------------------"

    # Sync a set
    Write-Host "Syncing sets..."
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/sets/sync" -Method Post
        if ($response.synced_sets -gt 0) {
            Print-Status "PASS" "Sets synced successfully ($($response.synced_sets) sets)"
            $script:TESTS_PASSED++

            # Wait a bit for data to be written
            Start-Sleep -Seconds 2

            # Check if sets are available
            $setsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/sets" -Method Get
            if ($setsResponse.Count -gt 0) {
                Print-Status "PASS" "Synced sets are retrievable"
                $script:TESTS_PASSED++
            } else {
                Print-Status "FAIL" "No sets found after sync"
                $script:TESTS_FAILED++
            }
        } else {
            Print-Status "FAIL" "No sets were synced"
            $script:TESTS_FAILED++
        }
    } catch {
        Print-Status "FAIL" "Set sync failed: $_"
        $script:TESTS_FAILED++
    }

    Write-Host ""
}

function Run-PlaywrightTests {
    Write-Host "Step 7: Running Playwright E2E Tests..." -ForegroundColor Cyan
    Write-Host "-----------------------------------------"

    if (Test-Path "e2e") {
        Push-Location e2e

        # Run subset of tests
        Write-Host "Running E2E tests against local environment..."
        $env:BACKEND_URL = "http://localhost:8080"
        $env:FRONTEND_URL = "http://localhost:5173"

        npx playwright test tests/deployment.spec.ts --reporter=line 2>&1 | Tee-Object -FilePath "../test-results-e2e-local.log"

        if ($LASTEXITCODE -eq 0) {
            Print-Status "PASS" "Playwright tests passed"
            $script:TESTS_PASSED++
        } else {
            Print-Status "FAIL" "Some Playwright tests failed (see test-results-e2e-local.log)"
            $script:TESTS_FAILED++
        }

        Pop-Location
    } else {
        Print-Status "SKIP" "E2E directory not found, skipping Playwright tests"
        $script:TESTS_SKIPPED++
    }

    Write-Host ""
}

function Show-ServiceInfo {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Service URLs" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Frontend:     http://localhost:5173" -ForegroundColor Green
    Write-Host "Backend API:  http://localhost:8080" -ForegroundColor Green
    Write-Host "MinIO Console: http://localhost:9001" -ForegroundColor Green
    Write-Host "  (Credentials: minioadmin / minioadmin)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "API Endpoints:" -ForegroundColor Cyan
    Write-Host "  GET  http://localhost:8080/api/health" -ForegroundColor Gray
    Write-Host "  GET  http://localhost:8080/api/sets" -ForegroundColor Gray
    Write-Host "  POST http://localhost:8080/api/sets/sync" -ForegroundColor Gray
    Write-Host "  GET  http://localhost:8080/api/cache/stats" -ForegroundColor Gray
    Write-Host ""
}

function Generate-TestReport {
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Test Results Summary" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""

    $totalTests = $TESTS_PASSED + $TESTS_FAILED + $TESTS_SKIPPED

    Write-Host "Total Tests: $totalTests"
    Write-Host "Passed: $TESTS_PASSED" -ForegroundColor Green
    Write-Host "Failed: $TESTS_FAILED" -ForegroundColor Red
    Write-Host "Skipped: $TESTS_SKIPPED" -ForegroundColor Yellow
    Write-Host ""

    if ($TESTS_FAILED -eq 0) {
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "✓ ALL TESTS PASSED!" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host ""
        Show-ServiceInfo
        Write-Host "Services are still running. To stop them, run:" -ForegroundColor Yellow
        if ($script:dockerComposeCmd -eq "docker-compose") {
            Write-Host "  docker-compose down" -ForegroundColor Gray
        } else {
            Write-Host "  docker compose down" -ForegroundColor Gray
        }
        return 0
    } else {
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host "✗ SOME TESTS FAILED" -ForegroundColor Red
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Check container logs:" -ForegroundColor Yellow
        if ($script:dockerComposeCmd -eq "docker-compose") {
            Write-Host "  docker-compose logs backend" -ForegroundColor Gray
            Write-Host "  docker-compose logs frontend" -ForegroundColor Gray
        } else {
            Write-Host "  docker compose logs backend" -ForegroundColor Gray
            Write-Host "  docker compose logs frontend" -ForegroundColor Gray
        }
        return 1
    }
}

# Main execution
$startTime = Get-Date

try {
    Check-Prerequisites
    Start-DockerCompose
    Wait-ForServices
    Test-BackendEndpoints
    Test-FrontendLoading
    Test-DatabasePersistence
    Run-PlaywrightTests

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Host ""
    Write-Host "Total execution time: $([math]::Round($duration))s" -ForegroundColor Cyan
    Write-Host ""

    $exitCode = Generate-TestReport
    exit $exitCode
} catch {
    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host "FATAL ERROR" -ForegroundColor Red
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    exit 1
}
