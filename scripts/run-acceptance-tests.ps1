# Comprehensive Acceptance Test Runner for Windows
# This script deploys the application with Skaffold and runs all acceptance tests

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Card Separator Acceptance Test Suite" -ForegroundColor Cyan
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
        default {
            Write-Host $Message
        }
    }
}

function Check-Prerequisites {
    Write-Host "Step 1: Checking Prerequisites..." -ForegroundColor Cyan
    Write-Host "-----------------------------------"

    $missingTools = @()

    # Check Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingTools += "docker"
    } else {
        Print-Status "PASS" "Docker is installed"
    }

    # Check kubectl
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missingTools += "kubectl"
    } else {
        Print-Status "PASS" "kubectl is installed"
    }

    # Check minikube
    if (-not (Get-Command minikube -ErrorAction SilentlyContinue)) {
        $missingTools += "minikube"
    } else {
        Print-Status "PASS" "Minikube is installed"
    }

    # Check skaffold
    if (-not (Get-Command skaffold -ErrorAction SilentlyContinue)) {
        $missingTools += "skaffold"
    } else {
        Print-Status "PASS" "Skaffold is installed"
    }

    # Check go
    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        $missingTools += "go"
    } else {
        Print-Status "PASS" "Go is installed"
    }

    # Check node
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $missingTools += "node"
    } else {
        Print-Status "PASS" "Node.js is installed"
    }

    if ($missingTools.Count -gt 0) {
        Write-Host ""
        Print-Status "FAIL" "Missing required tools: $($missingTools -join ', ')"
        Write-Host "Please run 'make install' to install missing tools"
        exit 1
    }

    Write-Host ""
}

function Check-Minikube {
    Write-Host "Step 2: Checking Minikube Cluster..." -ForegroundColor Cyan
    Write-Host "-------------------------------------"

    $minikubeStatus = minikube status 2>&1 | Out-String
    if ($minikubeStatus -notmatch "Running") {
        Write-Host "Minikube is not running. Starting..."
        minikube start --cpus=4 --memory=8g --driver=docker
        minikube addons enable ingress
        Print-Status "PASS" "Minikube started successfully"
    } else {
        Print-Status "PASS" "Minikube is already running"
    }

    # Verify cluster is accessible
    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "Kubernetes cluster is accessible"
    } else {
        Print-Status "FAIL" "Cannot connect to Kubernetes cluster"
        exit 1
    }

    Write-Host ""
}

function Deploy-WithSkaffold {
    Write-Host "Step 3: Deploying Application with Skaffold..." -ForegroundColor Cyan
    Write-Host "-----------------------------------------------"

    $deployment = kubectl get deployment card-separator-backend 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "SKIP" "Application already deployed, skipping deployment"
    } else {
        Write-Host "Deploying with Skaffold (this may take 5-10 minutes)..."

        skaffold run -p dev
        if ($LASTEXITCODE -eq 0) {
            Print-Status "PASS" "Skaffold deployment succeeded"
        } else {
            Print-Status "FAIL" "Skaffold deployment failed"
            exit 1
        }
    }

    Write-Host ""
}

function Wait-ForServices {
    Write-Host "Step 4: Waiting for Services to be Ready..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------"

    Write-Host "Waiting for backend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/card-separator-backend
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "Backend is ready"
    } else {
        Print-Status "FAIL" "Backend deployment did not become ready"
        kubectl get pods
        exit 1
    }

    Write-Host "Waiting for frontend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/card-separator-frontend
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "Frontend is ready"
    } else {
        Print-Status "FAIL" "Frontend deployment did not become ready"
        kubectl get pods
        exit 1
    }

    Write-Host "Waiting for MinIO deployment..."
    kubectl wait --for=condition=ready --timeout=300s pod/card-separator-minio-0
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "MinIO is ready"
    } else {
        Print-Status "FAIL" "MinIO pod did not become ready"
        kubectl get pods
        exit 1
    }

    Write-Host "Allowing services to fully initialize..."
    Start-Sleep -Seconds 30

    Write-Host ""
}

