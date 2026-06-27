# Phase 6: Automatic Failover

## Objective

Demonstrate that the cluster self-heals when a node goes down and
that nginx remains available throughout the failure and recovery.

## Method

Node failure simulated using k3d node stop, which stops the Docker
container acting as the worker node. This is equivalent to a server
losing power or network connectivity.

## Sequence of Events

### Step 1: Baseline

All 3 nodes Ready, all 3 nginx pods Running across separate nodes.
curl loop running against localhost:8080 confirming 200 responses.

### Step 2: Simulate Node Failure

```bash
k3d node stop k3d-tec-cluster-agent-0
```

Node k3d-tec-cluster-agent-0 immediately moved to NotReady status.
This triggered the NodeNotReady custom alert rule configured in Phase 5.

### Step 3: Self-Healing Begins

The Deployment controller detected the replica count dropped from 3
to 2 and immediately created a replacement pod (7v9nj). This is
self-healing -- no human intervention required.

The replacement pod entered Pending state because the anti-affinity
rule correctly refused to place two nginx pods on the same node.
With agent-0 dead, agent-1 and server-0 already had one pod each.
The scheduler held the pod in Pending rather than violate the
spreading constraint.

Throughout this entire period the curl loop continued returning
HTTP 200. Two surviving pods maintained full traffic availability.

### Step 4: Node Recovery

```bash
k3d node start k3d-tec-cluster-agent-0
```

The moment agent-0 returned to Ready status, the scheduler
immediately placed the pending pod onto it. Pod transitioned from
Pending to ContainerCreating to Running in under 10 seconds.

### Step 5: Full Recovery

All 3 nodes Ready, all 3 pods Running across separate nodes.
7v9nj confirmed Running on k3d-tec-cluster-agent-0.
curl loop continued showing 200 throughout entire sequence.

## Observed Behavior

| Event | Time | nginx Status |
|-------|------|-------------|
| Node stopped | T+0s | 200 OK (2 pods serving) |
| Node NotReady | T+5s | 200 OK (2 pods serving) |
| Pod Terminating, replacement Pending | T+10s | 200 OK (2 pods serving) |
| Node restarted | T+4m | 200 OK (2 pods serving) |
| Replacement pod Running | T+4m30s | 200 OK (3 pods serving) |

## Why the Pod Stayed Pending

In this local setup we have exactly 3 nodes and 3 pods with a hard
anti-affinity rule. When one node died there were no valid nodes
remaining. In production this would not happen because:

1. Production clusters run more nodes than replicas
2. Cluster Autoscaler provisions new nodes automatically when
   pods stay Pending
3. Pods spread across multiple availability zones so a single
   node or AZ failure still leaves valid scheduling targets

The Pending behavior validates that the anti-affinity rule works
correctly under pressure. It refused to violate the constraint
even during a failure event.

## Key Takeaway

The Deployment controller created a replacement pod immediately
and automatically. nginx served traffic from 2 pods throughout
the entire event without a single failed request. Full capacity
was restored the moment the node recovered.
