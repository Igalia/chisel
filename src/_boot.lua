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

