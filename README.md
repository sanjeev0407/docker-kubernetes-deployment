#  Docker and Kubernetes on AWS EKS

A hands-on containerization and Kubernetes deployment project using a small Java 17
Spring Boot REST API, Docker, Kubernetes manifests, and Amazon EKS.

## What this project demonstrates

- Multi-stage Docker image build and non-root runtime
- Kubernetes Namespace, Deployment, Service, ConfigMap and Secret
- Readiness, liveness and startup probes
- CPU/memory requests and limits
- Horizontal Pod Autoscaler (HPA)
- Rolling updates and rollback
- EKS deployment and operational troubleshooting

> This repository contains deployable application and Kubernetes configuration.
> It does not create an EKS cluster or AWS networking automatically. Create or select
> an EKS cluster before following the EKS deployment section. AWS resources may incur
> charges.

## Repository structure

```text
project3-docker-kubernetes/
├── app/
│   ├── src/main/java/com/example/demo/
│   │   ├── DemoApplication.java
│   │   └── HealthController.java
│   ├── src/main/resources/application.yml
│   ├── src/test/java/com/example/demo/HealthControllerTest.java
│   └── pom.xml
├── docker/
│   ├── Dockerfile
│   └── .dockerignore
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.example.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml
├── scripts/
│   ├── build-push-ecr.ps1
│   ├── deploy.ps1
│   └── cleanup.ps1
├── docs/
│   ├── architecture.md
│   └── troubleshooting.md
└── .gitignore
```

## Prerequisites

- Windows 10/11 with PowerShell
- Java 17 and Maven 3.9+
- Docker Desktop
- `kubectl`
- AWS CLI v2
- `eksctl` (only if creating a cluster)
- An AWS account and permissions appropriate for ECR/EKS

## 1. Build and test the application locally

From the repository root:

```powershell
mvn -f app/pom.xml clean verify
```

Run the JAR:

```powershell
java -jar app/target/k8s-demo-app.jar
```

In another PowerShell window:

```powershell
Invoke-RestMethod http://localhost:8080/api/health
Invoke-RestMethod http://localhost:8080/api/info
```

## 2. Build and run the Docker image

```powershell
docker build -f docker/Dockerfile -t k8s-demo-app:1.0.0 .
docker run --rm -d --name k8s-demo -p 8080:8080 k8s-demo-app:1.0.0
Invoke-RestMethod http://localhost:8080/api/health
docker logs k8s-demo
docker stop k8s-demo
```

## 3. Test on a local Kubernetes cluster

Start Docker Desktop Kubernetes or use another local Kubernetes cluster, then confirm:

```powershell
kubectl config current-context
kubectl get nodes
```

Load the local image into the local cluster. For Docker Desktop Kubernetes, the image
built by Docker Desktop is normally available directly. If using kind or minikube,
follow that tool's image-loading procedure.

Create the example Secret from a local value. Do not commit real secret values:

```powershell
kubectl create namespace devops-demo
kubectl -n devops-demo create secret generic app-secret `
  --from-literal=demo-api-key='replace-with-a-local-demo-value' `
  --dry-run=client -o yaml | kubectl apply -f -
```

Apply the remaining resources:

```powershell
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

For local testing, the Service is `ClusterIP`. Use port forwarding:

```powershell
kubectl -n devops-demo port-forward service/k8s-demo-service 8080:80
```

Then call `http://localhost:8080/api/health`.

The HPA manifest requires the Kubernetes Metrics Server. Apply it only after
Metrics Server is available:

```powershell
kubectl apply -f k8s/hpa.yaml
kubectl -n devops-demo get hpa
```

## 4. Deploy to Amazon EKS

### 4.1 Select the AWS region and cluster

```powershell
aws sts get-caller-identity
aws eks update-kubeconfig --region ap-south-1 --name YOUR_EKS_CLUSTER
kubectl config current-context
kubectl get nodes
```

