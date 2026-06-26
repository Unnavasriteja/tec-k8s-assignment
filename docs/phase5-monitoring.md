# Phase 5: Observability Stack

## Components Installed

| Component | Purpose |
|-----------|---------|
| Prometheus | Metrics collection and storage |
| Grafana | Metrics and log visualization |
| Alertmanager | Alert routing and notification |
| Loki | Log aggregation and storage |
| Grafana Alloy | Log collection from all pods |

## Why kube-prometheus-stack

Installs Prometheus, Grafana, Alertmanager, node exporters, and
kube-state-metrics in a single Helm chart. This is the production
standard for Kubernetes monitoring. Manually installing each
component separately would introduce version compatibility issues
and significantly more configuration overhead.

## Resource Constraints

Default kube-prometheus-stack values are too heavy for a local
8GB machine. A custom values file was used to set memory requests
and limits on every component. Prometheus retention was reduced
to 12 hours and scrape interval increased to 30 seconds to reduce
disk and CPU usage.

## Custom Alert Rules

Two custom PrometheusRule resources were created:

NodeNotReady: fires when a node has been in NotReady state for
more than 1 minute. Uses kube_node_status_condition metric.
Severity: critical.

PodRestartingTooMuch: fires when a pod restarts more than 5 times
in 15 minutes. Uses rate() on kube_pod_container_status_restarts_total.
Severity: warning.

The label release: kube-prometheus-stack is required on the
PrometheusRule resource so the Prometheus operator picks it up
automatically.

## Why Grafana Alloy Instead of Promtail

The assignment suggested Loki + Promtail. Promtail reached end of
life on March 2, 2026. Grafana Alloy is the current recommended
replacement for log collection. Alloy runs as a DaemonSet with one
pod per node, collects logs from all containers, attaches Kubernetes
metadata labels, and ships to Loki automatically.

## Log Verification

Logs verified in two ways:

1. Grafana Explore view using LogQL query {namespace="default"}
   shows nginx access logs with full Kubernetes metadata labels.

2. kubectl logs aggregation across all pods:
   kubectl logs -l app=nginx --all-containers=true --prefix=true
   Shows logs from all 3 pods simultaneously with pod name prefix.

Both approaches confirm liveness and readiness probes hitting nginx
every 5 seconds and returning HTTP 200.
