# V2D Studio

[English](./README.md)｜[繁體中文](./README-zh.md)

Animate an image into a virtual avatar using your webcam. This is especially useful for those who don't have a 3D avatar but wants to start VTubing.

V2D Studio is written in Zig using [Mach](https://machengine.org/) and [Mediapipe](https://ai.google.dev/edge/mediapipe).

## Installation

> Building can sometimes take up to 20min depending on your hardware. Please trust the process.

### MacOS

Installing v2d is hastle free via [Homebrew](https://brew.sh) + my own repo

```sh
brew tap chiissu/macchiato & brew install v2d
```

### Linux

It is very possible to get this up and running on Linux. Since I cannot maintain a Linux repository, you'll have to do two things yourself:

> Note that I haven't ported libmediapipe build script to Linux, but it is very much possible and is planned to be done soon

1. Build and install [libmediapipe](https://github.com/froxcey/libmediapipe)
2. Build v2d

### Windows

Since Mediapipe doesn't support hardware acceleration on Windows and I don't have access to a Windows machine, there is no plan to support Windows in the foreseeable future.

## Running

> Since we are rewriting the UI and config system, you need to put the image you want to animate in `./assets/img/main.png`. This temporary workaround will be removed in a future version.

Just open a terminal and run `v2d`

## Support

If you need help, [contact Frox](https://frox.tw/contacts)

## Related software

You're welcome to add projects here, as long as it is primarily written in a [tier B language or above](https://github.com/Froxcey/Froxcey/blob/main/lang_tier.md) and source available. We encourage users to check out alternatives and choose what is the best for their own use case.

## Future plans

- [ ] Proper UI and config system
- [ ] WebRTP remote support
- [ ] Parallax effect
- [ ] Special effects and shaders
- [ ] Plug-in system (longer term)

## Copyright & Usage Guideline

© 2024 Chiissu Team

As long as you are using this for personal studio and with proper attribute, we don't really mind what you're doing.
