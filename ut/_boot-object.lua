--
-- ut/_boot-object.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local getmetatable = getmetatable


function test_clone ()
  local o = object:clone ()
  assert_not_equal (o, object)
  assert_equal (object, getmetatable (o).__index)
  assert_equal (object, o:prototype ())
  assert_true  (o:derives (object))
  assert_false (o:derives ({}))
  assert_false (o:derives (4))
end

function test_clone_extend ()
  -- Attributes go to the new clone
  local o1 = object:clone { foo = 42 }
  assert_equal (42, o1.foo)

  -- Extending again *overwrites* attributes
  -- Attributes in the base object remains unchanged
  local o2 = object:clone { foo = 666, bar = 13 }
  assert_equal (666, o2.foo)
  assert_equal (13,  o2.bar)
  assert_equal (42,  o1.foo)
  assert_equal (nil, o1.bar)
end

function test_derives ()
  local animal = object:clone ()
  local person = animal:clone ()
  local cat    = animal:clone ()
  local user   = person:clone ()
  assert_true  (user:derives (animal))
  assert_true  (user:derives (person))
  assert_false (user:derives (cat))
  assert_true  (cat:derives (animal))
  assert_false (cat:derives (user))
  assert_false (cat:derives (person))
end

