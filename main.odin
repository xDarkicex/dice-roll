package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import dice "./dice"

ArgsError :: enum {
	None,
	Invalid_Subcommand,
	Missing_Spec,
	Invalid_Count,
	Invalid_Spec,
}

Exit :: enum int {
	Success         = 0,
	Usage_Error     = 1,
	Invalid_Spec    = 2,
	Count_Out_Range = 3,
}

CLIArgs :: struct {
	spec:     dice.RollSpec,
	is_json:  bool,
}

parse_args :: proc(argv: []string) -> (args: CLIArgs, err: ArgsError) {
	if len(argv) < 1 {
		return {}, ArgsError.Missing_Spec
	}

	if argv[0] != "roll" {
		return {}, ArgsError.Invalid_Subcommand
	}

	if len(argv) < 2 {
		return {}, ArgsError.Missing_Spec
	}

	spec, parse_err := dice.parse_spec(argv[1])
	if parse_err != nil {
		return {}, ArgsError.Invalid_Spec
	}
	args.spec = spec

	// Parse optional flags: [count] [--adv|--disadv] [--json]
	i := 2
	for i < len(argv) {
		arg := argv[i]
		if arg == "--json" || arg == "-j" {
			args.is_json = true
			i += 1
		} else if arg == "--adv" || arg == "--advantage" {
			args.spec.advantage = .Advantage
			i += 1
		} else if arg == "--disadv" || arg == "--disadvantage" {
			args.spec.advantage = .Disadvantage
			i += 1
		} else {
			explicit := dice.parse_uint(arg)
			if explicit < 1 || explicit > dice.MAX_DICE {
				return {}, ArgsError.Invalid_Count
			}
			args.spec.count = explicit
			i += 1
		}
	}

	return args, ArgsError.None
}

print_usage :: proc() {
	fmt.fprintln(os.stderr, "usage: diceroll roll <spec> [count] [--adv|--disadv] [--json]")
	fmt.fprintln(os.stderr, "  spec   dice notation: d20, 3d6, d20+5, 4d6k3, 4d6d1, 3d6!, 5d10t8, 4dF")
	fmt.fprintln(os.stderr, "  count  override number of dice (default from spec)")
	fmt.fprintln(os.stderr, "  --adv, --advantage    roll with advantage (take highest)")
	fmt.fprintln(os.stderr, "  --disadv, --disadvantage  roll with disadvantage (take lowest)")
	fmt.fprintln(os.stderr, "  --json output JSON")
}

main :: proc() {
	backing: [8192]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])

	run(&arena, os.args[1:])
}

run :: proc(arena: ^mem.Arena, argv: []string) {
	args, parse_err := parse_args(argv)

	if parse_err != nil {
		print_usage()
		switch parse_err {
		case .Invalid_Subcommand:
			fmt.fprintln(os.stderr, "error: unknown command:", argv[0] if len(argv) > 0 else "")
		case .Missing_Spec:
			fmt.fprintln(os.stderr, "error: missing dice spec")
		case .Invalid_Count:
			fmt.fprintln(os.stderr, "error: count must be 1-", dice.MAX_DICE)
		case .Invalid_Spec:
			fmt.fprintln(os.stderr, "error: invalid dice spec")
		case .None:
		}
		ec := Exit.Usage_Error
		switch parse_err {
		case .Invalid_Count:
			ec = Exit.Count_Out_Range
		case .Invalid_Spec:
			ec = Exit.Invalid_Spec
		case .None, .Invalid_Subcommand, .Missing_Spec:
			ec = Exit.Usage_Error
		}
		os.exit(int(ec))
	}

	results: [dice.MAX_DICE]int

	result, roll_err := dice.roll(results[:], args.spec)
	if roll_err != nil {
		fmt.fprintln(os.stderr, "error: roll failed")
		os.exit(int(Exit.Invalid_Spec))
	}

	if args.is_json {
		json_out := dice.format_json(arena, results[:result.count], result, args.spec)
		fmt.println(json_out)
	} else {
		text_out := dice.format_text(arena, results[:result.count], result, args.spec)
		fmt.println(text_out)
	}
}
