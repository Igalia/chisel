#! /usr/bin/env lua
--
-- util.lua
-- Copyright (C) 2013 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local deepcopy = lib.util.deepcopy
local rupdate  = lib.util.rupdate


function test_rupdate_simple_types()
  assert_equal (1, rupdate (1, 1))
  assert_equal (2, rupdate (1, 2))
  assert_equal (3, rupdate ("a", 3))
  assert_equal ("b", rupdate ("a", "b"))
  assert_equal ("c", rupdate (1, "c"))
  assert_equal ("t", rupdate ({}, "t"))
  assert_equal ("u", rupdate ({{}}, "u"))
end

function test_rupdate_simplesrc_tabledst()
  local r = rupdate (1, { a = 42; b = "foo" })
  assert_equal ("table", type (r))
  assert_equal (42, r.a)
  assert_equal ("foo", r.b)
end

function test_rupdate_shallow_table()
  local spam = { all = 42; foo = "bar" }
  local eggs = { all = 24; bar = "baz" }
  local r

  -- XXX Work with copies, to avoid issues with the side effects
  r = rupdate (deepcopy (spam), deepcopy (eggs))
  assert_equal ("table", type (r))
  assert_equal (24, r.all)
  assert_equal ("bar", r.foo)
  assert_equal ("baz", r.bar)

  r = rupdate (deepcopy (eggs), deepcopy (spam))
  assert_equal ("table", type (r))
  assert_equal (42, r.all)
  assert_equal ("bar", r.foo)
  assert_equal ("baz", r.bar)
end

function test_rupdate_deep_table()
  local a = { n = 42; foo = { 1, 2 }; bar = { a = 3; b = 4 }}
  local b = { n = 24; baz = { 5, 6 }; bar = { a = 7; b = 8 }}
  local r

  r = rupdate (deepcopy (a), deepcopy (b))
  assert_equal (24, r.n)
  assert_equal (7, r.bar.a)
  assert_equal (8, r.bar.b)
  assert_equal (1, r.foo[1])
  assert_equal (2, r.foo[2])
  assert_equal (5, r.baz[1])
  assert_equal (6, r.baz[2])

  r = rupdate (deepcopy (b), deepcopy (a))
  assert_equal (42, r.n)
  assert_equal (3, r.bar.a)
  assert_equal (4, r.bar.b)
  assert_equal (1, r.foo[1])
  assert_equal (2, r.foo[2])
  assert_equal (5, r.baz[1])
  assert_equal (6, r.baz[2])
end

function test_rupdate_array_table()
  local a = { 1, 2, 3, 4, 5 }
  local b = { 1, 4, 3, 2, 5 }
  local r = rupdate (a, b)

  assert_equal (1, r[1])
  assert_equal (4, r[2])
  assert_equal (3, r[3])
  assert_equal (2, r[4])
  assert_equal (5, r[5])
end

