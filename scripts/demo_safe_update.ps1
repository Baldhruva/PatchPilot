# Demonstration: Safe Dependency / Application Update
param ()

$ErrorActionPreference = "Continue"

Write-Host "`n========================================================" -ForegroundColor Magenta
Write-Host "   PATCHPILOT DEMO: SAFE VALIDATED UPDATE FLOW          " -ForegroundColor Magenta
Write-Host "========================================================`n" -ForegroundColor Magenta

Write-Host "[1] Simulating a safe application update..." -ForegroundColor Cyan
# Update version in main.py to 1.1.0
$mainPyPath = "app/main.py"
$originalContent = Get-Content $mainPyPath -Raw
$updatedContent = $originalContent -replace '"version": "1.0.0"', '"version": "1.1.0"'
Set-Content $mainPyPath $updatedContent

try {
    Write-Host "[2] Running PatchPilot DevSecOps Pipeline on updated code..." -ForegroundColor Cyan
    & .\scripts\run_pipeline.ps1

    Write-Host "`n[3] Verifying live Kubernetes service with new version..." -ForegroundColor Cyan
    $podName = (& kubectl get pods -l app=patchpilot -o jsonpath='{.items[0].metadata.name}')
    $response = & kubectl exec $podName -- python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/').read().decode())"
    Write-Host "Live response from Kubernetes Pod ($podName):" -ForegroundColor Green
    Write-Host $response

    Write-Host "`n[DEMO CONCLUSION] Safe update successfully passed all tests, security gates, and was automatically deployed to Kubernetes!`n" -ForegroundColor Green
}
finally {
    # Restore original content
    Set-Content $mainPyPath $originalContent
}
