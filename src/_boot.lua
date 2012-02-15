---
-- Chisel "boot" module containing builtins and common startup code.
--
-- Functionality defined in this module is available in the global
-- environment automatically.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local str  = require "string"
local io   = require "io"
local chsl = _G["chisel"]

assert(chsl,
       "symbol \"chisel\" is not defined")
assert(type(chsl) == "table",
       "type of \"chisel\" is not \"table\"")

local function _log(level, format, ...)
	if chsl.loglevel >= level then
		io.stderr:write(str.format(format, ...))
		io.stderr:flush()
	end
end

--- Send a verbose message to stderr.
--
-- Formats a message string, and sends it to the standard error output, but
-- only if `chisel.loglevel` is non-zero.
--
-- @param format Format string.
-- @param ... Format string arguments.
--
verbose = function (format, ...) _log(1, format, ...) end

--- Send a debug message to stderr.
--
-- Formats a message string, and sends it to the standard error output, but
-- only if `chisel.loglevel` is above `1`.
--
-- @param format Format string.
-- @param ... Format string arguments.
--
debug = function (format, ...) _log(2, format, ...) end


verbose ("chisel %s\n", chisel.version)
debug   (" - libdir = %q\n", chisel.libdir)
debug   (" - script = %q\n", chisel.script)
debug   (" - loglevel = %q\n", chisel.version)
debug   (" - interactive = %i\n", chisel.interactive)


--- Base object.
--
-- Chisel provides a simple base `object` class that supports a
-- simple, prototype-based, single-inheritance object system. It
-- is kept intentionally small. As the system is prototype-based,
-- there is no *classes* as such, just objects were cloned from
-- other objects.
--
-- A typical example on how to use the system would be:
--
-- 	animal = object:clone {
--		what = function (self)
--			return "This is " .. self.name
--		end;
--	}
--	cat = animal:clone {
--		what = function (self)
--			return "Meoooww! - Me iz " .. self.name
--		end;
--	}
--	peter = animal:clone { name = "Peter" }
--	roger = cat:clone { name = "Roger" }
--	print(peter:what())
--	print(roger:what())
--
-- Apart from cloning objects, they can also be *augmented* by
-- using @{object:extend}, and inspected using @{object:prototype}
-- and @{object:derives}.
--
-- @section object
--
object = {}

--- Clones an object.
--
-- Clones an object, returning a new one. The returned object will look
-- up missing attributes in the table in which `clone()` was called.
-- Optionally, a table from which to pick additional attributes can
-- be passed (n.b. it is equivalent to call @{object:extend} on the
-- returned object).
--
-- @param t Table with additional attributes (optional).
-- @return New cloned object.
--
function object:clone (t)
	local clone = {}
	setmetatable(clone, { __index = self })
	return t == nil and clone or clone:extend (t)
end

--- Extends an object with the content of another object or table.
--
-- Copies all the *(key, value)* pairs from the passed table to the
-- object. Note that only a shallow copy is done.
--
-- @param t Table from where to copy elements.
-- @return The object itself, to allow chained calls.
--
function object:extend (t)
	for k, v in pairs (t) do
		self[k] = v
	end
	return self
end

--- Gets the prototype of an object.
--
-- The prototype is the base object from which the object was cloned.
-- @return A table (the prototype) or `nil` (for the base object).
--
function object:prototype ()
	local meta = getmetatable (self)
	return meta and meta.__index
end

--- Checks whether an object is derived from some other object.
--
-- **Note** that this function will traverse the object prototype
-- chain recursively, so it may be slow.
--
-- @param obj Reference object.
-- @return Whether the object derives from the reference object.
--
function object:derives (obj)
	local meta = getmetatable (self)
	while true do
		-- No metatable, or no __index, means it's the base object
		if not (meta and meta.__index) then
			return false
		end
		-- Yup, this is derived
		if meta.__index == obj then
			return true
		end
		-- Climb up in the hierarchy
		meta = getmetatable (meta.__index)
	end
end


--- Module auto-import
--
-- @section auto_import
--

--- Automatic module importing.
--
-- Indexing the `lib` table will auto-load modules. This provides
-- the needed syntactic sugar to be able to write:
--
-- 	local mymodule = lib.mymodule
--
-- The built-in @{require} Lua function is used for loading modules.
--
lib = {}
setmetatable (lib, { __index = function (_, k) return require (k) end })

--
-- When running in interactive mode, load some extra niceties
-- from the "replutils" module into the global namespace.
--
if chisel.interactive then
	for k, v in pairs (lib.replutils) do
		if type (v) == "function" then
			_G[k] = v
		end
	end
end
