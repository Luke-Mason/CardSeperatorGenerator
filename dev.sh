#!/bin/bash

# Card Separator Development Script
# Provides a smooth developer experience with hot-reload for both frontend and backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

success() {
    echo -e "${GREEN}✓ ${NC}$1"
}

error() {
    echo -e "${RED}✗ ${NC}$1"
}

warning() {
    echo -e "${YELLOW}⚠ ${NC}$1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prereqs() {
    info "Checking prerequisites..."

    local missing=()

    if ! command_exists node; then
        missing+=("Node.js")
    fi

    if ! command_exists npm; then
        missing+=("npm")
    fi

    if ! command_exists go; then
        missing+=("Go")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        error "Please install them and try again"
        exit 1
    fi

    success "All prerequisites installed"
}

# Install dependencies
install_deps() {
    info "Installing dependencies..."

    # Frontend
    if [ ! -d "web/node_modules" ]; then
        info "Installing frontend dependencies..."
        cd web && npm install && cd ..
        success "Frontend dependencies installed"
    else
        success "Frontend dependencies already installed"
    fi

    # Backend
    info "Installing backend dependencies..."
    cd backend && go mod download && cd ..
    success "Backend dependencies installed"
}

# Start backend in background
start_backend() {
    info "Starting Go backend on :8080..."

    cd backend
    go run src/main.go &
    BACKEND_PID=$!
    cd ..

    # Wait for backend to be ready
    for i in {1..30}; do
        if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
            success "Backend is ready!"
            return 0
        fi
        sleep 1
    done

    warning "Backend may not be fully ready, but continuing anyway..."
}

# Start frontend
start_frontend() {
    info "Starting Vite frontend on :5173..."

    cd web
    npm run dev
}

# Cleanup on exit
cleanup() {
    info "\nShutting down..."

    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
        success "Backend stopped"
    fi

    exit 0
}

# Set up trap for cleanup
trap cleanup EXIT INT TERM

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Card Separator - Dev Environment    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    check_prereqs
    install_deps

    echo ""
    info "Starting development servers..."
    echo ""

    start_backend
    sleep 2
    start_frontend
}

# Run main
main