function Run-GodogTests {
    Write-Host "Step 5: Running Godog BDD Tests..." -ForegroundColor Cyan
    Write-Host "-----------------------------------"

    Push-Location test

    # Run deployment feature tests
    Write-Host "Running deployment.feature..."
    go test -v -run TestDeployment > ..\test-results-deployment.log 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "Deployment tests passed"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "Deployment tests failed (see test-results-deployment.log)"
        $script:TESTS_FAILED++
    }

    # Run API endpoint tests
    Write-Host ""
    Write-Host "Running api_endpoints.feature..."
    go test -v -run TestAPIEndpoints > ..\test-results-api.log 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "API endpoint tests passed"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "API endpoint tests failed (see test-results-api.log)"
        $script:TESTS_FAILED++
    }

    Pop-Location
    Write-Host ""
}

function Run-PlaywrightTests {
    Write-Host "Step 6: Running Playwright E2E Tests..." -ForegroundColor Cyan
    Write-Host "----------------------------------------"

    # Set up port forwarding for tests
    Write-Host "Setting up port forwarding..."
    $backendPF = Start-Process kubectl -ArgumentList "port-forward","svc/card-separator-backend","8080:8080" -PassThru -WindowStyle Hidden
    $frontendPF = Start-Process kubectl -ArgumentList "port-forward","svc/card-separator-frontend","5173:5173" -PassThru -WindowStyle Hidden

    # Wait for port forwarding to establish
    Start-Sleep -Seconds 5

    Push-Location e2e

    # Run deployment tests
    Write-Host "Running deployment.spec.ts..."
    npx playwright test tests/deployment.spec.ts > ..\test-results-e2e-deployment.log 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "E2E deployment tests passed"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "E2E deployment tests failed (see test-results-e2e-deployment.log)"
        $script:TESTS_FAILED++
    }

    # Run UI workflow tests
    Write-Host ""
    Write-Host "Running ui-workflows.spec.ts..."
    npx playwright test tests/ui-workflows.spec.ts > ..\test-results-e2e-ui.log 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "E2E UI workflow tests passed"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "E2E UI workflow tests failed (see test-results-e2e-ui.log)"
        $script:TESTS_FAILED++
    }

    Pop-Location

    # Kill port forwarding processes
    Stop-Process -Id $backendPF.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $frontendPF.Id -Force -ErrorAction SilentlyContinue

    Write-Host ""
}

function Run-InfrastructureTests {
    Write-Host "Step 7: Running Infrastructure Verification..." -ForegroundColor Cyan
    Write-Host "-----------------------------------------------"

    # Check deployments
    Write-Host "Verifying deployments..."
    kubectl get deployment card-separator-backend card-separator-frontend card-separator-minio 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "All deployments exist"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "Some deployments are missing"
        $script:TESTS_FAILED++
    }

    # Check services
    Write-Host "Verifying services..."
    kubectl get service card-separator-backend card-separator-frontend card-separator-minio 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "All services exist"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "Some services are missing"
        $script:TESTS_FAILED++
    }

    # Check PVCs
    Write-Host "Verifying persistent volume claims..."
    kubectl get pvc data-card-separator-minio-0 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Print-Status "PASS" "MinIO PVC exists"
        $script:TESTS_PASSED++
    } else {
        Print-Status "FAIL" "MinIO PVC is missing"
        $script:TESTS_FAILED++
    }

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
        return 0
    } else {
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host "✗ SOME TESTS FAILED" -ForegroundColor Red
        Write-Host "=========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Check the following log files for details:"
        Write-Host "  - test-results-deployment.log"
        Write-Host "  - test-results-api.log"
        Write-Host "  - test-results-e2e-deployment.log"
        Write-Host "  - test-results-e2e-ui.log"
        return 1
    }
}

# Main execution
$startTime = Get-Date

Check-Prerequisites
Check-Minikube
Deploy-WithSkaffold
Wait-ForServices
Run-GodogTests
Run-PlaywrightTests
Run-InfrastructureTests

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "Total execution time: $([math]::Round($duration))s"
Write-Host ""

$exitCode = Generate-TestReport

exit $exitCode
