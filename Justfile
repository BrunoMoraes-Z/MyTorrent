set shell := ["pwsh", "-NoLogo", "-NoProfile", "-Command"]

default: msix

certificate:
    $ErrorActionPreference = 'Stop'; & .\tool\create_dev_certificate.ps1

quality:
    $ErrorActionPreference = 'Stop'; dart format --output=none --set-exit-if-changed lib test; flutter analyze; flutter test; flutter build windows --release

msix: quality certificate
    $ErrorActionPreference = 'Stop'; $certificate = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -eq 'CN=My Torrent' -and $_.HasPrivateKey -and $_.NotAfter -gt (Get-Date) } | Sort-Object NotAfter -Descending | Select-Object -First 1; if ($null -eq $certificate) { throw 'Certificado de desenvolvimento não encontrado em CurrentUser\My. Execute just certificate primeiro.' }; dart run msix:create --build-windows false --sign-msix true --install-certificate false --signtool-options "/v /fd SHA256 /td SHA256 /tr http://timestamp.digicert.com /sha1 $($certificate.Thumbprint)"
