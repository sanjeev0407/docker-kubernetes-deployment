# Kubernetes troubleshooting runbook

| Symptom | Commands | What to inspect |
|---|---|---|
| Pod Pending | `kubectl describe pod POD -n devops-demo` | CPU/memory capacity, scheduling, taints, PVCs |
| ImagePullBackOff | `kubectl describe pod POD -n devops-demo` | ECR URI, node/pod pull permissions, network |
| CrashLoopBackOff | `kubectl logs POD -n devops-demo --previous` | Application startup errors, config, memory |
| Readiness failing | `kubectl describe pod POD -n devops-demo` | Probe path, port, startup duration |
| Service has no endpoints | `kubectl get endpoints -n devops-demo` | Service selector versus Pod labels and readiness |
| HPA unknown metrics | `kubectl get hpa -n devops-demo` | Metrics Server and resource requests |
| Rollout stuck | `kubectl rollout status deploy/k8s-demo-deployment -n devops-demo` | Events, readiness, image pull, capacity |

Useful commands:

```bash
kubectl get pods -n devops-demo -o wide
kubectl get events -n devops-demo --sort-by=.lastTimestamp
kubectl describe deployment k8s-demo-deployment -n devops-demo
kubectl logs deployment/k8s-demo-deployment -n devops-demo
kubectl rollout history deployment/k8s-demo-deployment -n devops-demo
kubectl rollout undo deployment/k8s-demo-deployment -n devops-demo
kubectl top pods -n devops-demo
```
