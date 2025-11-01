$email = "test$(Get-Random)@uit.edu.vn"
$body = @{
    email = $email
    password = 'secret123'
    fullName = 'Test User'
    phone = '0909999888'
    role = 'PASSENGER'
} | ConvertTo-Json

Write-Host "`n=== REGISTER ===" -ForegroundColor Cyan
$regResp = Invoke-RestMethod -Uri 'http://localhost:8088/api/users' -Method Post -ContentType 'application/json' -Body $body
Write-Host "Registered: id=$($regResp.id), email=$($regResp.email)" -ForegroundColor Green

Write-Host "`n=== LOGIN ===" -ForegroundColor Cyan
$loginBody = @{email=$email; password='secret123'} | ConvertTo-Json
$loginResp = Invoke-RestMethod -Uri 'http://localhost:8088/api/sessions' -Method Post -ContentType 'application/json' -Body $loginBody
$token = $loginResp.access_token
Write-Host "Logged in, token: $($token.Substring(0,20))..." -ForegroundColor Green

Write-Host "`n=== CREATE TRIP ===" -ForegroundColor Cyan
$tripBody = @{
    origin = @{latitude=10.87; longitude=106.803}
    destination = @{latitude=10.88; longitude=106.813}
} | ConvertTo-Json -Depth 5
$tripResp = Invoke-RestMethod -Uri 'http://localhost:8088/api/trips' -Method Post -ContentType 'application/json' -Headers @{Authorization="Bearer $token"} -Body $tripBody
Write-Host "Trip created: id=$($tripResp.id), status=$($tripResp.status), passengerId=$($tripResp.passengerId)" -ForegroundColor Green

Write-Host "`n=== ESTIMATE ===" -ForegroundColor Cyan
$estimateResp = Invoke-RestMethod -Uri 'http://localhost:8088/api/trips/estimate' -Method Post -ContentType 'application/json' -Body $tripBody
Write-Host "Estimate: price=$($estimateResp.estimatedPrice), distance=$($estimateResp.distanceMeters)m" -ForegroundColor Green

Write-Host "`n✅ All tests passed!" -ForegroundColor Green
