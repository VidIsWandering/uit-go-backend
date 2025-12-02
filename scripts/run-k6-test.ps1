param(
    [Parameter(Mandatory = $true)]
    [string]$TestScript,
    
    [Parameter(Mandatory = $true)]
    [int]$TargetVUs,
    
    [Parameter(Mandatory = $true)]
    [string]$RunLabel,
    
    [Parameter(Mandatory = $true)]
    [int]$Threshold
)

# Generate token
$token = .\scripts\generate-token.ps1 | Select-Object -Last 1

Write-Host "Running k6 test: $TestScript" -ForegroundColor Cyan
Write-Host "Target VUs: $TargetVUs" -ForegroundColor Cyan
Write-Host "Token generated successfully" -ForegroundColor Green

# Run docker and capture output
$output = docker run -i --rm `
    -v "${PWD}/tests/k6:/scripts" `
    --network uit-go-backend_default `
    -e BASE_URL=http://nginx `
    -e API_PREFIX=/api `
    -e ASYNC=1 `
    -e TARGET_VUS=$TargetVUs `
    -e RUN_LABEL=$RunLabel `
    -e PASSENGER_TOKEN=$token `
    -e ASYNC_P95_THRESHOLD=$Threshold `
    -e K6_INFLUXDB_ADDR=http://influxdb:8086 `
    -e K6_INFLUXDB_DB=k6 `
    grafana/k6:latest run --out influxdb /scripts/$TestScript 2>&1

# Display k6 output in real-time
$output | ForEach-Object { Write-Host $_ }

$exitCode = $LASTEXITCODE

# Parse JSON log line for p95 metric - support both formats
# spike-test.js: {"label":"...","p95":2456.55,"vus":300}
# stress-test.js: {"label":"...","overall_p95":5802.17}
$jsonLine = $output | Where-Object { $_ -match '^\{.*"label".*\}$' } | Select-Object -First 1

# Parse iterations count from output (e.g., "6700 complete")
$iterationsLine = $output | Where-Object { $_ -match 'running \(.*\), \d+/\d+ VUs, (\d+) complete' } | Select-Object -Last 1
$iterations = 0
if ($iterationsLine -match '(\d+) complete') {
    $iterations = [int]$matches[1]
}

# Check for HTTP errors (4xx, 5xx) in output - ignore k6 internal errors
$hasErrors = ($output | Where-Object { $_ -match 'http_req_failed.*rate=[1-9]' }).Count -gt 0

if ($jsonLine) {
    try {
        $metrics = $jsonLine | ConvertFrom-Json
        
        # Support both p95 formats
        $p95Value = if ($metrics.p95) { $metrics.p95 } elseif ($metrics.overall_p95) { $metrics.overall_p95 } else { 0 }
        $vusValue = if ($metrics.vus) { $metrics.vus } else { $TargetVUs }
        
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Yellow
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Test Label: $($metrics.label)" -ForegroundColor White
        Write-Host "Max VUs: $vusValue" -ForegroundColor White
        Write-Host "Total Iterations: $iterations" -ForegroundColor White
        Write-Host ""
        Write-Host "p95 Latency: $([math]::Round($p95Value, 2))ms" -ForegroundColor Cyan
        
        # Display error rate based on http_req_failed metric
        if ($hasErrors) {
            Write-Host "Error Rate: > 0% (HTTP errors detected)" -ForegroundColor Red
        }
        else {
            Write-Host "Error Rate: 0% (no HTTP errors)" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        
        # Check thresholds based on PowerShell threshold, not k6 exit code
        $thresholdPassed = $p95Value -lt $Threshold
        
        if (-not $thresholdPassed -or $hasErrors) {
            Write-Host "THRESHOLDS CROSSED - Test FAILED" -ForegroundColor Red
            Write-Host "   p95 threshold: < ${Threshold}ms" -ForegroundColor Yellow
            Write-Host "   p95 actual: $([math]::Round($p95Value, 2))ms" -ForegroundColor $(if ($thresholdPassed) { "Green" } else { "Red" })
            if ($hasErrors) {
                Write-Host "   error rate: > 0%" -ForegroundColor Red
            }
        }
        else {
            Write-Host "ALL THRESHOLDS PASSED" -ForegroundColor Green
            Write-Host "   p95: $([math]::Round($p95Value, 2))ms < ${Threshold}ms" -ForegroundColor Green
            Write-Host "   error rate: 0%" -ForegroundColor Green
        }
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "Warning: Could not parse k6 metrics" -ForegroundColor Yellow
        exit 1
    }
}
else {
    Write-Host ""
    Write-Host "Warning: No k6 metrics JSON found in output" -ForegroundColor Yellow
    exit 1
}

# Exit based on PowerShell threshold check, not k6's exit code
if ($p95Value -ge $Threshold -or $hasErrors) {
    exit 99  # Failed threshold
}
else {
    exit 0   # Passed
}