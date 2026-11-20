param(
    [Parameter(Mandatory = $true)][string]$ImageUri
)

$ErrorActionPreference = "Stop"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

Write-Host "Create the app-secret in the cluster before deploying. Do not commit secret values."
kubectl -n devops-demo get secret app-secret *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Secret app-secret is missing. Create it using the secure command in README.md."
}

$template = Get-Content "k8s/deployment.yaml" -Raw
$template = $template.Replace("REPLACE_WITH_ECR_IMAGE", $ImageUri)
$template | Set-Content "k8s/deployment-rendered.yaml" -Encoding utf8

kubectl apply -f k8s/deployment-rendered.yaml
if ($LASTEXITCODE -ne 0) { throw "Deployment apply failed." }

kubectl apply -f k8s/service.yaml
if ($LASTEXITCODE -ne 0) { throw "Service apply failed." }

kubectl rollout status deployment/k8s-demo-deployment -n devops-demo --timeout=180s
if ($LASTEXITCODE -ne 0) { throw "Deployment did not become ready. Inspect Pods and events." }

kubectl get pods,svc -n devops-demo
