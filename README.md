# diceroll

[![Odin](https://img.shields.io/badge/Odin-v2026--02-blue?logo=odin&logoColor=white)](https://odin-lang.org)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Linux](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?logo=linux&logoColor=white)](https://github.com/xDarkicex/dice-roll/actions)
[![Build](https://github.com/xDarkicex/dice-roll/actions/workflows/build.yml/badge.svg)](https://github.com/xDarkicex/dice-roll/actions)

A Unix dice roller for tabletop use. Rolls N dice with M sides using a cryptographically secure PRNG.

## Install

### macOS — Homebrew (recommended)

```sh
brew tap xDarkicex/diceroll
brew install diceroll
```

### macOS — Tarball

```sh
curl -sL https://github.com/xDarkicex/dice-roll/releases/latest/download/diceroll-apple-darwin.tar.gz | tar -xz
chmod +x diceroll
./diceroll roll d20
```

### Linux — Tarball

```sh
curl -sL https://github.com/xDarkicex/dice-roll/releases/latest/download/diceroll-unknown-linux.tar.gz | tar -xz
chmod +x diceroll
./diceroll roll d20
```

### Build from source

```sh
odin build . -file -out:diceroll
```

## Usage

```
diceroll roll <spec> [count] [--json]
```

**`<spec>`** accepts any `XdY` notation (e.g., `d20`, `3d6`, `2D8`) or a plain sides count (`20`). Case-insensitive.

| Example | Meaning |
|---------|---------|
| `diceroll roll d20` | Roll 1d20 |
| `diceroll roll 3d6` | Roll 3 six-sided dice |
| `diceroll roll d8 4` | Roll 4d8, overriding count in spec |
| `diceroll roll d20 --json` | JSON output |

## Output

**Text (default):**
```
3d6: [5, 1, 2] → 8
```

**JSON (`--json`):**
```json
{"count":3,"sides":6,"rolls":[5,1,2],"sum":8}
```

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Usage error (missing spec, unknown subcommand) |
| `2` | Invalid dice spec |
| `3` | Count out of range (>10000) |

## Supported dice

All standard D&D dice: d4, d6, d8, d10, d12, d20, d100.
Any die from 1–65535 sides is valid. Up to 10,000 dice per roll.

## Building

```sh
make build
```

## Testing

```sh
make test
```