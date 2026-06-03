package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"

ArgParse :: struct {
	subcommand: string,
	count:      int,
	sides:      int,
	is_json:    bool,
}

ArgsError :: enum {
	None,
	Invalid_Subcommand,
	Missing_Spec,
	Invalid_Count,
	Invalid_Spec,
}

// Unix exit codes for diceroll
Exit :: enum int {
	Success        = 0,
	Usage_Error    = 1, // wrong args / usage
	Invalid_Spec   = 2, // malformed dice spec
	Count_Out_Range = 3,// count not in 1-10000
}

parse_args :: proc(argv: []string) -> (args: ArgParse, err: ArgsError) {
	if len(argv) < 1 {
		return {}, ArgsError.Missing_Spec
	}

	if argv[0] != "roll" {
		return {}, ArgsError.Invalid_Subcommand
	}

	if len(argv) < 2 {
		return {}, ArgsError.Missing_Spec
	}

	count, sides, parse_err := parse_dice_spec(argv[1])
	if parse_err != nil {
		return {}, ArgsError.Invalid_Spec
	}
	args.count = count
	args.sides = sides

	if len(argv) > 2 {
		if argv[2] == "--json" || argv[2] == "-j" {
			args.is_json = true
		} else {
			explicit := parse_uint(argv[2])
			if explicit < 1 || explicit > 10000 {
				return {}, ArgsError.Invalid_Count
			}
			args.count = explicit
		}
	}

	if len(argv) > 3 && !args.is_json {
		if argv[3] == "--json" || argv[3] == "-j" {
			args.is_json = true
		}
	}

	return args, ArgsError.None
}

print_usage :: proc() {
	fmt.fprintln(os.stderr, "usage: diceroll roll <spec> [count] [--json]")
	fmt.fprintln(os.stderr, "  spec   dice notation: d20, 3d6, 20")
	fmt.fprintln(os.stderr, "  count  override number of dice (default from spec)")
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
			fmt.fprintln(os.stderr, "error: unknown command:", args.subcommand)
		case .Missing_Spec:
			fmt.fprintln(os.stderr, "error: missing dice spec")
		case .Invalid_Count:
			fmt.fprintln(os.stderr, "error: count must be 1-10000")
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

	MAX_DICE :: 10000
	results: [MAX_DICE]int

	sum := roll_dice(results[:args.count], args.count, args.sides)

	if args.is_json {
		json_out := format_json(arena, results[:args.count], args.count, args.sides, sum)
		fmt.println(json_out)
	} else {
		text_out := format_text(arena, results[:args.count], args.count, args.sides, sum)
		fmt.println(text_out)
	}
}