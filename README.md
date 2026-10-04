# aerospace (fork)

my fork of [aerospace](https://github.com/nikitabobko/AeroSpace). see the original repo for docs and the full readme.

native macos tabs (ghostty, finder, ...) are separate windows under the hood, so aerospace tiled every tab on its own. a new tab split the layout, and moving a window to another workspace left its other tabs behind. upstream tracks this in [#68](https://github.com/nikitabobko/AeroSpace/issues/68).

this fork treats a whole tab group as one tile.

### install

there is no prebuilt release, it builds from source. needs xcode.

1. `brew install swiftly bash ruby@3.4 rustup fish`, then `swiftly init` and `rustup default stable`
2. create a code signing certificate in keychain access: certificate assistant → create a certificate, name `aerospace-codesign-certificate`, identity type `self-signed root`, certificate type `code signing`
3. build and install:

```sh
git clone https://github.com/AryehSchoefer/AeroSpace && cd AeroSpace
. ~/.swiftly/env.sh && swiftly install
export PATH="/opt/homebrew/opt/ruby@3.4/bin:/opt/homebrew/opt/rustup/bin:/opt/homebrew/bin:$PATH"
./install-from-sources.sh
open -a AeroSpace
```

`install-from-sources.sh` uninstalls the homebrew `aerospace` cask and installs this fork as `aerospace-dev`. your `~/.aerospace.toml` stays. grant accessibility when macos asks.

uninstall with `brew uninstall --cask aerospace-dev`.

### update

with the same `PATH` as above:

```sh
git pull && ./install-from-sources.sh
```

### sync with upstream

```sh
git remote add upstream https://github.com/nikitabobko/AeroSpace
git fetch upstream && git merge upstream/main
```

### development

```sh
./build-debug.sh   # binaries in .debug/
./run-debug.sh     # run without installing
./test.sh          # build, tests, lint
```
