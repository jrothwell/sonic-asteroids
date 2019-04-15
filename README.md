# SonicAsteroids sound engine

A sound engine for macOS, written in Swift 4.2, for the [Elixoids v3](https://github.com/devstopfix/elixoids) game engine. No longer compatible with the v1 sound stream!

## Getting started
To install dependencies you will need [Carthage](https://github.com/Carthage/Carthage) (this can be installed using homebrew.)

SonicAsteroids has been tested on Xcode 7.3.1 on OS X 10.11 (El Capitan) and Xcode 10.1 on 10.13.6 (High Sierra).

## Build

    brew install carthage
    
    carthage update


### Sound Client Protocol

Sound events can be received at `ws://example.com/sound` and are a JSON list of maps:

```json
[
  {"snd": "x", "pan": -0.8, "gt": 83802},
  {"snd": "f", "pan":  0.2, "gt": 84010}
]
...
```

The sound types are:

* `x` : explosion
* `f` : shot fired

The pan is a float from -1 to +1 where -1 is hard left and zero is center. See the [pan property](https://developer.apple.com/documentation/avfoundation/avaudioplayer/1390884-pan)

* `gt` is the game time in milliseconds and can be used for ordering or delaying events
