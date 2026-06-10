package dice

import "core:fmt"
import "core:mem"
import "core:strings"

/*
format_text writes a human-readable roll result.
Adapts output based on the roll spec's features.
*/
format_text :: proc(arena: ^mem.Arena, results: []int, result: RollResult, spec: RollSpec) -> string {
	b := strings.builder_make()

	spec_text(&b, spec)
	strings.write_string(&b, ": [")

	if spec.wild_sides > 0 && spec.count == 1 {
		wild_write_results(&b, results[:result.count], spec)
	} else if spec.advantage != .None {
		adv_write_results(&b, results[:result.count], spec)
	} else {
		write_comma_list(&b, results[:result.count])
	}

	strings.write_string(&b, "] → ")

	if spec.target > 0 {
		fmt.sbprintf(&b, "{} successes", result.sum)
	} else if spec.modifier != 0 && spec.exploding {
		fmt.sbprintf(&b, "{} + {} = {}", result.sum, spec.modifier, result.total)
	} else if spec.modifier != 0 {
		fmt.sbprintf(&b, "{} + {} = {}", result.sum, spec.modifier, result.total)
	} else {
		fmt.sbprintf(&b, "{}", result.total)
	}

	if result.raises > 0 {
		plural := "raises"
		if result.raises == 1 {
			plural = "raise"
		}
		fmt.sbprintf(&b, " ({} {})", result.raises, plural)
	}

	buf := strings.to_string(b)
	out, err := mem.arena_alloc_bytes(arena, len(buf))
	if err != nil {
		return ""
	}
	copy(out, buf)
	return string(out)
}

/*
format_json writes a JSON roll result.
*/
format_json :: proc(arena: ^mem.Arena, results: []int, result: RollResult, spec: RollSpec) -> string {
	b := strings.builder_make()

	fmt.sbprintf(&b, `{{"count":{},"sides":{}`, spec.count, spec.sides)
	if spec.die_type == .Fudge {
		strings.write_string(&b, `,"type":"fudge"`)
	}
	if spec.modifier != 0 {
		fmt.sbprintf(&b, `,"modifier":{}`, spec.modifier)
	}
	if spec.wild_sides > 0 {
		fmt.sbprintf(&b, `,"wild_sides":{}`, spec.wild_sides)
	}
	if spec.advantage != .None {
		adv_str := spec.advantage == .Advantage ? "adv" : "disadv"
		fmt.sbprintf(&b, `,"advantage":"{}"`, adv_str)
	}
	if spec.keep_mode != .All {
		mode_str := spec.keep_mode == .Highest ? "highest" : "lowest"
		fmt.sbprintf(&b, `,"keep_mode":"{}","keep_count":{}`, mode_str, spec.keep_count)
		if spec.drop_count > 0 {
			fmt.sbprintf(&b, `,"drop_count":{}`, spec.drop_count)
		}
	}
	if spec.exploding {
		strings.write_string(&b, `,"exploding":true`)
	}
	if spec.reroll_val > 0 {
		fmt.sbprintf(&b, `,"reroll":{}`, spec.reroll_val)
	}
	if spec.target > 0 {
		fmt.sbprintf(&b, `,"target":{},"successes":{}`, spec.target, result.sum)
		if spec.cancel_val > 0 {
			fmt.sbprintf(&b, `,"cancel_val":{}`, spec.cancel_val)
		}
	}
	if spec.raise_step > 0 {
		fmt.sbprintf(&b, `,"raise_step":{},"tn":{},"raises":{}`, spec.raise_step, spec.tn, result.raises)
	}

	strings.write_string(&b, `,"rolls":[`)
	write_json_list(&b, results[:result.count])
	fmt.sbprintf(&b, `],"sum":{},"total":{}}}`, result.sum, result.total)

	buf := strings.to_string(b)
	out, err := mem.arena_alloc_bytes(arena, len(buf))
	if err != nil {
		return ""
	}
	copy(out, buf)
	return string(out)
}

/*
spec_text writes the canonical dice notation string for a RollSpec.
*/
spec_text :: proc(b: ^strings.Builder, spec: RollSpec) {
	if spec.die_type == .Fudge {
		fmt.sbprintf(b, "{}dF", spec.count)
		return
	}
	fmt.sbprintf(b, "{}d{}", spec.count, spec.sides)
	if spec.wild_sides > 0 {
		fmt.sbprintf(b, "w{}", spec.wild_sides)
	}
	if spec.modifier != 0 {
		if spec.modifier > 0 {
			fmt.sbprintf(b, "+{}", spec.modifier)
		} else {
			fmt.sbprintf(b, "-{}", -spec.modifier)
		}
	}
	if spec.drop_count > 0 {
		fmt.sbprintf(b, "d{}", spec.drop_count)
	} else if spec.keep_mode == .Highest {
		fmt.sbprintf(b, "k{}", spec.keep_count)
	} else if spec.keep_mode == .Lowest {
		fmt.sbprintf(b, "d{}", spec.keep_count)
	}
	if spec.exploding {
		strings.write_byte(b, '!')
	}
	if spec.reroll_val > 0 {
		fmt.sbprintf(b, "r{}", spec.reroll_val)
	}
	if spec.target > 0 {
		fmt.sbprintf(b, "t{}", spec.target)
		if spec.cancel_val > 0 {
			fmt.sbprintf(b, "c{}", spec.cancel_val)
		}
	}
}

write_comma_list :: proc(b: ^strings.Builder, results: []int) {
	for i in 0 ..< len(results) {
		if i > 0 {
			strings.write_string(b, ", ")
		}
		fmt.sbprintf(b, "{}", results[i])
	}
}

write_json_list :: proc(b: ^strings.Builder, results: []int) {
	for i in 0 ..< len(results) {
		if i > 0 {
			strings.write_byte(b, ',')
		}
		fmt.sbprintf(b, "{}", results[i])
	}
}

adv_write_results :: proc(b: ^strings.Builder, results: []int, spec: RollSpec) {
	if len(results) >= 2 {
		fmt.sbprintf(b, "{}, {}", results[0], results[1])
	}
}

wild_write_results :: proc(b: ^strings.Builder, results: []int, spec: RollSpec) {
	if len(results) >= 2 {
		fmt.sbprintf(b, "{}, {}", results[0], results[1])
	}
}
