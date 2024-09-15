# V2D Studio

Cool wip stuff, build it yourself to see what this does.

## Installation

> Installation can sometimes take up to 20min depending on your hardware. Please be patient with the installation process.

### MacOS

Installing v2d is hastle free via [Homebrew](https://brew.sh) + my own repo

```sh
brew tap chiissu/macchiato & brew install v2d
```

### Linux

It is very possible to get this up and running on Linux. Since I cannot maintain a repository you'll have to do two things yourself:

1. Build and install [libmediapipe](https://github.com/froxcey/libmediapipe)
2. Build v2d

### Windows

This project theoretically could work on Windows, but the upstream software, mediapipe, does not support hardware accelerated detection on Windows. Also, I don't have access to a Windows machine. There is no plan to provide official Windows support until dependency requirements are met.

## Running

Before you can do anything, you'll need to add your own asset `main.png` in `assets/img/`

After finishing configurating, you can run `v2d` in the terminal to run the app.

If you have any general question regarding the usage of v2d, feel free to contact [@froxcey](https://github.com/froxcey)

## Related software

You're welcome to add projects here, as long as it is primarily written in a [tier B language or above](https://github.com/Froxcey/Froxcey/blob/main/lang_tier.md) and source available. We encourage users to check out alternatives and choose what is the best for their own use case.

## Future plan

It would be cool to add WebRTP video streaming support

## Copyright & Usage Guideline

This software is not fully FOSS, please read [this usage guideline](./src/utils/guideline.txt).

IMPORTANT COPY-LEFT NOTICE: By distributing modifications or derivative works, a perpetual, worldwide, non-exclusive, royalty-free license is granted to the original author to incorporate these modifications into the original software or any future versions.
