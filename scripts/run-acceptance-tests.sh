#!/bin/bash
# Comprehensive Acceptance Test Runner
# This script deploys the application with Skaffold and runs all acceptance tests

set -e

echo "========================================="
echo "Card Separator Acceptance Test Suite"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to print colored output
print_status() {
    if [ "$1" == "PASS" ]; then
        echo -e "${GREEN}✓ $2${NC}"
    elif [ "$1" == "FAIL" ]; then
        echo -e "${RED}✗ $2${NC}"
    elif [ "$1" == "SKIP" ]; then
        echo -e "${YELLOW}⊘ $2${NC}"
    else
        echo "$2"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo "Step 1: Checking Prerequisites..."
    echo "-----------------------------------"

    MISSING_TOOLS=()

    # Check Docker
    if ! command -v docker &> /dev/null; then
        MISSING_TOOLS+=("docker")
    else
        print_status "PASS" "Docker is installed"
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        MISSING_TOOLS+=("kubectl")
    else
        print_status "PASS" "kubectl is installed"
    fi

    # Check minikube
    if ! command -v minikube &> /dev/null; then
        MISSING_TOOLS+=("minikube")
    else
        print_status "PASS" "Minikube is installed"
    fi

    # Check skaffold
    if ! command -v skaffold &> /dev/null; then
        MISSING_TOOLS+=("skaffold")
    else
        print_status "PASS" "Skaffold is installed"
    fi

    # Check go
    if ! command -v go &> /dev/null; then
        MISSING_TOOLS+=("go")
    else
        print_status "PASS" "Go is installed"
    fi

    # Check node
    if ! command -v node &> /dev/null; then
        MISSING_TOOLS+=("node")
    else
        print_status "PASS" "Node.js is installed"
    fi

    if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
        echo ""
        print_status "FAIL" "Missing required tools: ${MISSING_TOOLS[*]}"
        echo "Please run 'make install' to install missing tools"
        exit 1
    fi

    echo ""
}

# Function to check/start Minikube
check_minikube() {
    echo "Step 2: Checking Minikube Cluster..."
    echo "-------------------------------------"

    if ! minikube status | grep -q "Running"; then
        echo "Minikube is not running. Starting..."
        minikube start --cpus=4 --memory=8g --driver=docker
        minikube addons enable ingress
        print_status "PASS" "Minikube started successfully"
    else
        print_status "PASS" "Minikube is already running"
    fi

    # Verify cluster is accessible
    if kubectl cluster-info &> /dev/null; then
        print_status "PASS" "Kubernetes cluster is accessible"
    else
        print_status "FAIL" "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    echo ""
}

# Function to deploy with Skaffold
deploy_with_skaffold() {
    echo "Step 3: Deploying Application with Skaffold..."
    echo "-----------------------------------------------"

    # Check if already deployed
    if kubectl get deployment card-separator-backend &> /dev/null; then
        print_status "SKIP" "Application already deployed, skipping deployment"
    else
        echo "Deploying with Skaffold (this may take 5-10 minutes)..."

        if skaffold run -p dev; then
            print_status "PASS" "Skaffold deployment succeeded"
        else
            print_status "FAIL" "Skaffold deployment failed"
            exit 1
        fi
    fi

    echo ""
}

# Function to wait for services to be ready
wait_for_services() {
    echo "Step 4: Waiting for Services to be Ready..."
    echo "--------------------------------------------"

    echo "Waiting for backend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/card-separator-backend || {
        print_status "FAIL" "Backend deployment did not become ready"
        kubectl get pods
        exit 1
    }
    print_status "PASS" "Backend is ready"

    echo "Waiting for frontend deployment..."
    kubectl wait --for=condition=available --timeout=300s deployment/card-separator-frontend || {
        print_status "FAIL" "Frontend deployment did not become ready"
        kubectl get pods
        exit 1
    }
    print_status "PASS" "Frontend is ready"

    echo "Waiting for MinIO deployment..."
    kubectl wait --for=condition=ready --timeout=300s pod/card-separator-minio-0 || {
        print_status "FAIL" "MinIO pod did not become ready"
        kubectl get pods
        exit 1
    }
    print_status "PASS" "MinIO is ready"

    # Wait a bit more for services to fully initialize
    echo "Allowing services to fully initialize..."
    sleep 30

    echo ""
}

