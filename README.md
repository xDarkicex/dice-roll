# diceroll

> Cryptographically secure dice rolling for tabletop RPGs — D&D, World of Darkness, Savage Worlds, Fate, Shadowrun, and more.

[![Odin](https://img.shields.io/badge/Odin-dev--2026--05-blue?logo=odin&logoColor=white)](https://odin-lang.org)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Linux](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue?logo=linux&logoColor=white)](https://github.com/xDarkicex/dice-roll/actions)
[![Build](https://github.com/xDarkicex/dice-roll/actions/workflows/release.yml/badge.svg)](https://github.com/xDarkicex/dice-roll/actions/workflows/release.yml)

## Why diceroll?

- **Truly random** — uses the OS CSPRNG (`arc4random_uniform` on macOS, `getrandom` on Linux). Not `rand()`.
- **Script-friendly** — `--json` output for piping into shell scripts, bots, or automation.
- **System-agnostic** — first-class support for D&D, World of Darkness, Savage Worlds, Fate, dice pools, and more. Every mechanic is opt-in; use only what your table needs.
- **Zero dependencies** — single static binary, no runtime needed.
- **Fast** — arena-based memory, O(1) parsing, zero heap allocations after startup.
- **Tested** — 68 tests with enforced ≥90% line coverage.
- **Usable as a library** — import the `dice` package into your own Odin projects.

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
diceroll roll <spec> [count] [flags]
```

### Dice notation

`<spec>` accepts a rich dice expression:

| Example | Meaning |
|---|---|
| `d20` | Roll 1d20 |
| `3d6` | Roll 3 six-sided dice |
| `d20+5`, `3d6-2` | Modifier |
| `4d6k3` | Keep highest 3 |
| `4d6d1` | Drop lowest 1 |
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
| `--wild <sides>` | Savage Worlds: extra wild die (e.g. `--wild 6`) |
| `--cancel <val>` | WoD: die value that cancels a success (e.g. `--cancel 1`) |
| `--tn <n>` | Target number for raise counting |
| `--raise-step <n>` | Increment per raise (e.g. `--raise-step 4`) |
| `--json`, `-j` | JSON output |

### Recipes by system

**D&D / d20**
```sh
diceroll roll d20+7                      # attack roll
diceroll roll d20+5 --adv                # with advantage
diceroll roll 4d6d1                      # stat generation
diceroll roll 8d6!                       # exploding fireball
diceroll roll 2d6r1+5                    # greatsword, reroll 1s
```

**World of Darkness**
```sh
diceroll roll 6d10t8 --cancel 1          # 6-die pool, 8+ success, 1s cancel
diceroll roll 8d10t8 --cancel 1 --json   # scriptable pool check
```

**Savage Worlds**
```sh
diceroll roll d8 --wild 6                # trait roll with wild die
diceroll roll d8 --wild 6 --tn 4 --raise-step 4  # with raise counting
```

**Shadowrun / dice pool**
```sh
diceroll roll 10d6t5                     # 10-die pool, 5+ = success
diceroll roll 12d6t5!                    # with exploding 6s
```

**Fate / Fudge**
```sh
diceroll roll 4dF                        # standard Fate check
```

## Output

**Text (default):**
```
3d6: [5, 1, 2] → 8
1d20+5: [12] → 12 + 5 = 17
4d6k3: [6, 4, 3, 1] → 13
5d10t8c1: [9, 1, 8, 6, 10] → 3 successes
1d8w6: [8, 1] → 8 (1 raise)
4dF: [1, 0, -1, 1] → 1
```

**JSON (`--json`):**
```json
{"count":3,"sides":6,"rolls":[5,1,2],"sum":8,"total":8}
{"count":1,"sides":20,"modifier":5,"rolls":[12],"sum":12,"total":17}
{"count":4,"sides":6,"keep_mode":"highest","keep_count":3,"rolls":[6,4,3,1],"sum":13,"total":13}
{"count":5,"sides":10,"target":8,"successes":3,"cancel_val":1,"rolls":[9,1,8,6,10],"sum":3,"total":3}
```

## Library usage

Import the `dice` package into your own Odin project:

```go
import dice "./dice"

main :: proc() {
    // Parse any dice expression
    spec, err := dice.parse_spec("d20+5")
    if err != nil { return }

    // Set optional mechanics (all default to off)
    spec.advantage  = .Advantage   // D&D: advantage
    spec.wild_sides = 6            // Savage Worlds: wild die
    spec.cancel_val = 1            // WoD: 1s cancel successes
    spec.tn         = 4            // Savage Worlds: target number
    spec.raise_step = 4            // Savage Worlds: raise increment

    // Roll into caller-provided buffer
    results: [dice.MAX_DICE]int
    result, roll_err := dice.roll(results[:], spec)
    if roll_err != nil { return }

    // result.count  — number of dice shown
    // result.sum    — sum of kept dice (before modifier)
    // result.total  — sum + modifier
    // result.raises — number of raises (if raise_step > 0 and tn > 0)

    fmt.println(result.total)
}
```

**Compound expressions** for multi-group rolls:

```go
specs: [8]dice.RollSpec
count, modifier, err := dice.parse_compound(specs[:], "2d6+1d8+5")
// specs[0] = {2, 6}, specs[1] = {1, 8}, modifier = 5

// Or use the convenience wrapper:
result, err := dice.roll_compound(results[:], "1d6+1d4")
```

Key types:

| Type | Description |
|---|---|
| `RollSpec` | Describes what to roll (count, sides, modifier, advantage, keep mode, exploding, reroll, target, cancel, wild die, raises) |
| `RollResult` | Result of a roll (count, sum, total, raises) |
| `Error` | Parse or roll errors |

Key procs:

| Proc | Description |
|---|---|
| `parse_spec(string) -> (RollSpec, Error)` | Parse a dice expression |
| `parse_compound(specs, string) -> (count, modifier, Error)` | Parse multi-group like `2d6+1d8+5` |
| `roll([]int, RollSpec) -> (RollResult, Error)` | Execute a roll into caller's buffer |
| `roll_compound([]int, string) -> (RollResult, Error)` | Parse and roll a compound expression |
| `format_text(arena, results, result, spec) -> string` | Human-readable output |
| `format_json(arena, results, result, spec) -> string` | JSON output |

## Supported dice

All standard RPG dice: d4, d6, d8, d10, d12, d20, d100.
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
