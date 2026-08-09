# My Torrent

Cliente desktop de torrents para Windows, com suporte a magnet links, arquivos `.torrent` locais e URLs HTTP(S) para arquivos `.torrent`.

## Desenvolvimento

```powershell
flutter pub get
flutter run -d windows
flutter test
flutter build windows --release
dart run msix:create
```

O aplicativo usa `libtorrent_flutter`, licenciado sob GPL-3.0. Distribuições do aplicativo precisam permanecer compatíveis com essa licença.

## Empacotamento

O workflow `.github/workflows/windows-msix.yml` valida formato, análise e testes, compila a versão Windows e publica o instalador `.msix` como artefato. O MSIX declara o protocolo `magnet` e a extensão `.torrent`.

## Certificado de desenvolvimento

O script `tool/create_dev_certificate.ps1` cria um certificado autoassinado para testes locais, válido por 20 anos, e exporta o PFX sem versionar a chave privada ou senha. O workflow assina o MSIX automaticamente quando os segredos `MSIX_CERTIFICATE_BASE64` e `MSIX_CERTIFICATE_PASSWORD` estão configurados; sem eles, gera um certificado de desenvolvimento automaticamente.

O script `tool/install_dev_certificate.ps1` precisa ser executado como administrador para registrar a chave pública em `LocalMachine\TrustedPeople`, requisito para instalar localmente um MSIX assinado por certificado de desenvolvimento.
