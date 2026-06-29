# Phase 3: Pod Spreading with topologySpreadConstraints

## The Problem

Without spreading constraints, the Kubernetes scheduler distributes
pods across nodes by default but does not guarantee it. Under certain
conditions multiple pods can land on the same node. If that node goes
down, multiple pods are lost simultaneously and capacity drops.

## Why topologySpreadConstraints Over Hard Anti-Affinity

Hard pod anti-affinity (requiredDuringSchedulingIgnoredDuringExecution)
guarantees one pod per node but has a critical limitation: if a node
fails and no valid node is available, the replacement pod stays Pending
indefinitely. This means the Deployment cannot recover to the desired
replica count until a new node is added.

topologySpreadConstraints with whenUnsatisfiable: ScheduleAnyway
provides a better balance for this cluster:

- Pods spread evenly across nodes during normal operation
- During a node failure, the replacement pod schedules immediately
  onto a surviving node even if that node already has one nginx pod
- Full replica count is maintained throughout the failure
- Once the failed node recovers, pods rebalance automatically

## Configuration

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
      app: nginx
```

## Fields Explained

maxSkew: 1 -- the maximum allowed difference in pod count between
any two nodes. The scheduler tries to keep pods evenly distributed
within this tolerance.

topologyKey: kubernetes.io/hostname -- each node is treated as a
separate zone. The constraint applies at the node level.

whenUnsatisfiable: ScheduleAnyway -- if the constraint cannot be
satisfied (for example during a node failure), schedule the pod
anyway rather than leaving it Pending. Prioritizes availability
over strict spreading.

labelSelector: app: nginx -- the constraint applies only to pods
with this label.

## Verified Behavior

kubectl describe pod confirms:
Topology Spread Constraints: kubernetes.io/hostname:ScheduleAnyway
when max skew 1 is exceeded for selector app=nginx

All 3 pods confirmed on separate nodes via kubectl get pods -o wide.

## In Production

In a cloud environment, change topologyKey to
topology.kubernetes.io/zone to spread pods across availability zones
rather than just nodes within a single zone. This protects against
a full AZ outage. The Kubernetes Descheduler can be used to
automatically rebalance pods after node recovery without manual
intervention.