# Function to run Godog BDD tests
run_godog_tests() {
    echo "Step 5: Running Godog BDD Tests..."
    echo "-----------------------------------"

    cd test

    # Run deployment feature tests
    echo "Running deployment.feature..."
    if go test -v -run TestDeployment 2>&1 | tee ../test-results-deployment.log; then
        print_status "PASS" "Deployment tests passed"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "Deployment tests failed (see test-results-deployment.log)"
        ((TESTS_FAILED++))
    fi

    # Run API endpoint tests
    echo ""
    echo "Running api_endpoints.feature..."
    if go test -v -run TestAPIEndpoints 2>&1 | tee ../test-results-api.log; then
        print_status "PASS" "API endpoint tests passed"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "API endpoint tests failed (see test-results-api.log)"
        ((TESTS_FAILED++))
    fi

    cd ..
    echo ""
}

# Function to run Playwright E2E tests
run_playwright_tests() {
    echo "Step 6: Running Playwright E2E Tests..."
    echo "----------------------------------------"

    # Set up port forwarding for tests
    echo "Setting up port forwarding..."
    kubectl port-forward svc/card-separator-backend 8080:8080 &
    BACKEND_PF_PID=$!
    kubectl port-forward svc/card-separator-frontend 5173:5173 &
    FRONTEND_PF_PID=$!

    # Wait for port forwarding to establish
    sleep 5

    cd e2e

    # Run deployment tests
    echo "Running deployment.spec.ts..."
    if npx playwright test tests/deployment.spec.ts 2>&1 | tee ../test-results-e2e-deployment.log; then
        print_status "PASS" "E2E deployment tests passed"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "E2E deployment tests failed (see test-results-e2e-deployment.log)"
        ((TESTS_FAILED++))
    fi

    # Run UI workflow tests
    echo ""
    echo "Running ui-workflows.spec.ts..."
    if npx playwright test tests/ui-workflows.spec.ts 2>&1 | tee ../test-results-e2e-ui.log; then
        print_status "PASS" "E2E UI workflow tests passed"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "E2E UI workflow tests failed (see test-results-e2e-ui.log)"
        ((TESTS_FAILED++))
    fi

    cd ..

    # Kill port forwarding processes
    kill $BACKEND_PF_PID $FRONTEND_PF_PID 2>/dev/null || true

    echo ""
}

# Function to check Kubernetes resources (Terratest)
run_infrastructure_tests() {
    echo "Step 7: Running Infrastructure Verification..."
    echo "-----------------------------------------------"

    # Check deployments
    echo "Verifying deployments..."
    if kubectl get deployment card-separator-backend card-separator-frontend card-separator-minio &> /dev/null; then
        print_status "PASS" "All deployments exist"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "Some deployments are missing"
        ((TESTS_FAILED++))
    fi

    # Check services
    echo "Verifying services..."
    if kubectl get service card-separator-backend card-separator-frontend card-separator-minio &> /dev/null; then
        print_status "PASS" "All services exist"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "Some services are missing"
        ((TESTS_FAILED++))
    fi

    # Check PVCs
    echo "Verifying persistent volume claims..."
    if kubectl get pvc data-card-separator-minio-0 &> /dev/null; then
        print_status "PASS" "MinIO PVC exists"
        ((TESTS_PASSED++))
    else
        print_status "FAIL" "MinIO PVC is missing"
        ((TESTS_FAILED++))
    fi

    echo ""
}

# Function to generate test report
generate_test_report() {
    echo "========================================="
    echo "Test Results Summary"
    echo "========================================="
    echo ""

    TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

    echo "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}========================================="
        echo -e "✓ ALL TESTS PASSED!"
        echo -e "=========================================${NC}"
        return 0
    else
        echo -e "${RED}========================================="
        echo -e "✗ SOME TESTS FAILED"
        echo -e "=========================================${NC}"
        echo ""
        echo "Check the following log files for details:"
        echo "  - test-results-deployment.log"
        echo "  - test-results-api.log"
        echo "  - test-results-e2e-deployment.log"
        echo "  - test-results-e2e-ui.log"
        return 1
    fi
}

# Main execution
main() {
    START_TIME=$(date +%s)

    check_prerequisites
    check_minikube
    deploy_with_skaffold
    wait_for_services
    run_godog_tests
    run_playwright_tests
    run_infrastructure_tests

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo ""
    echo "Total execution time: ${DURATION}s"
    echo ""

    generate_test_report

    # Return appropriate exit code
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main
