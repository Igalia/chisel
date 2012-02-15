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
