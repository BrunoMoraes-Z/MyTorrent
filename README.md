# My Torrent

A compact Windows torrent client with support for magnet links, local `.torrent` files, and HTTP(S) torrent URLs.

## 🚀 Development

```powershell
flutter pub get
flutter run -d windows
flutter test
```

Create a locally signed Windows package with:

```powershell
just msix
```

This command checks formatting, runs analysis and tests, builds the Windows app, and produces an MSIX signed with the local development certificate.

## 📦 Installation

GitHub Releases include the MSIX installer and its matching `my-torrent-dev.cer` certificate. Before installing a release, open an elevated PowerShell session and trust that release certificate:

```powershell
Import-Certificate -FilePath .\my-torrent-dev.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

Then install the `.msix` file. Import the certificate from each new release before updating an existing installation.

## 🏷️ Releases

Push a tag in the format `vMAJOR.MINOR.PATCH`, such as `v1.0.2`, to create a GitHub Release. Update `pubspec.yaml` first so its version matches the tag, for example `1.0.2+1`.

The GitHub workflow creates a new self-signed `CN=My Torrent` certificate valid for 20 years, signs the MSIX, verifies it, and publishes both the installer and public certificate. No PFX file, password, secret, or environment variable is required.

## ℹ️ Notes

The MSIX package registers the `magnet` protocol and `.torrent` file extension. The application uses `libtorrent_flutter` and is distributed under GPL-3.0-compatible terms.
