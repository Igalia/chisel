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


--- Parses an input string into a document tree.
--
-- @param input Input string.
-- @return Document tree.
--
function M.parsestring (input)
	local env = {}
	setmetatable (env, { __index = doc_funcs })
	local chunk, err = load (input, nil, "t", env)
	if chunk == nil then
		error (err)
	end
	return chunk ()
end


--- Parses an input file into a document tree.
--
-- @param input Path to input file. When omitted (or `nil`), data is read
-- from the standard input stream.
-- @return Document tree.
--
function M.parse (input)
	local env = {}
	setmetatable (env, { __index = doc_funcs })
	local chunk, err = loadfile (input, "t", env)
	if chunk == nil then
		error (err)
	end
	return chunk ()
end


return M

