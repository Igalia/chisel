---
-- Document loader.
--
-- Provides functions to load document trees from an external representation
-- of it. The external representation is a small Lua-derived DSL that runs
-- in a sandboxed environment where only the functions needed to describe
-- a document are provided.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local callable = lib.ml.callable

local T = lib.doctree
local M = {}
local doc_funcs = {}

function doc_funcs.text (t)
	if type (t) == "table" then
		return T.text:clone { data = table.concat (t) }
	else
		return T.text:clone { data = tostring (t) }
	end
end

function doc_funcs.document (t)
	return T.document:clone { children = t }
end


local doc_options = {
	dot_distance = tonumber;
}


function doc_funcs.options (t, relaxed)
	local r = {}
	for option, value in pairs (t) do
		local convert = doc_options[option]
		if convert == nil then
			if not relaxed then
				error (("Option %q is invalid"):format (option))
			end
		else
			-- Option name is recognized. Try to do the conversion.
			if callable (convert) then
				r[option] = convert (value)
			else
				r[option] = value
			end
		end
	end
	return r
end

function doc_funcs.raw (device, data)
	return T.raw:clone { device = device; data = data }
end

--- Parses an input string into a document tree.
--
-- @param input Input string.
-- @return Document tree.
--
function M.parsestring (input)
	-- Create the sandboxed environment used for loading documents.
	local env = {}
	setmetatable (env, { __index = doc_funcs })

	-- The top-level document() function has to be created here as a closure
	-- so it can reference the "result" upvalue in the containing function.
	local result = nil
	local options = {}
	function env.document (...) result  = doc_funcs.document (...) end
	function env.options  (...) options = doc_funcs.options  (...) end

	-- Load the chunk from the passed string
	local chunk, err = load (input, nil, "t", env)
	if chunk == nil then
		return nil, err
	end

	chunk, err = pcall (chunk)
	if chunk == false then
		return nil, err
	end

	result.options = options
	return result
end


--- Parses an input file into a document tree.
--
-- @param input Path to input file. When omitted (or `nil`), data is read
-- from the standard input stream.
-- @return Document tree.
--
function M.parse (input)
	-- Create the sandbox environment used for loading documents.
	local env = {}
	setmetatable (env, { __index = doc_funcs })

	-- The top-level document() function has to be created here as a closure
	-- so it can reference the "result" upvalue in the containing function.
	local result = nil
	local options = {}
	function env.document (...) result  = doc_funcs.document (...) end
	function env.options  (...) options = doc_funcs.options  (...) end

	-- Load the chunk from disk
	local chunk, err = loadfile (input, "t", env)
	if chunk == nil then
		return nil, err
	end

	chunk, err = pcall (chunk)
	if chunk == false then
		return nil, err
	end

	result.options = options
	return result
end


--- Validates a table containing document options
--
-- @param options Table containing document options.
-- @param relaxed Relaxed checking: if an unrecognized option is given, it
--   will be silently ignored. If `false` (the default) then unrecognized
--   options will raise errors.
-- @return Table containing the converted options.
-- @name validate_options
M.validate_options = doc_funcs.options


return M

