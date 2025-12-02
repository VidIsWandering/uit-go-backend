$secret = 'Kf9v2mX3rT9bL6sN1eJ4kZ7uH5cD0aS2fG8mV3wB6yP1qR4tU9lE5jC7xF0zM2nC9'
$iat = [int][double]::Parse((Get-Date -UFormat %s))
$exp = $iat + 3600

$header = '{"alg":"HS384","typ":"JWT"}'
$payload = "{""sub"":""00000000-0000-0000-0000-000000000001"",""role"":""passenger"",""iat"":$iat,""exp"":$exp}"

Write-Host "Payload: $payload" -ForegroundColor Cyan

# Base64url encode
function ConvertTo-Base64Url($text) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($text)
    $b64 = [Convert]::ToBase64String($bytes)
    return $b64.TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

$headerEncoded = ConvertTo-Base64Url $header
$payloadEncoded = ConvertTo-Base64Url $payload
$data = "$headerEncoded.$payloadEncoded"

# Sign with HMACSHA384
$hmac = [Security.Cryptography.HMACSHA384]::new([Text.Encoding]::UTF8.GetBytes($secret))
$signature = [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($data)))
$signatureEncoded = $signature.TrimEnd('=').Replace('+', '-').Replace('/', '_')

$token = "$data.$signatureEncoded"

# Set environment variable for current session
$env:PASSENGER_TOKEN = $token

Write-Host "`nToken (first 80 chars): $($token.Substring(0,80))..." -ForegroundColor Green
Write-Host "`n✅ Token saved to `$env:PASSENGER_TOKEN" -ForegroundColor Green

# Output token for batch script consumption
Write-Output $token
