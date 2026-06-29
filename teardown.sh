#!/bin/bash

echo "================================================"
echo " TEC Kubernetes Assignment -- Teardown"
echo "================================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${YELLOW}[-->]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC} $1"; }

info "Deleting k3d cluster 'tec-cluster'..."
k3d cluster delete tec-cluster && ok "Cluster deleted" || echo "  Cluster not found, skipping."

echo ""
ok "Teardown complete. All cluster resources removed."
echo ""
echo "To recreate the cluster, run: ./setup.sh"
echo ""
