#!/usr/bin/env pwsh
# Local Development Startup Script
# Runs MinIO and Backend without Docker

Write-Host "🚀 Starting Local Development Environment" -ForegroundColor Green
Write-Host ""

# Check if MinIO exists
$minioPath = "C:\minio\minio.exe"
if (-Not (Test-Path $minioPath)) {
    Write-Host "⚠️  MinIO not found at $minioPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Downloading MinIO..." -ForegroundColor Cyan

    # Create directory
    New-Item -ItemType Directory -Force -Path "C:\minio" | Out-Null
    New-Item -ItemType Directory -Force -Path "C:\minio\data" | Out-Null

    # Download MinIO
    Invoke-WebRequest -Uri "https://dl.min.io/server/minio/release/windows-amd64/minio.exe" -OutFile $minioPath
    Write-Host "✅ MinIO downloaded successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "📦 Starting MinIO Server..." -ForegroundColor Cyan
Write-Host "   API: http://localhost:9000" -ForegroundColor Gray
Write-Host "   Console: http://localhost:9001" -ForegroundColor Gray
Write-Host "   Credentials: minioadmin / minioadmin" -ForegroundColor Gray
Write-Host ""

# Start MinIO in background
$minioJob = Start-Job -ScriptBlock {
    Set-Location "C:\minio"
    .\minio.exe server .\data --console-address ":9001"
}

Write-Host "✅ MinIO started (Job ID: $($minioJob.Id))" -ForegroundColor Green

# Wait for MinIO to be ready
Write-Host ""
Write-Host "⏳ Waiting for MinIO to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

# Test MinIO
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ MinIO is ready!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  MinIO may not be ready yet, continuing anyway..." -ForegroundColor Yellow
}

# Start Backend
Write-Host ""
Write-Host "🔧 Starting Backend Server..." -ForegroundColor Cyan
Write-Host "   API: http://localhost:8080" -ForegroundColor Gray
Write-Host ""

Set-Location "$PSScriptRoot\..\backend"

# Create data directory if it doesn't exist
New-Item -ItemType Directory -Force -Path ".\data" | Out-Null

# Run backend
go run .\src\main.go

# Cleanup function (runs when script is terminated)
# Note: MinIO job will keep running after script exits
Write-Host ""
Write-Host "💡 To stop MinIO later, run: Stop-Job -Id $($minioJob.Id); Remove-Job -Id $($minioJob.Id)" -ForegroundColor Yellow
