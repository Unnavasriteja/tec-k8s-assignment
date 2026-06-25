# Phase 3: Pod Anti-Affinity

## The Problem Anti-Affinity Solves

Without anti-affinity rules, the Kubernetes scheduler spreads pods
across nodes by default but does not guarantee it. With more replicas
or after rescheduling events, multiple pods can land on the same node.
If that node goes down, multiple pods are lost simultaneously.

## The Rule

Added podAntiAffinity with requiredDuringSchedulingIgnoredDuringExecution.
This is a hard rule. If the scheduler cannot satisfy it, the pod will
not be scheduled at all. The alternative, preferredDuring, is a soft
preference that can be ignored under resource pressure.

The topologyKey kubernetes.io/hostname means each node is treated as
a separate zone. The rule translates to: never place an nginx pod on
a node that already has an nginx pod running.

## Verified Behavior

kubectl describe pod shows FailedScheduling events followed by
successful scheduling. The warning confirms the scheduler actively
evaluated and enforced the anti-affinity rule before placing each pod.

All 3 pods confirmed on separate nodes via kubectl get pods -o wide.

## Why This Matters in Production

In production with 10+ replicas across 5 nodes, without anti-affinity
you could end up with 4 pods on one node and 1 on each of the others.
Losing the heavy node takes down 40 percent of capacity instantly.
Anti-affinity distributes the blast radius evenly.
