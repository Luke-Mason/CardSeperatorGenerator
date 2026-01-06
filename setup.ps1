#!/usr/bin/env pwsh
# Setup Script - Install all dependencies for Card Separator
# Run this once to set up your development environment

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Card Separator - Setup Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = $PSScriptRoot
$minioDir = "$env:USERPROFILE\minio"

# Function to check if a command exists
function Test-Command {
    param($Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Check Go
Write-Host "1. Checking Go installation..." -ForegroundColor Yellow
if (Test-Command "go") {
    $goVersion = go version
    Write-Host "   [OK] Go is installed: $goVersion" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Go is NOT installed" -ForegroundColor Red
    Write-Host "   Please install Go from: https://golang.org/dl/" -ForegroundColor Yellow
    Write-Host "   Then re-run this script." -ForegroundColor Yellow
    exit 1
}

# Check Node.js
Write-Host ""
Write-Host "2. Checking Node.js installation..." -ForegroundColor Yellow
if (Test-Command "node") {
    $nodeVersion = node --version
    Write-Host "   [OK] Node.js is installed: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Node.js is NOT installed" -ForegroundColor Red
    Write-Host "   Please install Node.js from: https://nodejs.org/" -ForegroundColor Yellow
    Write-Host "   Then re-run this script." -ForegroundColor Yellow
    exit 1
}

# Download MinIO
Write-Host ""
Write-Host "3. Setting up MinIO..." -ForegroundColor Yellow
if (Test-Path "$minioDir\minio.exe") {
    Write-Host "   [OK] MinIO already downloaded" -ForegroundColor Green
} else {
    Write-Host "   Downloading MinIO..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path $minioDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$minioDir\data" | Out-Null

    try {
        Invoke-WebRequest -Uri "https://dl.min.io/server/minio/release/windows-amd64/minio.exe" `
            -OutFile "$minioDir\minio.exe" `
            -UseBasicParsing
        Write-Host "   [OK] MinIO downloaded to $minioDir" -ForegroundColor Green
    } catch {
        Write-Host "   [ERROR] Failed to download MinIO: $_" -ForegroundColor Red
        exit 1
    }
}

# Install Backend Dependencies
Write-Host ""
Write-Host "4. Installing Backend dependencies..." -ForegroundColor Yellow
Set-Location "$projectRoot\backend"

if (-Not (Test-Path "go.mod")) {
    Write-Host "   [ERROR] go.mod not found in backend directory" -ForegroundColor Red
    exit 1
}

try {
    go mod download
    Write-Host "   [OK] Backend dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] Failed to install backend dependencies: $_" -ForegroundColor Red
    exit 1
}

# Create backend data directory
New-Item -ItemType Directory -Force -Path "$projectRoot\backend\data" | Out-Null
Write-Host "   [OK] Created backend data directory" -ForegroundColor Green

# Install Frontend Dependencies
Write-Host ""
Write-Host "5. Installing Frontend dependencies..." -ForegroundColor Yellow
Set-Location "$projectRoot\web"

if (-Not (Test-Path "package.json")) {
    Write-Host "   [ERROR] package.json not found in web directory" -ForegroundColor Red
    exit 1
}

try {
    npm install
    Write-Host "   [OK] Frontend dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "   [ERROR] Failed to install frontend dependencies: $_" -ForegroundColor Red
    exit 1
}

# Create .env file for backend if it doesn't exist
Write-Host ""
Write-Host "6. Configuring environment..." -ForegroundColor Yellow
$envFilePath = "$projectRoot\backend\.env"

if (-Not (Test-Path $envFilePath)) {
    Write-Host "   Creating .env file..." -ForegroundColor Cyan
    $envContent = "PORT=8080`nDATABASE_PATH=./data/cards.db`nMINIO_ENDPOINT=localhost:9000`nMINIO_ACCESS_KEY=minioadmin`nMINIO_SECRET_KEY=minioadmin`nMINIO_BUCKET=card-images`nMINIO_USE_SSL=false`nMINIO_REGION=us-east-1`nAUTO_SYNC_ON_STARTUP=true`nSET_SYNC_INTERVAL_HOURS=24`nCACHE_MAX_AGE_HOURS=168"
    Set-Content -Path $envFilePath -Value $envContent -Encoding UTF8
    Write-Host "   [OK] Created .env file" -ForegroundColor Green
}
else {
    Write-Host "   [OK] .env file already exists" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "MinIO location: $minioDir" -ForegroundColor Gray
Write-Host "Backend config: $envFilePath" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: .\start.ps1" -ForegroundColor White
Write-Host "  2. Open your browser to: http://localhost:5173" -ForegroundColor White
Write-Host ""
Write-Host "To stop services:" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C in each terminal window" -ForegroundColor White
Write-Host ""

Set-Location $projectRoot
