# Card Separator - Deployment Guide

## 🚀 Quick Start

### Prerequisites Installation

Run the automated setup:

```bash
# Install all required tools (Docker, kubectl, Helm, Skaffold, Minikube, Godog, Playwright)
make install

# Verify installations
make help
```

### Local Development (Docker Compose)

```bash
# Start all services with Docker Compose
make dev-docker

# Access:
# - Frontend: http://localhost:5173
# - Backend API: http://localhost:8080
# - MinIO Console: http://localhost:9001
```

### Local Kubernetes Development

```bash
# 1. Start Minikube cluster
make k8s-start

# 2. Deploy with Skaffold (hot-reload enabled)
make dev

# 3. Access services (auto port-forwarded):
# - Frontend: http://localhost:5173
# - Backend: http://localhost:8080
# - MinIO Console: http://localhost:9001
```

---

## 🏗️ Architecture Overview

```
┌──────────────────────────────────────────┐
│         CloudFlare CDN (Optional)         │
└────────────────┬─────────────────────────┘
                 │
┌────────────────┴─────────────────────────┐
│         Kubernetes Ingress (NGINX)        │
└────────────────┬─────────────────────────┘
                 │
       ┌─────────┴─────────┐
       │                   │
┌──────┴──────┐    ┌──────┴──────┐
│  Frontend   │    │   Backend   │
│  (Svelte)   │────│   (Go API)  │
│  2-3 pods   │    │  3-10 pods  │
└─────────────┘    └──────┬──────┘
                          │
                ┌─────────┼─────────┐
                │         │         │
         ┌──────┴──┐  ┌──┴───┐  ┌──┴────┐
         │  MinIO  │  │SQLite│  │ Sync  │
         │ 1-3nodes│  │  DB  │  │Worker │
         └─────────┘  └──────┘  └───────┘
```

---

## 📋 Deployment Workflows

### Development Workflow

```bash
# Terminal 1: Start Kubernetes
make k8s-start

# Terminal 2: Deploy with Skaffold (hot-reload)
make dev

# Make code changes - Skaffold will auto-rebuild and redeploy!
```

### Staging Deployment

```bash
# Deploy to staging cluster
make deploy-staging

# Monitor deployment
kubectl get pods -w

# Check logs
make logs-k8s
```

### Production Deployment

```bash
# Deploy to production
make deploy-prod

# Verify health
make health

# Monitor
kubectl get hpa
kubectl top pods
```

---

## 🧪 Testing Strategy

### 1. Unit Tests

```bash
# Backend unit tests
make backend-test

# Frontend unit tests (if available)
cd web && npm test
```

### 2. Integration Tests (Terratest + Godog)

```bash
# Run BDD integration tests
make test-integration

# This will:
# 1. Deploy application via Skaffold
# 2. Run Godog feature tests
# 3. Verify all pods are running
# 4. Test API endpoints
# 5. Verify MinIO storage
# 6. Test HPA configuration
```

**Test Features:**
- ✅ Deployment verification
- ✅ Pod health checks
- ✅ API functionality
- ✅ Database persistence
- ✅ MinIO storage
- ✅ Auto-scaling configuration
- ✅ Image caching workflow

### 3. E2E Tests (Playwright)

```bash
# Run Playwright E2E tests
make test-e2e

# Run with UI
cd e2e && npx playwright test --ui

# Run in debug mode
cd e2e && npx playwright test --debug
```

**E2E Test Coverage:**
- ✅ Backend health checks
- ✅ Frontend page load
- ✅ Set loading workflow
- ✅ Card filtering
- ✅ Image proxy functionality
- ✅ API sync operations
- ✅ Error handling
- ✅ Performance benchmarks

### 4. Complete Test Suite

```bash
# Run all tests
make test

# This executes:
# 1. Backend unit tests
# 2. Terratest integration tests
# 3. Playwright E2E tests
```

---

## 🔧 Configuration

### Environment Variables

All configuration is managed via Helm values or environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_PATH` | `/data/cards.db` | SQLite database location |
| `MINIO_ENDPOINT` | `minio:9000` | MinIO server endpoint |
| `MINIO_ACCESS_KEY` | `minioadmin` | MinIO access key |
| `MINIO_SECRET_KEY` | `minioadmin` | MinIO secret key |
| `MINIO_BUCKET` | `card-images` | S3 bucket name |
| `AUTO_SYNC_ON_STARTUP` | `true` | Sync sets on startup |
| `SET_SYNC_INTERVAL_HOURS` | `24` | Auto-sync interval |

### Helm Values

**Development (values.yaml):**
```yaml
backend:
  replicaCount: 1
  autoscaling:
    enabled: false

