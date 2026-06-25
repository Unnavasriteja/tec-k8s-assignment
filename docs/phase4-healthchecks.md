# Phase 4: Health Checks

## Liveness Probe

Checks if the container is alive and functioning.
If it fails, Kubernetes restarts the container.

Configuration:
- HTTP GET request to / on port 80
- initialDelaySeconds: 10 (wait 10s after start before first check)
- periodSeconds: 10 (check every 10 seconds)
- failureThreshold: 3 (restart only after 3 consecutive failures)

When this would trigger in production:
nginx process running but stuck, deadlocked, or unresponsive.
The container appears alive but serves no traffic.
Liveness kills and restarts it automatically.

## Readiness Probe

Checks if the container is ready to serve traffic.
If it fails, the pod is removed from Service endpoints.
The container is not restarted.

Configuration:
- HTTP GET request to / on port 80
- initialDelaySeconds: 5 (check sooner than liveness)
- periodSeconds: 5 (check every 5 seconds)
- failureThreshold: 3 (remove from rotation after 3 consecutive failures)

When this would trigger in production:
Container just started and is still warming up.
It is alive but not yet ready to handle requests.
Readiness keeps traffic away until the app is fully up.

## Key Difference

Liveness failure restarts the container.
Readiness failure removes it from traffic rotation without restarting.
Both can be true simultaneously on the same pod.

## Verified Output

kubectl describe pod confirms both probes active with correct configuration.
All pod conditions show True meaning readiness probe passed
and pods are actively receiving traffic.
