--
-- ut/util-stack.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local s = nil

function setup ()
  s = lib.util.stack:clone ()
end

function teardown ()
  s = nil
end

function test_empty ()
  assert_equal (0, #s)
  assert_true (s:empty ())
end

function test_push_top ()
  s:push "foo"
  assert_equal (1, #s)
  assert_equal ("foo", s:top ())
  s:push "bar"
  assert_equal (2, #s)
  assert_equal ("bar", s:top ())
end

function test_top_pop ()
  s:push "foo"
  s:push "bar"
  s:push "baz"
  assert_equal (3, #s)
  assert_equal ("baz", s:top ())
  assert_equal ("baz", s:pop ())
  assert_equal (2, #s)
  assert_equal ("bar", s:top ())
  assert_equal ("bar", s:pop ())
  assert_equal (1, #s)
  assert_equal ("foo", s:top ())
  assert_equal ("foo", s:pop ())
  assert_equal (0, #s)
end

function test_push_pop ()
  s:push "foo"
  s:push "bar"
  assert_equal ("bar", s:pop ())
  s:push "baz"
  s:push "mmh"
  assert_equal ("mmh", s:pop ())
  assert_equal ("baz", s:pop ())
  s:push "wah"
  assert_equal ("wah", s:pop ())
  assert_equal ("foo", s:pop ())
end

function test_push_copy_table_arg ()
  s:push { a = 1 }
  s:push { a = 2 }
  assert_equal (2, s:pop ().a)
  assert_equal (1, s:pop ().a)
end

function test_push_copy ()
  local data = { a = 1 }
  s:push (data)
  data.a = 2
  s:push (data)
  assert_not_equal (data, s:top ())
  assert_equal (2, s:pop ().a)
  assert_not_equal (data, s:top ())
  assert_equal (1, s:pop ().a)
end

function test_push_same ()
  local data = { a = 1 }
  s:push (data, false)
  data.a = 2
  s:push (data, false)
  assert_equal (data, s:top ())
  assert_equal (data.a, s:top ().a)
  assert_equal (2, s:pop ().a)
  assert_equal (data, s:top ())
  assert_equal (data.a, s:top ().a)
  assert_equal (2, s:pop ().a)
end

function test_push_chain ()
  assert_equal (s, s:push "foo")
  assert_equal ("bar", s:push "bar" :top ())
end

