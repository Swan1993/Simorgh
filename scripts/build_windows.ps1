param(
  [switch]$SkipTests,
  [switch]$SkipAnalyze
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  flutter pub get
  if (-not $SkipAnalyze) { flutter analyze }
  if (-not $SkipTests) { flutter test }
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build windows --release failed with exit code $LASTEXITCODE."
  }

  $release = Join-Path $root 'build\windows\x64\runner\Release'
  $hashFile = Join-Path $release 'SHA256SUMS.txt'
  Get-ChildItem -File $release |
    Get-FileHash -Algorithm SHA256 |
    ForEach-Object { '{0}  {1}' -f $_.Hash.ToLowerInvariant(), $_.Path.Substring($release.Length + 1) } |
    Set-Content -Path $hashFile -Encoding utf8

  Write-Host "Windows release: $release"
  Write-Host "SHA-256 manifest: $hashFile"
}
finally {
  Pop-Location
}
