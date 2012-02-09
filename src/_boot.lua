#! /usr/bin/env lua
--
-- _boot.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
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

verbose = function (...) _log(1, ...) end
debug   = function (...) _log(2, ...) end

verbose("chisel %s\n", chisel.version)
debug(" - libdir = %q\n", chisel.libdir)
debug(" - loglevel = %q\n", chisel.version)
debug(" - interactive = %i\n", chisel.interactive)


-- Really simple no-frill prototype-based object orientation
object =
{
	-- Objects can be cloned (and optionally extended)
	clone = function (self, t)
		local clone = {}
		setmetatable(clone, { __index = self })
		return t == nil and clone or clone:extend (t)
	end;

	-- Objects can be extended with the contents of another table
	extend = function (self, t)
		for k, v in pairs (t) do
			self[k] = v
		end
		return self
	end;
}
