# Phase 1 — Cluster Setup

## Tool Choice: k3d

k3d runs Kubernetes nodes as Docker containers on your local machine.
Chosen over alternatives for the following reasons:

| Tool | Reason not chosen |
|------|------------------|
| minikube | Multi-node support is clunky, not production-like |
| kind | Slower on M2 Mac |
| kubeadm + VMs | Too heavy for 8GB RAM |
| k3d | Lightweight, M2 native, nodes as containers |

## Cluster Architecture

1 control plane + 2 worker nodes — minimum required for demonstrating
pod spreading and node failover.

## Command Used

```bash
k3d cluster create tec-cluster \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  --port "8080:80@loadbalancer"
```

## Flags Explained

- `--agents 2` — creates 2 worker nodes
- `--disable=traefik` — removes default ingress to save RAM
- `--port "8080:80"` — maps localhost:8080 to cluster port 80

## Verified Output

kubectl get nodes shows all 3 nodes in Ready state.

## High Availability in Production

Locally we run 1 control plane node. In production, HA means:
- 3 control plane nodes minimum
- etcd distributed across all 3 (needs odd number for quorum)
- If 1 control plane goes down, the other 2 maintain cluster state
- Tools like kubeadm or managed services (EKS, GKE) handle this automatically
