# Farside for macOS

An English-first, native macOS client for streaming from Sunshine, Foundation Sunshine, and compatible GameStream hosts.

Farside is an independent community fork of [Moonlight macOS Enhanced](https://github.com/skyhua0224/moonlight-macos-enhanced). It focuses on a polished Mac experience: Apple Silicon support, reliable local-network discovery, clear diagnostics, and controls that feel at home on macOS.

> Farside is not affiliated with the Moonlight project, NVIDIA, Sunshine, or Foundation Sunshine.

## What this fork changes

- English-first interface, including stream controls, error states, and diagnostics
- Separate app identity: it installs as **Farside** and does not replace regular Moonlight
- macOS 15+ local-network and Bonjour declarations for reliable LAN discovery
- Isolated pairing credentials so the enhanced build can coexist with regular Moonlight
- Paired-client identity used consistently for launch, resume, and quit requests
- Native controls for display mode, resolution, frame rate, bitrate, audio, connection routing, and logs

## Install

Download a release from this repository’s [Releases](../../releases) page once available.

Because personal development builds are not notarized by Apple, macOS may ask for confirmation the first time you open the app. Use Finder’s **Open** command for the app, then confirm once. Regular Moonlight is left unchanged.

## Connect a host

1. Install and configure Sunshine or Foundation Sunshine on the host computer.
2. Open Farside and add the host, or wait for local-network discovery.
3. Pair using the displayed PIN.
4. Launch Desktop or an app.

If the client shows **Permission denied** after the host is online and paired, the host has rejected the stream launch. Check the host’s client authorization and service permissions; this is not a macOS local-network permission problem.

## Build from source

### Requirements

- macOS on Apple Silicon or Intel
- Xcode 16 or newer
- Git with submodule support

### Build

```bash
git clone --recursive https://github.com/farazfarid/moonlight-macos-enhanced.git
cd moonlight-macos-enhanced
open Moonlight.xcodeproj
```

Choose the **Moonlight for macOS** scheme and run it. If Xcode reports missing `FFmpeg.xcframework`, `Opus.xcframework`, or `SDL2.xcframework`, fetch the project’s documented Apple XCFramework dependency bundle before building.

For a personal build, select your Apple Development Team in Xcode if you want development signing. It is not required for local network discovery or for a host to authorize a stream.

## Project direction

This fork is maintained by Faraz Farid. The next priorities are:

- complete English localization throughout the app
- Mac-native host cards, settings, and streaming controls
- robust keyboard, mouse, and controller behavior
- clear host-permission troubleshooting for Sunshine variants
- reproducible Apple Silicon release builds and automated checks

Feature requests and bug reports are welcome in [Issues](../../issues). Please include your macOS version, Mac chip, host software/version, and a sanitized log where possible.

## Contributing

Keep changes focused, use clear commit messages, and test on the target macOS architecture. Please do not include certificates, pairing keys, access tokens, or host credentials in commits or issues.

## License and attribution

This project is distributed under the [GNU General Public License v3.0](LICENSE.txt). The license, upstream notices, and contributor attribution remain intact. See the Git history for the full provenance of this fork and its upstream projects.
