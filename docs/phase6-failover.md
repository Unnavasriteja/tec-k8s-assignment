# Phase 6: Automatic Failover

## Objective

Demonstrate that the cluster self-heals when a node goes down and
that nginx remains available throughout the failure and recovery.

## Method

Node failure simulated using k3d node stop, which stops the Docker
container acting as the worker node. This is equivalent to a server
losing power or network connectivity.

A continuous curl loop ran against localhost:8080 throughout the
entire event to prove nginx remained available.

## Sequence of Events

### Step 1: Baseline

All 3 nodes Ready, all 3 nginx pods Running across separate nodes.
curl loop confirming HTTP 200 responses every second.

### Step 2: Simulate Node Failure

```bash
k3d node stop k3d-tec-cluster-agent-0
```

Node k3d-tec-cluster-agent-0 moved to NotReady status.
This triggered the NodeNotReady custom alert rule configured in Phase 5.

### Step 3: Self-Healing

The Deployment controller detected the replica count dropped from 3
to 2 and immediately created a replacement pod. The replacement pod
scheduled onto a surviving node within seconds because
topologySpreadConstraints uses ScheduleAnyway, which allows the
scheduler to place the pod on a node that already has one nginx pod
rather than leaving it Pending.

Full replica count of 3 was maintained throughout the failure.

### Step 4: Traffic Behavior

The curl loop showed a brief interruption of approximately 3-5 seconds
during node failure. This is expected behavior during abrupt node loss.
When a node stops suddenly there is no graceful shutdown period and
the Service endpoint controller requires time to detect the pod is
gone and update the routing table.

A preStop lifecycle hook was added to reduce this window. It sleeps
5 seconds before container shutdown during graceful termination events
such as rolling updates and planned maintenance. It cannot prevent
the brief interruption during sudden node failure.

After the brief interruption, HTTP 200 responses resumed immediately
and continued for the remainder of the demo.

### Step 5: Node Recovery

```bash
k3d node start k3d-tec-cluster-agent-0
```

The moment agent-0 returned to Ready status, the pending replacement
pod scheduled directly onto it, automatically restoring the balanced
spread. The topologySpreadConstraints guided the scheduler to choose
the node with the lowest pod count which was the recovered node.

### Step 6: Full Recovery

All 3 nodes Ready, all 3 pods Running, one per node.
No manual pod deletion required for rebalancing.

## Observed Behavior

| Event | nginx Status |
|-------|-------------|
| Baseline | HTTP 200 continuous |
| Node stopped | HTTP 200 (2 pods serving) |
| Brief interruption | ~3-5 seconds connection failure |
| Replacement scheduled | HTTP 200 (3 pods serving) |
| Node recovered | HTTP 200 (3 pods, rebalanced) |

## Key Observations

topologySpreadConstraints with ScheduleAnyway allowed the replacement
pod to schedule immediately onto a surviving node during failure.
This is a significant improvement over hard anti-affinity which would
have left the pod Pending until a valid node was available.

The default node eviction timeout is 5 minutes. This is intentional.
Kubernetes does not immediately reschedule pods when a node goes down
because the outage could be a brief network blip. For this demo force
eviction was used to demonstrate the behavior without waiting the full
timeout. In production the correct approach for planned maintenance is
kubectl cordon and kubectl drain which evicts pods immediately and
gracefully.

## In Production

In production on AWS EKS, when a node becomes unhealthy the Auto
Scaling Group detects it and automatically provisions a replacement
EC2 instance. The new node joins the cluster and pending pods
schedule onto it without any manual intervention. Combined with
Cluster Autoscaler or Karpenter, the entire recovery is fully
automated. The Kubernetes Descheduler handles automatic pod
rebalancing after node recovery.
