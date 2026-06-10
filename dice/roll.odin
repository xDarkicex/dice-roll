package dice

import "core:sort"

Advantage :: enum u8 { None, Advantage, Disadvantage }
KeepMode :: enum u8 { All, Highest, Lowest }
DieType  :: enum u8 { Normal, Fudge }

RollSpec :: struct {
	count:       int,
	sides:       int,
	die_type:    DieType,
	modifier:    int,
	advantage:   Advantage,
	keep_mode:   KeepMode,
	keep_count:  int,
	drop_count:  int,
	exploding:   bool,
	reroll_val:  int,
	target:      int,
	cancel_val:  int,
	wild_sides:  int,
	raise_step:  int,
	tn:          int,
}

RollResult :: struct {
	count:  int,
	sum:    int,
	total:  int,
	raises: int,
}

Error :: enum {
	None,
	Invalid_Spec,
	Too_Many_Dice,
	Internal_RNG_Failure,
}

MAX_DICE  :: 10000
MAX_SIDES :: 0xFFFF

roll :: proc(results: []int, spec: RollSpec) -> (RollResult, Error) {
	if spec.count < 1 || spec.count > MAX_DICE {
		return {}, Error.Too_Many_Dice
	}
	if spec.die_type != .Fudge && (spec.sides < 1 || spec.sides > MAX_SIDES) {
		return {}, Error.Invalid_Spec
	}

	result: RollResult

	if spec.wild_sides > 0 && spec.count == 1 {
		result = roll_wild(results, spec)
	} else if spec.advantage != .None {
		result = roll_advantage(results, spec)
	} else {
		result.count = spec.count
		result.sum = roll_basic(results[:spec.count], spec)
	}

	if spec.exploding && result.sum > 0 {
		result = apply_exploding(results, result.count, spec)
	}

	if spec.reroll_val > 0 {
		apply_rerolls(results[:result.count], spec)
		if spec.target == 0 {
			result.sum = sum_slice(results[:result.count])
		}
	}

	if spec.keep_mode != .All {
		_, kept_sum := apply_keep(results, result.count, spec)
		result.sum = kept_sum
	}

	if spec.target > 0 {
		successes := count_successes(results[:result.count], spec.target)
		if spec.cancel_val > 0 {
			cancels := count_value(results[:result.count], spec.cancel_val)
			successes -= cancels
			if successes < 0 {
				successes = 0
			}
		}
		result.sum = successes
	}

	result.total = result.sum + spec.modifier
	if result.total < 0 {
		result.total = 0
	}

	if spec.raise_step > 0 && spec.tn > 0 {
		if result.total > spec.tn {
			result.raises = (result.total - spec.tn) / spec.raise_step
		}
	}

	return result, nil
}

roll_basic :: proc(results: []int, spec: RollSpec) -> (sum: int) {
	for i in 0 ..< len(results) {
		val: int
		if spec.die_type == .Fudge {
			val = roll_fudge_die()
		} else {
			val = roll_single_die(spec.sides)
		}
		results[i] = val
		sum += val
	}
	return
}

roll_single_die :: proc(sides: int) -> int {
	n := secure_uniform_int(u32(sides))
	if n < 0 {
		return 0
	}
	return int(n) + 1
}

roll_fudge_die :: proc() -> int {
	n := secure_uniform_int(3)
	if n < 0 {
		return 0
	}
	return int(n) - 1
}

roll_wild :: proc(results: []int, spec: RollSpec) -> RollResult {
	if len(results) < 2 {
		return RollResult{count = 1, sum = 0}
	}

	a := roll_single_die(spec.sides)
	b := roll_single_die(spec.wild_sides)

	results[0] = a
	results[1] = b

	sum := a
	if b > a {
		sum = b
	}
	return RollResult{count = 2, sum = sum}
}

roll_advantage :: proc(results: []int, spec: RollSpec) -> RollResult {
	if len(results) < 2 {
		return RollResult{count = 1, sum = 0}
	}

	a := roll_single_die(spec.sides)
	b := roll_single_die(spec.sides)

	if spec.advantage == .Advantage {
		if b > a {
			a, b = b, a
		}
	} else {
		if b < a {
			a, b = b, a
		}
	}

	results[0] = a
	results[1] = b
	return RollResult{count = 2, sum = a}
}

apply_rerolls :: proc(results: []int, spec: RollSpec) {
	for i in 0 ..< len(results) {
		if results[i] == spec.reroll_val {
			results[i] = roll_single_die(spec.sides)
		}
	}
}

apply_exploding :: proc(results: []int, initial_count: int, spec: RollSpec) -> RollResult {
	total := initial_count
	sum := 0
	for i in 0 ..< total {
		sum += results[i]
	}

	idx := 0
	for idx < total && total < MAX_DICE {
		if results[idx] < spec.sides {
			idx += 1
			continue
		}
		if total >= len(results) {
			break
		}
		val := roll_single_die(spec.sides)
		results[total] = val
		sum += val
		total += 1
		idx += 1
	}
	return RollResult{count = total, sum = sum}
}

apply_keep :: proc(results: []int, count: int, spec: RollSpec) -> (kept_count: int, sum: int) {
	kept_count = spec.keep_count
	if kept_count > count {
		kept_count = count
	}
	if kept_count < 1 {
		kept_count = 1
	}

	sort.quick_sort(results[:count])

	if spec.keep_mode == .Highest {
		start := count - kept_count
		for i in start ..< count {
			sum += results[i]
		}
	} else {
		for i in 0 ..< kept_count {
			sum += results[i]
		}
	}
	return
}

count_successes :: proc(results: []int, target: int) -> (successes: int) {
	for i in 0 ..< len(results) {
		if results[i] >= target {
			successes += 1
		}
	}
	return
}

count_value :: proc(results: []int, val: int) -> (count: int) {
	for i in 0 ..< len(results) {
		if results[i] == val {
			count += 1
		}
	}
	return
}

sum_slice :: proc(results: []int) -> (sum: int) {
	for v in results {
		sum += v
	}
	return
}
