$ErrorActionPreference = "Stop"
kubectl delete namespace devops-demo
Write-Host "Deleted namespace devops-demo. EKS cluster and ECR repository were not deleted."
