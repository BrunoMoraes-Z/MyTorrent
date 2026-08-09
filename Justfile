set shell := ["pwsh", "-NoLogo", "-NoProfile", "-Command"]

default: msix

certificate:
    $ErrorActionPreference = 'Stop'; if ([string]::IsNullOrWhiteSpace($env:MSIX_CERTIFICATE_PASSWORD)) { throw 'Defina MSIX_CERTIFICATE_PASSWORD antes de criar o certificado.' }; $password = ConvertTo-SecureString $env:MSIX_CERTIFICATE_PASSWORD -AsPlainText -Force; & .\tool\create_dev_certificate.ps1 -Password $password

quality:
    $ErrorActionPreference = 'Stop'; dart format --output=none --set-exit-if-changed lib test; flutter analyze; flutter test; flutter build windows --release

msix: quality
    $ErrorActionPreference = 'Stop'; $certificatePath = Join-Path $PWD 'certificates\torrent-desk-dev.pfx'; if ([string]::IsNullOrWhiteSpace($env:MSIX_CERTIFICATE_PASSWORD)) { throw 'Defina MSIX_CERTIFICATE_PASSWORD antes de gerar o MSIX.' }; if (-not (Test-Path -LiteralPath $certificatePath -PathType Leaf)) { throw "Certificado não encontrado: $certificatePath. Execute just certificate primeiro." }; dart run msix:create --sign-msix true --install-certificate false --certificate-path $certificatePath --certificate-password $env:MSIX_CERTIFICATE_PASSWORD
