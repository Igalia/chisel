#! /usr/bin/env lua
--
-- replutils.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local M = {}


--
-- dir(t): Returns a table with all the keys of a table.
--
function M.dir (t)
	local result = {}
	for k, _ in pairs (t) do
		table.insert (result, k)
	end
	return result
end


--
-- Pretty printer. This auxiliar table is used as jump-table indexed by the
-- type name of the value that is to be pretty-printed.
--
local pprint = {}

function pprint.string (s)
	return string.format ("%q", s)
end

function pprint.number (n)
	return tostring (n)
end

function pprint.table (t)
	-- XXX This is slow...
	local result = "{ "
	for i, v in pairs (t) do
		local ppv = (pprint[type (v)] or tostring) (v)
		if type (v) == "number" then
			result = result .. string.format ("[%i] = %s, ", i, ppv)
		elseif type (v) == "string" then
			result = result .. string.format ("[%q] = %s, ", i, ppv)
		else
			result = result .. string.format ("[%s] = %s, ", tostring (i), ppv)
		end
	end
	return result .. "}"
end

--
-- pprint(v): Pretty-print the given value. Returns a string with
-- a representation of the argument which is suitable for displaying
-- to the user. Do *not* use this as a serialization function.
--
function M.pprint (v)
	return (pprint[type (v)] or tostring) (v)
end


return M

