# Phase 2: Application Deployment

## What was deployed

nginx web server with 3 replicas across the cluster nodes.

## Why nginx

The assignment evaluates Kubernetes patterns, not application complexity.
nginx provides a real HTTP server with a health endpoint out of the box,
zero configuration needed, and is universally understood. It lets the
focus stay on the infrastructure decisions.

## Deployment Strategy

RollingUpdate was chosen over Recreate for zero downtime updates.

- maxSurge: 1 means one extra pod can exist temporarily during rollout
- maxUnavailable: 1 means one pod can be down during rollout
- At minimum 2 pods are always serving traffic during an update

## Image Pinning

nginx:1.25 used instead of latest. In production you never use latest
because you lose the ability to track what version is actually running
and rollbacks become unreliable.

## Resource Limits

Every container has requests and limits defined:
- Requests tell the scheduler the minimum resources needed
- Limits prevent a single pod from consuming all node resources
- This is a production requirement, not optional

## Service

LoadBalancer type service selected to expose nginx.
The selector app: nginx ensures traffic reaches all 3 pods.
In k3d this maps to localhost:8080 via the port configured at cluster creation.

## Verified

All 3 pods Running across 3 different nodes confirmed via kubectl get pods -o wide.
nginx welcome page confirmed accessible at http://localhost:8080.
