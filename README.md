> [!WARNING]
> This project is NOT yet in a functional state and is still being created. However, feel free to contribute if you have time!

# Intensity

Intensity is a post-quantum end-to-end-encrypted chat server, and client for quick fire temporary chat rooms.

## FAQ

- I found bug, xyz, what do I do?
  - Create an issue on this GitHub repository and include a screenshot of any logs applicable to the crash.
- What do you use for encryption?
  - Kyber1024-90s for the key exchange and AES256 for symmetric encryption.

## Build Instructions

> **Notice:** Zap is not compatible with Windows, your best bet would be [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

We use the as of writing this stable version of [Zig](https://ziglang.org/), v14. We also rely on [zigzap/zig](https://github.com/zigzap/zap) but Zig should automagically handle that!

`zig build -Doptimize=ReleaseSafe`

## Source Conditions

This project is licensed under the [European Union Public License (EUPL), version 1.2](./LICENSE) or later. The website's favicon (specifically this [file](./public/favicon.ico)) is licensed under the MIT license.
