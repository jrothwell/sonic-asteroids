# SonicAsteroids sound engine

A sound engine for macOS, written in Swift 2.2, for the [Elixoids](https://github.com/devstopfix/elixoids) game engine.

## Getting started
To install dependencies you will need [Carthage](https://github.com/Carthage/Carthage) (this can be installed using homebrew.)

SonicAsteroids has only been tested on Xcode 7.3.1 on OS X 10.11 (El Capitan.)

## Known issues
* If a renderer is not running, there is a good chance the app will crash under the weight of trying to process explosions. This is because explosions are only cleared from the game state when they are served to a renderer.
* Similarly, there is a known problems where explosions sometimes won't generate a sound. This is because there is a possibility it will be served to the renderer before it gets served to the sound engine.

# Build

    brew install carthage
    
    carthage update

    