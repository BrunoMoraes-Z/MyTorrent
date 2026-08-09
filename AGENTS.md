# My Torrent Development Rules

## Scope

- Target platform is Windows desktop. Keep platform-specific code isolated in `windows/` or desktop services.
- The BitTorrent engine is `libtorrent_flutter`. Do not replace it with a pure Dart implementation.
- `libtorrent_flutter` is GPL-3.0. Distribution and source publication must remain GPL-compatible.

## Layout and UI

- Use `shadcn_ui` for visual controls: buttons, dialogs, inputs, checkboxes, switches and theming.
- Do not introduce Material visual widgets such as `MaterialApp`, `Scaffold`, `AppBar`, `FloatingActionButton`, `AlertDialog` or `LinearProgressIndicator`.
- Standard Flutter layout primitives (`Row`, `Column`, `Expanded`, `Padding`, `Container`) are allowed for composition only.
- Preserve the compact dark ShadCN visual language documented in `my_torrent.pen`: zinc surfaces, thin borders, lime accent (`#D6FF4D`), no excessive spacing.
- Implement new visual flows in Pencil before implementing them in Flutter. Keep major screens as top-level frames and validate their screenshots.

## Torrent Flow

- Accept magnets, local `.torrent` files and HTTP(S) URLs to `.torrent` files only.
- Resolve source URLs with a finite timeout and always provide a cancellation path after a torrent handle is created.
- Always prepare torrents with `streamOnly: true`, wait for metadata, preselect every file, then call `setFilePriorities` only after user confirmation.
- Never silently delete payload files. Removal UI must explicitly choose between retaining and deleting files.
- Closing the window hides it to the Windows tray. Only the tray `Encerrar` command exits the process.

## State and Persistence

- Keep engine access behind `TorrentService`; widgets must not call `LibtorrentFlutter` directly.
- Persist settings with atomic file replacement. A per-download directory is not a new global default.
- Validate directory existence and numeric settings before saving them.

## Quality

- Add focused unit tests for every parser, model, persistence, timeout and priority-mapping change.
- Run `dart format lib test`, `flutter analyze`, `flutter test` and `flutter build windows --release` before handing off changes.
- Never commit generated build directories, private certificates, package signing passwords or downloaded torrent files.

## Packaging

- Keep the custom icon in `assets/icons/app_icon.png` and regenerate `windows/runner/resources/app_icon.ico` when branding changes.
- Register `.torrent` and `magnet` in `msix_config`. Activation input is untrusted and must be parsed before use.
- The CI workflow must produce an MSIX artifact and run quality checks on `windows-latest`.
