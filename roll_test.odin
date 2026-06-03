package main

import "core:fmt"
import "core:mem"
import "core:testing"

ARR_SIZE :: 8

@(test)
test_parse_uint_empty :: proc(t: ^testing.T) {
	result := parse_uint("")
	testing.expect_value(t, result, 0)
}

@(test)
test_parse_uint_valid :: proc(t: ^testing.T) {
	result := parse_uint("123")
	testing.expect_value(t, result, 123)
}

@(test)
test_parse_uint_leading_zeros :: proc(t: ^testing.T) {
	result := parse_uint("007")
	testing.expect_value(t, result, 7)
}

@(test)
test_parse_uint_non_digit :: proc(t: ^testing.T) {
	result := parse_uint("12a3")
	testing.expect_value(t, result, 0)
}

@(test)
test_parse_uint_single_digit :: proc(t: ^testing.T) {
	result := parse_uint("5")
	testing.expect_value(t, result, 5)
}

@(test)
test_parse_uint_all_zeros :: proc(t: ^testing.T) {
	result := parse_uint("000")
	testing.expect_value(t, result, 0)
}

@(test)
test_parse_die_empty :: proc(t: ^testing.T) {
	die, err := parse_die("")
	testing.expect_value(t, err, Error.Invalid_Die_Spec)
	testing.expect_value(t, die.sides, 0)
}

@(test)
test_parse_die_d20 :: proc(t: ^testing.T) {
	die, err := parse_die("d20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 20)
}

@(test)
test_parse_die_D20 :: proc(t: ^testing.T) {
	die, err := parse_die("D20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 20)
}

@(test)
test_parse_die_d1 :: proc(t: ^testing.T) {
	die, err := parse_die("d1")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 1)
}

@(test)
test_parse_die_d65535 :: proc(t: ^testing.T) {
	die, err := parse_die("d65535")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 65535)
}

@(test)
test_parse_die_too_large :: proc(t: ^testing.T) {
	die, err := parse_die("d65536")
	testing.expect_value(t, err, Error.Invalid_Die_Spec)
	testing.expect_value(t, die.sides, 0)
}

@(test)
test_parse_die_zero :: proc(t: ^testing.T) {
	die, err := parse_die("d0")
	testing.expect_value(t, err, Error.Invalid_Die_Spec)
}

@(test)
test_parse_die_plain_20 :: proc(t: ^testing.T) {
	die, err := parse_die("20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 20)
}

@(test)
test_parse_die_plain_1 :: proc(t: ^testing.T) {
	die, err := parse_die("1")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, die.sides, 1)
}

@(test)
test_parse_dice_spec_empty :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("")
	testing.expect_value(t, err, Error.Invalid_Dice_Spec)
	testing.expect_value(t, c, 0)
	testing.expect_value(t, s, 0)
}

@(test)
test_parse_dice_spec_3d6 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("3d6")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 3)
	testing.expect_value(t, s, 6)
}

@(test)
test_parse_dice_spec_3D6 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("3D6")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 3)
	testing.expect_value(t, s, 6)
}

@(test)
test_parse_dice_spec_d20 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("d20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 1)
	testing.expect_value(t, s, 20)
}

@(test)
test_parse_dice_spec_1d20 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("1d20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 1)
	testing.expect_value(t, s, 20)
}

@(test)
test_parse_dice_spec_plain_20 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("20")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 1)
	testing.expect_value(t, s, 20)
}

@(test)
test_parse_dice_spec_10000d6 :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("10000d6")
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 10000)
	testing.expect_value(t, s, 6)
}

@(test)
test_parse_dice_spec_too_many_dice :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("10001d6")
	testing.expect_value(t, err, Error.Too_Many_Dice)
	testing.expect_value(t, c, 0)
}

@(test)
test_parse_dice_spec_zero_count :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("0d6")
	testing.expect_value(t, err, Error.Too_Many_Dice)
}

@(test)
test_parse_dice_spec_invalid_sides :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("dabc")
	testing.expect_value(t, err, Error.Invalid_Die_Spec)
}

@(test)
test_parse_dice_spec_no_sides_after_d :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("3d")
	testing.expect_value(t, err, Error.Invalid_Dice_Spec)
}

@(test)
test_parse_dice_spec_invalid_count :: proc(t: ^testing.T) {
	c, s, err := parse_dice_spec("abc3d6")
	testing.expect_value(t, err, Error.Too_Many_Dice)
}

@(test)
test_roll_single_range :: proc(t: ^testing.T) {
	// Test that roll_single returns values in valid range [1, sides]
	sides_list := []int{2, 6, 20, 100}
	for j in 0 ..< len(sides_list) {
		sides := sides_list[j]
		for i in 0 ..< 100 {
			val := roll_single(sides)
			testing.expect(t, val >= 1 && val <= sides,
				fmt.tprintf("roll_single(%d) = %d, outside valid range [1, %d]", sides, val, sides))
		}
	}
}

@(test)
test_roll_dice_basic :: proc(t: ^testing.T) {
	results: [ARR_SIZE]int
	sum := roll_dice(results[:3], 3, 6)
	testing.expect_value(t, sum > 0, true)

	for i in 0 ..< 3 {
		testing.expect(t, results[i] >= 1 && results[i] <= 6,
			fmt.tprintf("results[%d] = %d, expected [1, 6]", i, results[i]))
	}
}

@(test)
test_roll_dice_single :: proc(t: ^testing.T) {
	results: [ARR_SIZE]int
	sum := roll_dice(results[:1], 1, 20)
	testing.expect_value(t, sum >= 1 && sum <= 20, true)
}

@(test)
test_roll_dice_zero :: proc(t: ^testing.T) {
	results: [ARR_SIZE]int
	sum := roll_dice(results[:0], 0, 6)
	testing.expect_value(t, sum, 0)
}

@(test)
test_format_text_single_die :: proc(t: ^testing.T) {
	backing: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [1]int = {5}

	out := format_text(&arena, results[:1], 1, 20, 5)
	testing.expect_value(t, out, "1d20: [5] → 5")
}

@(test)
test_format_text_multiple_dice :: proc(t: ^testing.T) {
	backing: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [3]int = {3, 4, 6}

	out := format_text(&arena, results[:3], 3, 6, 13)
	testing.expect_value(t, out, "3d6: [3, 4, 6] → 13")
}

@(test)
test_format_text_large_dice_count :: proc(t: ^testing.T) {
	backing: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [10]int = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

	out := format_text(&arena, results[:], 10, 6, 55)
	testing.expect_value(t, out, "10d6: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] → 55")
}

@(test)
test_format_json_single_die :: proc(t: ^testing.T) {
	backing: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [1]int = {10}

	out := format_json(&arena, results[:1], 1, 20, 10)
	testing.expect_value(t, out, `{"count":1,"sides":20,"rolls":[10],"sum":10}`)
}

@(test)
test_format_json_multiple_dice :: proc(t: ^testing.T) {
	backing: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [3]int = {1, 3, 4}

	out := format_json(&arena, results[:3], 3, 6, 8)
	testing.expect_value(t, out, `{"count":3,"sides":6,"rolls":[1,3,4],"sum":8}`)
}

@(test)
test_format_json_large_sum :: proc(t: ^testing.T) {
	backing: [256]byte
	arena: mem.Arena
	mem.arena_init(&arena, backing[:])
	results: [2]int = {6, 6}

	out := format_json(&arena, results[:2], 2, 6, 12)
	testing.expect_value(t, out, `{"count":2,"sides":6,"rolls":[6,6],"sum":12}`)
}