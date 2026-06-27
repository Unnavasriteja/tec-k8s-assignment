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