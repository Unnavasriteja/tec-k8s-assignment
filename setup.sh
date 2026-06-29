#!/bin/bash

set -e

echo "================================================"
echo " TEC Kubernetes Assignment -- Cluster Setup"
echo "================================================"
echo ""

# ── colours ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${YELLOW}[-->]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# ── preflight checks ──────────────────────────────────
info "Checking required tools..."

command -v docker  >/dev/null 2>&1 || fail "Docker is not installed or not running"
command -v k3d     >/dev/null 2>&1 || fail "k3d is not installed. Run: brew install k3d"
command -v kubectl >/dev/null 2>&1 || fail "kubectl is not installed. Run: brew install kubectl"
command -v helm    >/dev/null 2>&1 || fail "Helm is not installed. Run: brew install helm"

docker info >/dev/null 2>&1 || fail "Docker Desktop is not running. Please start it first."

ok "All required tools found"
echo ""

# ── step 1: create cluster ────────────────────────────
info "Step 1/8: Creating k3d cluster (1 control plane + 2 workers)..."

if k3d cluster list | grep -q "tec-cluster"; then
  echo "  Cluster 'tec-cluster' already exists. Skipping creation."
else
  k3d cluster create tec-cluster \
    --agents 2 \
    --k3s-arg "--disable=traefik@server:0" \
    --port "8080:80@loadbalancer"
fi

ok "Cluster ready"
echo ""

# ── step 2: verify nodes ──────────────────────────────
info "Step 2/8: Verifying cluster nodes..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s
kubectl get nodes
echo ""
ok "All nodes Ready"
echo ""

# ── step 3: deploy nginx ──────────────────────────────
info "Step 3/8: Deploying nginx application..."
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl rollout status deployment/nginx-deployment --timeout=120s
ok "nginx deployed and Running"
echo ""

# ── step 4: monitoring namespace ─────────────────────
info "Step 4/8: Setting up monitoring namespace..."

if kubectl get namespace monitoring >/dev/null 2>&1; then
  echo "  Namespace 'monitoring' already exists. Skipping."
else
  kubectl create namespace monitoring
fi

ok "monitoring namespace ready"
echo ""

# ── step 5: grafana secret ────────────────────────────
info "Step 5/8: Creating Grafana admin secret..."

if kubectl get secret grafana-admin-secret -n monitoring >/dev/null 2>&1; then
  echo "  Secret already exists. Skipping."
else
  kubectl create secret generic grafana-admin-secret \
    --namespace monitoring \
    --from-literal=admin-user=admin \
    --from-literal=admin-password=Tec@Local2026
fi

ok "Grafana secret created"
echo ""

# ── step 6: install prometheus stack ─────────────────
info "Step 6/8: Installing kube-prometheus-stack via Helm..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

if helm list -n monitoring | grep -q "kube-prometheus-stack"; then
  echo "  kube-prometheus-stack already installed. Skipping."
else
  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values monitoring/prometheus-values.yaml \
    --wait \
    --timeout 5m
fi

kubectl apply -f monitoring/alert-rules.yaml
ok "Prometheus, Grafana, Alertmanager installed and custom alert rules applied"
echo ""

# ── step 7: install loki and alloy ───────────────────
info "Step 7/8: Installing Loki and Grafana Alloy for log aggregation..."

helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

if helm list -n monitoring | grep -q "^loki"; then
  echo "  Loki already installed. Skipping."
else
  helm install loki grafana/loki \
    --namespace monitoring \
    --values monitoring/loki-values.yaml \
    --wait \
    --timeout 5m
fi

if helm list -n monitoring | grep -q "^alloy"; then
  echo "  Alloy already installed. Skipping."
else
  helm install alloy grafana/alloy \
    --namespace monitoring \
    --values monitoring/alloy-values.yaml \
    --wait \
    --timeout 5m
fi

ok "Loki and Grafana Alloy installed"
echo ""

# ── step 8: install descheduler ──────────────────────
info "Step 8/8: Installing Descheduler for automatic pod rebalancing..."

helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/ >/dev/null 2>&1 || true
helm repo update >/dev/null 2>&1

if helm list -n kube-system | grep -q "descheduler"; then
  echo "  Descheduler already installed. Skipping."
else
  helm install descheduler descheduler/descheduler \
    --namespace kube-system \
    --set schedule="*/2 * * * *"
fi

ok "Descheduler installed (runs every 2 minutes)"
echo ""

# ── final verification ────────────────────────────────
echo "================================================"
echo " Verifying full stack..."
echo "================================================"
echo ""

echo "Nodes:"
kubectl get nodes
echo ""

echo "Application pods:"
kubectl get pods -o wide
echo ""

echo "Monitoring pods:"
kubectl get pods -n monitoring
echo ""

echo "================================================"
echo -e "${GREEN} Setup complete!${NC}"
echo "================================================"
echo ""
echo "  nginx:     http://localhost:8080"
echo ""
echo "  Grafana:   kubectl --namespace monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80"
echo "             then open http://localhost:3000 (admin / Tec@Local2026)"
echo ""
echo "  Prometheus: kubectl --namespace monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090"
echo "              then open http://localhost:9090"
echo ""
echo "  GitHub: https://github.com/Unnavasriteja/tec-k8s-assignment"
echo ""
