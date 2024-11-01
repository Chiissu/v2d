# V2D Studio

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

Before you can do anything, you'll need to add your own asset `main.png` in `assets/img/`

After finishing configurating, you can run `v2d` in the terminal to run the app.

If you have any general question regarding the usage of v2d, feel free to contact [@froxcey](https://github.com/froxcey)

## Related software

You're welcome to add projects here, as long as it is primarily written in a [tier B language or above](https://github.com/Froxcey/Froxcey/blob/main/lang_tier.md) and source available. We encourage users to check out alternatives and choose what is the best for their own use case.

## Future plans

1. WebRTP remote support
2. Parallax
3. Special effects and shaders
4. Plug-in system (longer term)

## Copyright & Usage Guideline

This software is not fully FOSS, please read [this usage guideline](./src/utils/guideline.txt).

IMPORTANT COPY-LEFT NOTICE: By distributing modifications or derivative works, a perpetual, worldwide, non-exclusive, royalty-free license is granted to the original author to incorporate these modifications into the original software or any future versions.