Replace `YOUR_EKS_CLUSTER` with your actual cluster name.

### 4.2 Create an ECR repository

```powershell
aws ecr create-repository `
  --repository-name k8s-demo-app `
  --image-scanning-configuration scanOnPush=true `
  --region ap-south-1
```

If it already exists, continue without recreating it.

### 4.3 Build and push the image

Use the provided script:

```powershell
.\scripts\build-push-ecr.ps1 `
  -Region ap-south-1 `
  -Repository k8s-demo-app `
  -Tag 1.0.0
```

The script discovers your AWS account ID, authenticates Docker to ECR, builds the
image and pushes it.

### 4.4 Update the deployment image

```powershell
$accountId = aws sts get-caller-identity --query Account --output text
$image = "$accountId.dkr.ecr.ap-south-1.amazonaws.com/k8s-demo-app:1.0.0"
(Get-Content k8s/deployment.yaml -Raw).Replace("REPLACE_WITH_ECR_IMAGE", $image) |
  Set-Content k8s/deployment-eks.yaml
```

Create the namespace and Secret securely:

```powershell
kubectl apply -f k8s/namespace.yaml
kubectl -n devops-demo create secret generic app-secret `
  --from-literal=demo-api-key='replace-with-your-secret' `
  --dry-run=client -o yaml | kubectl apply -f -
```

Apply ConfigMap, Deployment and Service:

```powershell
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment-eks.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deployment/k8s-demo-deployment -n devops-demo
kubectl get pods,svc -n devops-demo
```

The Service is ClusterIP. For external access, add an AWS Load Balancer Controller
and an Ingress manifest appropriate to your cluster, or use port-forwarding for
a temporary test. Do not expose the application publicly without appropriate
network controls and TLS.

### 4.5 Enable autoscaling

Install/configure Metrics Server for your cluster, then:

```powershell
kubectl apply -f k8s/hpa.yaml
kubectl get hpa -n devops-demo
kubectl top pods -n devops-demo
```

HPA scales on CPU utilization relative to the CPU requests. It will not scale
correctly if Metrics Server is unavailable or resource requests are omitted.

## 5. Verify and operate

```powershell
kubectl get all -n devops-demo
kubectl describe deployment k8s-demo-deployment -n devops-demo
kubectl logs deployment/k8s-demo-deployment -n devops-demo
kubectl rollout history deployment/k8s-demo-deployment -n devops-demo
```

Rollback:

```powershell
kubectl rollout undo deployment/k8s-demo-deployment -n devops-demo
kubectl rollout status deployment/k8s-demo-deployment -n devops-demo
```

Cleanup:

```powershell
.\scripts\cleanup.ps1
```

This removes only the Kubernetes namespace created for this demo. It does not delete
your EKS cluster or ECR repository.

## Security and production considerations

- Never commit real credentials or populated Secret manifests.
- Kubernetes Secret values are base64-encoded, not encrypted by base64 itself.
  Enable EKS secret encryption and use AWS Secrets Manager with an approved
  integration for production workloads.
- Use IAM Roles for Service Accounts (IRSA) or EKS Pod Identity for AWS access;
  do not place AWS access keys in Pods.
- Use least-privilege IAM and Kubernetes RBAC.
- Pin container images by immutable tag or digest and scan images.
- Configure network policies where supported, Pod Security Standards and
  admission controls.
- Set resource requests/limits and meaningful health probes.
- Use multiple replicas and disruption budgets for production availability.
- Add Ingress/ALB, TLS, logging, metrics and alerting before production exposure.
- Review EKS, NAT, load balancer and data-transfer costs before provisioning.

## Learning outcomes

At completion, be prepared to explain the difference between a Pod, Deployment,
ReplicaSet and Service; how ConfigMaps and Secrets are consumed; how probes work;
how rolling updates and rollback work; and how HPA uses metrics to scale Pods.
