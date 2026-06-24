# Phase 1: Cluster Setup

## Tool Choice: k3d

k3d runs Kubernetes nodes as Docker containers on the local machine.
Selected over other options for these reasons:

| Tool | Reason not chosen |
|------|------------------|
| minikube | Multi-node support is limited and not production-like |
| kind | Slower on M2 Mac |
| kubeadm + VMs | Too resource heavy for 8GB RAM |
| k3d | Lightweight, M2 compatible, nodes run as containers |

## Cluster Architecture

1 control plane + 2 worker nodes. This is the minimum setup needed
to demonstrate pod spreading across nodes and simulate node failover.

## Command Used

```bash
k3d cluster create tec-cluster \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  --port "8080:80@loadbalancer"
```

## Flags Explained

- `--agents 2`: creates 2 worker nodes
- `--disable=traefik`: removes the default ingress controller to save memory
- `--port "8080:80"`: maps localhost:8080 on the Mac to port 80 inside the cluster

## Verified Output

All 3 nodes showing Ready status confirmed via kubectl get nodes.

## High Availability in Production

Locally this runs with a single control plane node. In production, HA requires:
- Minimum 3 control plane nodes
- etcd distributed across all 3 nodes (odd number needed for quorum)
- If one control plane goes down, the remaining two maintain cluster state
- Managed services like EKS and GKE handle this automatically
