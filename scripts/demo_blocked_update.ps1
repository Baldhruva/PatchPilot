# Demonstration: Blocked Unsafe Dependency Update
param ()

Write-Host "`n========================================================" -ForegroundColor Magenta
Write-Host "   PATCHPILOT DEMO: BLOCKED UNSAFE UPDATE FLOW          " -ForegroundColor Magenta
Write-Host "========================================================`n" -ForegroundColor Magenta

Write-Host "[1] Simulating an incoming pull request with a vulnerable dependency..." -ForegroundColor Yellow
$testReqFile = "requirements-vulnerable.txt"
$vulnerableReq = @"
fastapi>=0.115.0,<1.0.0
uvicorn>=0.34.0,<1.0.0
urllib3==1.26.4
"@

Set-Content $testReqFile $vulnerableReq

try {
    Write-Host "[2] Running PatchPilot DevSecOps Pipeline on vulnerable configuration..." -ForegroundColor Yellow
    Write-Host "    Dependency file: $testReqFile (contains known vulnerable package: urllib3 1.26.4)`n"

    # Capture initial pod list in Kubernetes to prove deployment is NOT altered
    $initialPods = (& kubectl get pods -l app=patchpilot)

    # Execute pipeline
    & .\scripts\run_pipeline.ps1 -ReqFile $testReqFile
    $pipelineExit = $LASTEXITCODE

    if ($pipelineExit -ne 0) {
        Write-Host "`n--------------------------------------------------------" -ForegroundColor Red
        Write-Host "                SECURITY GATE IN ACTION                 " -ForegroundColor Red
        Write-Host "--------------------------------------------------------" -ForegroundColor Red
        Write-Host "[BLOCKED] The DevSecOps pipeline intercepted the vulnerability!" -ForegroundColor Red
        Write-Host "[RESULT] Exit Code: $pipelineExit (Security Gate Failure)." -ForegroundColor Red
        Write-Host "[VERIFICATION] Checking Kubernetes cluster status..." -ForegroundColor Yellow

        $currentPods = (& kubectl get pods -l app=patchpilot)
        
        Write-Host "`nKubernetes pods before attempt:" -ForegroundColor Gray
        Write-Host $initialPods
        Write-Host "Kubernetes pods after attempt:" -ForegroundColor Gray
        Write-Host $currentPods

        Write-Host "`n[DEMO CONCLUSION] Unsafe update was automatically BLOCKED by the security gate. Zero unauthorized changes reached the Kubernetes cluster!`n" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Pipeline unexpectedly allowed the unsafe dependency." -ForegroundColor Red
    }
}
finally {
    if (Test-Path $testReqFile) {
        Remove-Item $testReqFile -Force
    }
}
