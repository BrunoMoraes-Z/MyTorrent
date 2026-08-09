[CmdletBinding()]
param(
    [string]$CertificatePath = (Join-Path $PSScriptRoot '..\certificates\torrent-desk-dev.cer')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $CertificatePath)) {
    throw "Certificate not found: $CertificatePath"
}

Get-ChildItem Cert:\LocalMachine\TrustedPeople |
    Where-Object { $_.Subject -eq 'CN=My Torrent' } |
    Remove-Item
Import-Certificate -FilePath $CertificatePath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null
Write-Host 'Certificate installed in LocalMachine\TrustedPeople.'
