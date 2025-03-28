# Intensity

Intensity is a post-quantum end-to-end-encrypted chat server, and client for quick fire temporary chat rooms.

## FAQ

- I found bug, xyz, what do I do?
  - Create an issue on this GitHub repository and include a screenshot of any logs applicable to the crash.

## Build Instructions
> **Notice:** Zap is not compatible with Windows, your best bet would be [WSL](https://learn.microsoft.com/en-us/windows/wsl/install).

We use the as of writing this stable version of [Zig](https://ziglang.org/), v14. We also rely on [zigzap/zig](https://github.com/zigzap/zap) but Zig should automagically handle that!

`zig build -Doptimize=ReleaseSafe`

## Source Conditions

This project is licensed under the [GNU AGPLv3](./LICENSE) license. The website's favicon (specifically this [file](./public/favicon.ico)) is licensed under the MIT license.