minio:
  replicas: 1
```

**Production (values-prod.yaml):**
```yaml
backend:
  replicaCount: 5
  autoscaling:
    enabled: true
    minReplicas: 5
    maxReplicas: 20

minio:
  mode: distributed
  replicas: 3
```

---

## 📊 Monitoring & Observability

### Health Checks

```bash
# Check application health
make health

# Response:
# {
#   "status": "ok",
#   "database": "ok",
#   "minio": "ok",
#   "timestamp": "2026-01-06T..."
# }
```

### Cache Statistics

```bash
# View cache stats
make cache-stats

# Response:
# {
#   "total_sets": 15,
#   "total_cards": 1250,
#   "total_images": 5000,
#   "image_counts": {
#     "thumbnail": 1250,
#     "medium": 1250,
#     "full": 1250,
#     "original": 1250
#   }
# }
```

### Kubernetes Metrics

```bash
# Pod status
kubectl get pods

# HPA status
kubectl get hpa

# Resource usage
kubectl top pods
kubectl top nodes

# Logs
make logs-k8s
kubectl logs -f deployment/card-separator-backend
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          make install
          make test

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to staging
        run: make deploy-staging

  deploy-prod:
    needs: deploy-staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: make deploy-prod
```

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods

# View pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common issues:
# 1. Image pull errors - check Skaffold build
# 2. Resource limits - check HPA and node resources
# 3. PVC not bound - check storage class
```

### MinIO Connection Issues

```bash
# Port-forward to MinIO
kubectl port-forward svc/card-separator-minio 9000:9000

# Access console
open http://localhost:9001

# Check bucket
kubectl exec -it card-separator-minio-0 -- mc ls local/card-images
```

### Database Issues

```bash
# Check PVC
kubectl get pvc

# Access database
kubectl exec -it <backend-pod> -- sqlite3 /data/cards.db "SELECT COUNT(*) FROM sets;"
```

---

## 📈 Scaling

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment card-separator-backend --replicas=10

# Scale frontend
kubectl scale deployment card-separator-frontend --replicas=5
```

### Auto-Scaling (HPA)

Auto-scaling is configured via Helm:

```yaml
backend:
  autoscaling:
    enabled: true
    minReplicas: 5
    maxReplicas: 20
    targetCPUUtilization: 70
    targetMemoryUtilization: 80
```

Monitor HPA:

```bash
kubectl get hpa
kubectl describe hpa card-separator-backend
```

---

## 🔒 Security

### Secrets Management

Use Kubernetes secrets for production:

```bash
# Create MinIO secret
kubectl create secret generic minio-secret \
  --from-literal=accesskey=YOUR_ACCESS_KEY \
  --from-literal=secretkey=YOUR_SECRET_KEY

# Update Helm values to use secret
```

### Network Policies

Apply network policies to restrict pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

---

## 💰 Cost Optimization

### Development

- Use Minikube locally (free)
- Single replica for all services
- Disable autoscaling

### Production

**Estimated Monthly Cost:**

| Service | Configuration | Cost (GKE) |
|---------|--------------|------------|
| 3x n1-standard-2 nodes | 2 vCPU, 7.5GB RAM each | ~$150 |
| 100GB SSD storage | PersistentVolumes | ~$15 |
| Load Balancer | Ingress | ~$20 |
| **Total** | | **~$185/month** |

**For 1000+ concurrent users!**

---

## 🚀 Next Steps

1. **Set up CI/CD**: Integrate with GitHub Actions
2. **Add Monitoring**: Deploy Prometheus + Grafana
3. **Configure CDN**: Set up CloudFlare (free tier)
4. **Enable HTTPS**: Use cert-manager with Let's Encrypt
5. **Add Logging**: Deploy ELK stack or use cloud logging

---

## 📚 Additional Resources

- [Skaffold Documentation](https://skaffold.dev/)
- [Helm Charts Guide](https://helm.sh/docs/)
- [Terraform Documentation](https://www.terraform.io/)
- [Playwright Testing](https://playwright.dev/)
- [Godog BDD Framework](https://github.com/cucumber/godog)

---

## 🆘 Support

For issues or questions:
1. Check this guide
2. Review logs: `make logs-k8s`
3. Run health checks: `make health`
4. Check GitHub issues
