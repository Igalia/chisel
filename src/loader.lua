--
-- loader.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
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


function M.parsestring (input)
	local env = {}
	setmetatable (env, { __index = doc_funcs })
	local chunk, err = load (input, nil, "t", env)
	if chunk == nil then
		error (err)
	end
	return chunk ()
end


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

