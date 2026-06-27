# TEC Kubernetes Assignment

## Overview

This project deploys a production-like Kubernetes cluster locally using k3d,
with a stateless nginx web application configured for high availability,
automatic failover, and full observability.

The setup demonstrates core Kubernetes engineering practices including
pod scheduling guarantees, self-healing deployments, health checks,
metrics collection, log aggregation, and node failure recovery.

## Repository Structure

```
tec-k8s-assignment/
├── cluster/          # Cluster setup documentation
├── manifests/        # Kubernetes deployment and service manifests
├── monitoring/       # Prometheus, Loki, and Alloy configuration
├── docs/             # Phase documentation
└── screenshots/      # Evidence for each phase
```
## Architecture

![Architecture Diagram](screenshots/architecture-diagram.png)

### Key Design Decisions

k3d was chosen over minikube and kind because it runs Kubernetes nodes
as Docker containers rather than VMs, making it significantly lighter
on resources. It also has native ARM support and spins up in under a minute.

All monitoring components run in a dedicated monitoring namespace, isolated
from the application in the default namespace. This mirrors production
practice for RBAC and resource management.

## Cluster Setup

Tool: k3d v5.9.0
Nodes: 1 control plane + 2 worker nodes

### Command

```bash
k3d cluster create tec-cluster \
  --agents 2 \
  --k3s-arg "--disable=traefik@server:0" \
  --port "8080:80@loadbalancer"
```

### Verified

All 3 nodes confirmed Ready via kubectl get nodes.

![Cluster nodes ready](screenshots/phase1-nodes-ready.png)

### High Availability Note

This setup runs a single control plane node, which is not HA.
In production, HA requires a minimum of 3 control plane nodes.
etcd uses the Raft consensus algorithm and needs an odd number
of nodes for quorum. With 3 nodes, losing 1 still leaves 2 able
to agree on cluster state. Managed services like EKS handle this
automatically across availability zones without any manual configuration.

## Application Deployment

Tool: nginx:1.25
Replicas: 3, spread across all nodes via pod anti-affinity

### Deployment Strategy

RollingUpdate was chosen over Recreate to ensure zero downtime during
updates. maxSurge: 1 allows one extra pod during rollout. maxUnavailable: 1
means at minimum 2 pods are always serving traffic during an update.

### Pod Anti-Affinity

A hard anti-affinity rule guarantees one nginx pod per node. Without this,
the scheduler spreads pods by default but does not guarantee it. The rule
uses requiredDuringSchedulingIgnoredDuringExecution with topologyKey
kubernetes.io/hostname, meaning the scheduler will not place a pod on a
node that already has an nginx pod running.

Proof of enforcement: kubectl describe pod showed FailedScheduling events
confirming the scheduler evaluated and enforced the rule before placement.

![Pods running across nodes](screenshots/phase2-pods-running.png)

![Anti-affinity enforced](screenshots/phase3-antiaffinity-proof.png)

### Service

A LoadBalancer Service exposes nginx on localhost:8080. The selector
app: nginx routes traffic to all 3 pods automatically.

![nginx running in browser](screenshots/phase2-nginx-browser.png)

## Health Checks

Both liveness and readiness probes are configured on every nginx container.

### Liveness Probe

Checks if the container is alive and functioning. If it fails, Kubernetes
restarts the container. Configured with initialDelaySeconds: 10 to prevent
killing a container that is still starting up.

### Readiness Probe

Checks if the container is ready to serve traffic. If it fails, the pod
is removed from Service endpoints without restarting. Configured with
initialDelaySeconds: 5 to detect readiness as quickly as possible.

Both probes use HTTP GET on port 80 with failureThreshold: 3 to avoid
action on a single slow response.

![Probes configured](screenshots/phase4-probes.png)