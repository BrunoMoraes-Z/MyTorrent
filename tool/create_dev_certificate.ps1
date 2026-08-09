[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\certificates'),
    [switch]$Replace
)

$ErrorActionPreference = 'Stop'
$subject = 'CN=My Torrent'
$expiresAt = (Get-Date).AddYears(20)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$certificate = Get-ChildItem Cert:\CurrentUser\My |
    Where-Object {
        $_.Subject -eq $subject -and
        $_.HasPrivateKey -and
        $_.NotAfter -gt (Get-Date).AddYears(19)
    } |
    Select-Object -First 1

if ($Replace -and $null -ne $certificate) {
    Remove-Item $certificate.PSPath
    $certificate = $null
}

if ($null -eq $certificate) {
    $certificate = New-SelfSignedCertificate `
        -Type Custom `
        -Subject $subject `
        -FriendlyName 'My Torrent Development MSIX' `
        -KeyUsage DigitalSignature `
        -KeyExportPolicy Exportable `
        -KeySpec Signature `
        -HashAlgorithm SHA256 `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -NotAfter $expiresAt `
        -TextExtension @(
            '2.5.29.19={critical}{text}CA=FALSE',
            '2.5.29.37={text}1.3.6.1.5.5.7.3.3'
        )
}

$cerPath = Join-Path $OutputDirectory 'my-torrent-dev.cer'
Export-Certificate -Cert $certificate -FilePath $cerPath -Type CERT | Out-Null

Write-Host "Development certificate created in CurrentUser\My and exported to $cerPath."
