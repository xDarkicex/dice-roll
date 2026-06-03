package main

import "core:fmt"
import "core:mem"
import "core:strings"

/*
ParseDie represents a parsed die specification.
*/
ParseDie :: struct {
	sides: int,
}

/*
parse_die parses a single die specifier like "d20" or "20".
Returns ParseDie{0} and an error for invalid input.
*/
parse_die :: proc(spec: string) -> (ParseDie, Error) {
	if len(spec) == 0 {
		return {}, Error.Invalid_Die_Spec
	}

	if spec[0] == 'd' || spec[0] == 'D' {
		sides := parse_uint(spec[1:])
		if sides < 1 || sides > 0xFFFF {
			return {}, Error.Invalid_Die_Spec
		}
		return ParseDie{sides}, nil
	}

	sides := parse_uint(spec)
	if sides < 1 || sides > 0xFFFF {
		return {}, Error.Invalid_Die_Spec
	}
	return ParseDie{sides}, nil
}

/*
parse_dice_spec parses a full dice expression: [count]d<sides>.
count is optional (defaults to 1). Accepts d20, 3d6, 3D6, 20.
Returns count=0 on error.
*/
parse_dice_spec :: proc(spec: string) -> (count: int, sides: int, err: Error) {
	if len(spec) == 0 {
		return 0, 0, Error.Invalid_Dice_Spec
	}

	has_d := -1
	for i := 0; i < len(spec); i += 1 {
		c := spec[i]
		if c == 'd' || c == 'D' {
			has_d = i
			break
		}
	}

	if has_d == -1 {
		sides_val := parse_uint(spec)
		if sides_val < 1 {
			return 0, 0, Error.Invalid_Dice_Spec
		}
		return 1, sides_val, nil
	}

	count_str := spec[:has_d]
	die_count := 1
	if len(count_str) > 0 {
		die_count = parse_uint(count_str)
		if die_count < 1 || die_count > 10000 {
			return 0, 0, Error.Too_Many_Dice
		}
	}

	sides_str := spec[has_d+1:]
	if len(sides_str) == 0 {
		return 0, 0, Error.Invalid_Dice_Spec
	}
	die_sides := parse_uint(sides_str)
	if die_sides < 1 || die_sides > 0xFFFF {
		return 0, 0, Error.Invalid_Die_Spec
	}

	return die_count, die_sides, nil
}

/*
parse_uint parses a decimal string to int. Returns 0 on failure.
*/
parse_uint :: proc(s: string) -> int {
	result := 0
	for i := 0; i < len(s); i += 1 {
		c := s[i]
		if c < '0' || c > '9' {
			return 0
		}
		result = result * 10 + int(c - '0')
	}
	return result
}

/*
roll_single rolls a single die with the given number of sides.
Uses the secure_uniform_int wrapper for cryptographic randomness.
*/
roll_single :: proc(sides: int) -> int {
	n := secure_uniform_int(u32(sides))
	if n < 0 {
		return 0
	}
	return int(n) + 1
}

/*
roll_dice rolls count dice, each with sides faces.
All results are written to the results slice.
Returns the sum.
*/
roll_dice :: proc(results: []int, count: int, sides: int) -> (sum: int) {
	for i in 0 ..< count {
		val := roll_single(sides)
		results[i] = val
		sum += val
	}
	return
}

/*
format_text writes a human-readable roll result.
Format: "3d6: [4, 2, 6] → 12"
Uses strings.Builder to accumulate output, then copies to arena.
*/
format_text :: proc(arena: ^mem.Arena, results: []int, count: int, sides: int, sum: int) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "{}d{}", count, sides)
	strings.write_string(&builder, ": [")
	for i in 0 ..< count {
		if i > 0 {
			strings.write_string(&builder, ", ")
		}
		fmt.sbprintf(&builder, "{}", results[i])
	}
	strings.write_string(&builder, "] → ")
	fmt.sbprintf(&builder, "{}", sum)

	buf := strings.to_string(builder)
	out, err := mem.arena_alloc_bytes(arena, len(buf))
	if err != nil {
		return ""
	}
	copy(out, buf)
	return string(out)
}

/*
format_json writes a JSON roll result.
Format: {"count":3,"sides":6,"rolls":[4,2,6],"sum":12}
*/
format_json :: proc(arena: ^mem.Arena, results: []int, count: int, sides: int, sum: int) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, `{{"count":{},"sides":{},"rolls":[`, count, sides)
	for i in 0 ..< count {
		if i > 0 {
			strings.write_byte(&builder, ',')
		}
		fmt.sbprintf(&builder, "{}", results[i])
	}
	fmt.sbprintf(&builder, `],"sum":{}}}`, sum)

	buf := strings.to_string(builder)
	out, err := mem.arena_alloc_bytes(arena, len(buf))
	if err != nil {
		return ""
	}
	copy(out, buf)
	return string(out)
}

/*
Error represents a dice rolling error.
*/
Error :: enum {
	None,
	Invalid_Dice_Spec,
	Invalid_Die_Spec,
	Too_Many_Dice,
	Internal_RNG_Failure,
}