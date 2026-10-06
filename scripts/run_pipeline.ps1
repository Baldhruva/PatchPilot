# PatchPilot Local DevSecOps Pipeline Runner
param (
    [string]$ImageTag = "patchpilot:local",
    [string]$ReqFile = "requirements.txt",
    [switch]$SkipDeploy = $false
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "         PATCHPILOT DEVSECOPS PIPELINE EXECUTION        " -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# Step 1: Run Pytest
Write-Host "[GATE 1/4] Running Automated Pytest Suite..." -ForegroundColor Yellow
& .\.venv\Scripts\pytest -v
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[SECURITY GATE FAILED] Gate 1: Pytest tests failed! Pipeline Aborted." -ForegroundColor Red
    exit 1
}
Write-Host "[GATE 1 PASSED] Pytest suite executed successfully.`n" -ForegroundColor Green

# Step 2: Run pip-audit
Write-Host "[GATE 2/4] Running Dependency Security Audit (pip-audit)..." -ForegroundColor Yellow
& .\.venv\Scripts\pip-audit.exe -r $ReqFile
$auditExit = $LASTEXITCODE
if ($auditExit -ne 0) {
    Write-Host "`n[SECURITY GATE FAILED] Gate 2: Known vulnerabilities detected in $ReqFile! Deployment BLOCKED." -ForegroundColor Red
    exit 2
}
Write-Host "[GATE 2 PASSED] Zero known vulnerabilities in dependencies.`n" -ForegroundColor Green

# Step 3: Docker Build
Write-Host "[GATE 3/4] Building Hardened Multi-Stage Docker Image ($ImageTag)..." -ForegroundColor Yellow
& docker build -t $ImageTag .
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[PIPELINE FAILED] Gate 3: Docker build failed! Pipeline Aborted." -ForegroundColor Red
    exit 3
}
Write-Host "[GATE 3 PASSED] Docker image built successfully.`n" -ForegroundColor Green

# Step 4: Trivy Image Scan
Write-Host "[GATE 4/4] Running Trivy Container Vulnerability Scan..." -ForegroundColor Yellow
$trivyPath = "C:\Users\Baldhruva\AppData\Local\Microsoft\WinGet\Links\trivy.exe"
& $trivyPath image --severity HIGH,CRITICAL --exit-code 1 $ImageTag
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[SECURITY GATE FAILED] Gate 4: High/Critical vulnerabilities found in container image! Deployment BLOCKED." -ForegroundColor Red
    exit 4
}
Write-Host "[GATE 4 PASSED] Container image passed Trivy security policy.`n" -ForegroundColor Green

# Step 5: Kubernetes Deployment (Only if all gates pass)
if (-not $SkipDeploy) {
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "   ALL SECURITY GATES PASSED -> INITIATING DEPLOYMENT   " -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan

    Write-Host "Loading image into Minikube cluster..." -ForegroundColor Yellow
    & "C:\Program Files\Kubernetes\Minikube\minikube.exe" image load $ImageTag

    Write-Host "Applying Kubernetes manifests (k8s/)..." -ForegroundColor Yellow
    & kubectl apply -f k8s/

    Write-Host "Waiting for deployment rollout..." -ForegroundColor Yellow
    & kubectl rollout status deployment/patchpilot-deployment --timeout=60s

    Write-Host "`n[DEPLOYMENT SUCCESS] PatchPilot is successfully running in Kubernetes!" -ForegroundColor Green
    & kubectl get pods -l app=patchpilot
} else {
    Write-Host "[INFO] Deployment skipped by flag." -ForegroundColor Yellow
}
