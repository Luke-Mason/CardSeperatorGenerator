#!/usr/bin/env pwsh
# Start Script - Run all services (MinIO, Backend, Frontend)
# Opens each service in a new terminal window

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Card Separator - Starting Services" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
$minioDir = "$env:USERPROFILE\minio"

# Check if MinIO exists
if (-Not (Test-Path "$minioDir\minio.exe")) {
    Write-Host "[ERROR] MinIO not found!" -ForegroundColor Red
    Write-Host "   Please run .\setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if backend dependencies are installed
if (-Not (Test-Path "$projectRoot\backend\go.mod")) {
    Write-Host "[ERROR] Backend not set up!" -ForegroundColor Red
    Write-Host "   Please run .\setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if frontend dependencies are installed
if (-Not (Test-Path "$projectRoot\web\node_modules")) {
    Write-Host "[ERROR] Frontend dependencies not installed!" -ForegroundColor Red
    Write-Host "   Please run .\setup.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting all services in separate windows..." -ForegroundColor Green
Write-Host ""

# Start MinIO in new window
Write-Host "1. Starting MinIO..." -ForegroundColor Yellow
Write-Host "   API: http://localhost:9000" -ForegroundColor Gray
Write-Host "   Console: http://localhost:9001" -ForegroundColor Gray
Write-Host "   Login: minioadmin / minioadmin" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$minioDir'; .\minio.exe server .\data --console-address ':9001'"

# Wait for MinIO to start
Write-Host "   [WAIT] Waiting for MinIO to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Test MinIO
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
    Write-Host "   [OK] MinIO is running!" -ForegroundColor Green
} catch {
    Write-Host "   [INFO] MinIO is starting - this is normal..." -ForegroundColor Yellow
}

# Start Backend in new window
Write-Host ""
Write-Host "2. Starting Backend..." -ForegroundColor Yellow
Write-Host "   API: http://localhost:8080" -ForegroundColor Gray
Write-Host "   Health: http://localhost:8080/api/health" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\backend'; go run .\src\main.go"

# Wait for backend to start
Write-Host "   [WAIT] Waiting for backend to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Test backend
$backendReady = $false
for ($i = 1; $i -le 10; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        Write-Host "   [OK] Backend is running!" -ForegroundColor Green
        $backendReady = $true
        break
    } catch {
        if ($i -eq 10) {
            Write-Host "   [INFO] Backend is still starting - check the backend window..." -ForegroundColor Yellow
        } else {
            Start-Sleep -Seconds 2
        }
    }
}

# Start Frontend in new window
Write-Host ""
Write-Host "3. Starting Frontend..." -ForegroundColor Yellow
Write-Host "   App: http://localhost:5173" -ForegroundColor Gray

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\web'; npm run dev"

# Wait for frontend
Write-Host "   [WAIT] Waiting for frontend to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  All Services Started!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services:" -ForegroundColor Cyan
Write-Host "   MinIO API:     http://localhost:9000" -ForegroundColor White
Write-Host "   MinIO Console: http://localhost:9001" -ForegroundColor White
Write-Host "   Backend:       http://localhost:8080" -ForegroundColor White
Write-Host "   Frontend:      http://localhost:5173" -ForegroundColor White
Write-Host ""
Write-Host "MinIO Credentials:" -ForegroundColor Cyan
Write-Host "   Username: minioadmin" -ForegroundColor White
Write-Host "   Password: minioadmin" -ForegroundColor White
Write-Host ""
Write-Host "Tips:" -ForegroundColor Cyan
Write-Host "   - Open http://localhost:5173 in your browser" -ForegroundColor Gray
Write-Host "   - Check backend health: http://localhost:8080/api/health" -ForegroundColor Gray
Write-Host "   - To stop: Close each terminal window or press Ctrl+C" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to open the app in your browser..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open browser
Start-Process "http://localhost:5173"

Write-Host ""
Write-Host "[OK] Browser opened. Enjoy developing!" -ForegroundColor Green
Write-Host ""
