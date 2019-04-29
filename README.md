# SonicAsteroids sound engine

A sound engine for macOS, written in Swift 4.2, for the [Elixoids v3 game engine](https://github.com/devstopfix/elixoids). No longer compatible with the v1 branch sound stream!

## Getting started
To install dependencies you will need [Carthage](https://github.com/Carthage/Carthage) (this can be installed using homebrew.)

SonicAsteroids has been tested on Xcode 7.3.1 on OS X 10.11 (El Capitan) and Xcode 10.1 on 10.13.6 (High Sierra).

## Build

    brew install carthage

    carthage update


### Sound Client Protocol

Sound events can be received at `ws://example.com/0/sound` as described in the [sound protocol document](https://github.com/devstopfix/elixoids/blob/master/docs/sound_protocol.md). For maximum network efficiency we recommend sending an `Accept: application/octet-stream` header and consuming [protobufs](https://github.com/devstopfix/elixoids/blob/master/priv/proto/sound.proto).

The pan is a float from -1 to +1 where -1 is hard left and zero is center. See the [pan property](https://developer.apple.com/documentation/avfoundation/avaudioplayer/1390884-pan).  We apply a function `y=x³` to the linear pan sent by the game to keep most sounds centered but push out sounds at the very edge of the screen.
