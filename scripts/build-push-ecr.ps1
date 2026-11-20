param(
    [Parameter(Mandatory = $true)][string]$Region,
    [Parameter(Mandatory = $true)][string]$Repository,
    [Parameter(Mandatory = $false)][string]$Tag = "1.0.0"
)

$ErrorActionPreference = "Stop"
$accountId = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accountId)) {
    throw "Unable to identify AWS account. Check AWS CLI credentials."
}

$registry = "$accountId.dkr.ecr.$Region.amazonaws.com"
$image = "$registry/$Repository`:$Tag"

aws ecr describe-repositories --repository-names $Repository --region $Region *> $null
if ($LASTEXITCODE -ne 0) {
    aws ecr create-repository --repository-name $Repository --image-scanning-configuration scanOnPush=true --region $Region
    if ($LASTEXITCODE -ne 0) { throw "Could not create ECR repository." }
}

aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry
if ($LASTEXITCODE -ne 0) { throw "ECR Docker login failed." }

docker build -f docker/Dockerfile -t $image .
if ($LASTEXITCODE -ne 0) { throw "Docker build failed." }

docker push $image
if ($LASTEXITCODE -ne 0) { throw "Docker push failed." }

Write-Host "Image pushed: $image"
