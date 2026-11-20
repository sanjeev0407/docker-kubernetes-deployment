# Architecture

```text
Developer
   |
   v
Java / Spring Boot source
   |
   v
Docker multi-stage build
   |
   v
Amazon ECR image repository
   |
   v
Amazon EKS control plane
   |
   v
Kubernetes Deployment ----> ReplicaSet ----> Pods (2..6)
   |                                           |
   v                                           +--> startup/readiness/liveness probes
ClusterIP Service                              +--> ConfigMap environment
                                               +--> Secret environment
                                               +--> CPU/memory requests and limits
                                               +--> HPA (Metrics Server)
```

The Kubernetes Service provides stable in-cluster networking. For public access,
add an Ingress and AWS Load Balancer Controller with TLS and suitable security controls.
