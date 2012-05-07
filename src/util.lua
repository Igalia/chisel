---
-- Collection of assorted utilities.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local pairs, type = pairs, type
local util = {}

--- Data types.
-- @section util_data_types

--- Stack.
--
-- @table util.stack
--
util.stack = object:clone
{
  --- Check whether the stack is empty.
  -- This is equivalent to use the `#` operator on the object.
  -- @function stack:empty
  --
  empty = function (self)
    return #self == 0
  end;

  --- Obtain the element at the top of the stack.
  -- @function stack:top
  --
  top = function (self)
    return self[#self]
  end;

  --- Pop en element from the stack.
  -- The element at the top is returned.
  -- @function stack:pop
  --
  pop = function (self)
    local idx = #self
    local top = self[idx]
    self[idx] = nil
    return top
  end;

  --- Push an element on the top of the stack.
  -- Returns the object itself, to allow chaining method calls.
  -- @param value Element to push.
  -- @param copy When the element being pushed is a table, whether to make
  -- a shallow copy of it, instead of pushing a reference. If the argument
  -- is not specified, the default is to make copies.
  -- @function stack:push
  --
  push = function (self, value, copy)
    -- Copy tables by default
    copy = (copy == nil) and true or copy

    if copy and type (value) == "table" then
      local newcopy = {}
      for k, v in pairs (value) do
        newcopy[k] = v
      end
      value = newcopy
    end
    self[#self + 1] = value
    return self
  end;
}


return util

