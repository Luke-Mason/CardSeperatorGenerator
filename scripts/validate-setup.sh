#!/bin/bash

# Card Separator - Setup Validation Script
# This script validates that all components are properly configured

set -e

echo "🔍 Card Separator - Setup Validation"
echo "===================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation counters
PASSED=0
FAILED=0
WARNINGS=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check backend structure
echo "📦 Backend Structure"
echo "-------------------"

if [ -f "backend/main.go" ]; then
    check_pass "backend/main.go exists"
else
    check_fail "backend/main.go missing"
fi

if [ -d "backend/config" ]; then
    check_pass "backend/config package exists"
else
    check_fail "backend/config package missing"
fi

if [ -d "backend/database" ]; then
    check_pass "backend/database package exists"
else
    check_fail "backend/database package missing"
fi

if [ -d "backend/storage" ]; then
    check_pass "backend/storage package exists"
else
    check_fail "backend/storage package missing"
fi

if [ -d "backend/services" ]; then
    check_pass "backend/services package exists"
else
    check_fail "backend/services package missing"
fi

if [ -d "backend/handlers" ]; then
    check_pass "backend/handlers package exists"
else
    check_fail "backend/handlers package missing"
fi

echo ""

# Check Go compilation
echo "🐹 Go Backend Compilation"
echo "------------------------"

if command -v go &> /dev/null; then
    check_pass "Go is installed ($(go version))"

    cd backend
    if go build -o bin/test-server main.go 2>/dev/null; then
        check_pass "Backend compiles successfully"
        rm -f bin/test-server
    else
        check_fail "Backend compilation failed"
    fi
    cd ..
else
    check_warn "Go not installed"
fi

echo ""

# Check Docker setup
echo "🐋 Docker Configuration"
echo "----------------------"

if [ -f "docker-compose.yml" ]; then
    check_pass "docker-compose.yml exists"
else
    check_fail "docker-compose.yml missing"
fi

if [ -f "backend/Dockerfile" ]; then
    check_pass "backend/Dockerfile exists"
else
    check_fail "backend/Dockerfile missing"
fi

if [ -f "web/Dockerfile.dev" ]; then
    check_pass "web/Dockerfile.dev exists"
else
    check_warn "web/Dockerfile.dev missing"
fi

echo ""

# Check Kubernetes setup
echo "☸️  Kubernetes Configuration"
echo "---------------------------"

if [ -f "skaffold.yaml" ]; then
    check_pass "skaffold.yaml exists"
else
    check_fail "skaffold.yaml missing"
fi

if [ -f "helm/Chart.yaml" ]; then
    check_pass "Helm Chart.yaml exists"
else
    check_fail "Helm Chart.yaml missing"
fi

if [ -f "helm/values.yaml" ]; then
    check_pass "Helm values.yaml exists"
else
    check_fail "Helm values.yaml missing"
fi

HELM_TEMPLATES=(
    "helm/templates/backend/deployment.yaml"
    "helm/templates/backend/service.yaml"
    "helm/templates/backend/hpa.yaml"
    "helm/templates/frontend/deployment.yaml"
    "helm/templates/frontend/service.yaml"
    "helm/templates/minio/statefulset.yaml"
    "helm/templates/minio/service.yaml"
    "helm/templates/ingress.yaml"
    "helm/templates/_helpers.tpl"
)

TEMPLATE_COUNT=0
for template in "${HELM_TEMPLATES[@]}"; do
    if [ -f "$template" ]; then
        ((TEMPLATE_COUNT++))
    fi
done

if [ $TEMPLATE_COUNT -eq ${#HELM_TEMPLATES[@]} ]; then
    check_pass "All Helm templates present ($TEMPLATE_COUNT/${#HELM_TEMPLATES[@]})"
else
    check_warn "Some Helm templates missing ($TEMPLATE_COUNT/${#HELM_TEMPLATES[@]})"
fi

echo ""

# Check test setup
echo "🧪 Testing Infrastructure"
echo "-------------------------"

if [ -d "test" ] && [ -f "test/deployment_test.go" ]; then
    check_pass "Terratest integration tests configured"
else
    check_warn "Terratest tests not found"
fi

if [ -d "e2e" ] && [ -f "e2e/playwright.config.ts" ]; then
    check_pass "Playwright E2E tests configured"
else
    check_warn "Playwright tests not found"
fi

if [ -f "test/features/deployment.feature" ]; then
    check_pass "Godog BDD scenarios configured"
else
    check_warn "Godog scenarios not found"
fi

echo ""

# Check Makefile
echo "🔨 Developer Tooling"
echo "-------------------"

if [ -f "Makefile" ]; then
    check_pass "Makefile exists"

    # Count make targets
    TARGET_COUNT=$(grep -c "^[a-zA-Z_-]*:" Makefile || echo "0")
    if [ "$TARGET_COUNT" -gt 30 ]; then
        check_pass "Makefile has $TARGET_COUNT targets"
    else
        check_warn "Makefile has only $TARGET_COUNT targets"
    fi
else
    check_fail "Makefile missing"
fi

echo ""

# Check documentation
echo "📚 Documentation"
echo "---------------"

if [ -f "DEPLOYMENT.md" ]; then
    check_pass "DEPLOYMENT.md exists"
else
    check_warn "DEPLOYMENT.md missing"
fi

if [ -f "README.md" ]; then
    check_pass "README.md exists"
else
    check_warn "README.md missing"
fi

echo ""
echo "===================================="
echo "📊 Validation Summary"
echo "===================================="
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ Setup validation successful!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start Docker Desktop"
    echo "  2. Run: make dev-docker"
    echo "  3. Access: http://localhost:5173"
    exit 0
else
    echo -e "${RED}❌ Setup validation failed${NC}"
    echo "Please fix the issues above and run this script again."
    exit 1
fi
