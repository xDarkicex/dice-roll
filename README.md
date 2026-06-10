# diceroll

> Cryptographically secure dice rolling for D&D, tabletop RPGs, and any game that needs real randomness.

[![Odin](https://img.shields.io/badge/Odin-dev--2026--05-blue?logo=odin&logoColor=white)](https://odin-lang.org)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Linux](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?logo=linux&logoColor=white)](https://github.com/xDarkicex/dice-roll/actions)
[![Build](https://github.com/xDarkicex/dice-roll/actions/workflows/release.yml/badge.svg)](https://github.com/xDarkicex/dice-roll/actions/workflows/release.yml)

## Why diceroll?

- **Truly random** — uses the OS CSPRNG (`arc4random_uniform` on macOS, `getrandom` on Linux). Not `rand()`.
- **Script-friendly** — `--json` output for piping into shell scripts, bots, or automation.
- **Full mechanics** — modifiers, advantage/disadvantage, keep/drop, exploding dice, rerolls, target counting, Fudge dice.
- **Zero dependencies** — single static binary, no runtime needed.
- **Fast** — arena-based memory, O(1) parsing, zero heap allocations after startup.
- **Tested** — 52 tests with enforced ≥90% line coverage.
- **Usable as a library** — import `dice` into your own Odin projects.

## Install

### macOS — Homebrew (recommended)

```sh
brew tap xDarkicex/diceroll
brew install diceroll
```

### Linux — Tarball

```sh
curl -sL https://github.com/xDarkicex/dice-roll/releases/latest/download/diceroll-unknown-linux.tar.gz | tar -xz
chmod +x diceroll
./diceroll roll d20
```

### macOS — Tarball

```sh
curl -sL https://github.com/xDarkicex/dice-roll/releases/latest/download/diceroll-apple-darwin.tar.gz | tar -xz
chmod +x diceroll
./diceroll roll d20
```

### Build from source

```sh
odin build . -file -out:diceroll
```

## CLI Usage

```
diceroll roll <spec> [count] [--adv|--disadv] [--json]
```

### Dice notation

`<spec>` accepts a rich dice expression:

| Example | Meaning |
|---|---|
| `d20` | Roll 1d20 |
| `3d6` | Roll 3 six-sided dice |
| `d20+5` | Roll 1d20, add 5 |
| `3d6-2` | Roll 3d6, subtract 2 |
| `4d6k3` | Roll 4d6, keep highest 3 |
| `4d6d1` | Roll 4d6, drop lowest 1 |
| `3d6!` | Exploding dice (reroll on max) |
| `2d20r1` | Reroll any 1s once |
| `5d10t8` | Count successes ≥ 8 (dice pool) |
| `4dF` | Fudge/Fate dice (-1, 0, +1) |
| `3d6!+2` | Exploding with modifier |

### Flags

| Flag | Description |
|---|---|
| `[count]` | Override number of dice |
| `--adv`, `--advantage` | Roll with advantage (take highest) |
| `--disadv`, `--disadvantage` | Roll with disadvantage (take lowest) |
| `--json`, `-j` | JSON output |

### Examples

```sh
# Basic roll
diceroll roll d20

# D&D attack roll with +7
diceroll roll d20+7

# D&D stat generation (4d6 drop lowest)
diceroll roll 4d6d1

# Exploding fireball: 8d6
diceroll roll 8d6!

# Greatsword with reroll 1s
diceroll roll 2d6r1+5

# Stealth check with advantage
diceroll roll d20+5 --adv

# Dice pool: 6d10, threshold 8
diceroll roll 6d10t8

# Roll 4d8 overriding spec count
diceroll roll d8 4
```

## Output

**Text (default):**
```
3d6: [5, 1, 2] → 8
1d20+5: [12] → 12 + 5 = 17
4d6k3: [6, 4, 3, 1] → 13
5d10t8: [9, 2, 8, 6, 10] → 3 successes
4dF: [1, 0, -1, 1] → 1
```

**JSON (`--json`):**
```json
{"count":3,"sides":6,"rolls":[5,1,2],"sum":8,"total":8}
{"count":1,"sides":20,"modifier":5,"rolls":[12],"sum":12,"total":17}
{"count":4,"sides":6,"keep_mode":"highest","keep_count":3,"rolls":[6,4,3,1],"sum":13,"total":13}
```

## Library usage

Import the `dice` package into your own Odin project:

```go
import dice "./dice"

main :: proc() {
    spec, err := dice.parse_spec("d20+5")
    if err != nil { return }

    spec.advantage = .Advantage  // optional: set roll mode

    results: [dice.MAX_DICE]int
    result, roll_err := dice.roll(results[:], spec)
    if roll_err != nil { return }

    // result.count  — number of dice shown
    // result.sum    — sum of kept dice (before modifier)
    // result.total  — sum + modifier

    fmt.println(result.total)
}
```

Key types:

- `RollSpec` — describes what to roll (count, sides, modifier, advantage, keep mode, exploding, reroll, target)
- `RollResult` — result of a roll (count, sum, total)
- `Error` — parse or roll errors

Key procs:

| Proc | Description |
|---|---|
| `parse_spec(string) -> (RollSpec, Error)` | Parse a dice expression |
| `roll([]int, RollSpec) -> (RollResult, Error)` | Execute a roll into caller's buffer |
| `format_text(arena, results, result, spec) -> string` | Human-readable output |
| `format_json(arena, results, result, spec) -> string` | JSON output |

## Supported dice

All standard D&D dice: d4, d6, d8, d10, d12, d20, d100.
Any die from 1–65535 sides is valid. Up to 10,000 dice per roll.

## Exit codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Usage error (missing spec, unknown subcommand) |
| `2` | Invalid dice spec |
| `3` | Count out of range (>10000) |

## Building

```sh
make build
```

## Testing

```sh
make test
```
