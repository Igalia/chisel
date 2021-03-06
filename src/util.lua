---
-- Collection of assorted utilities.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local pairs, type = pairs, type
local util = {}

--- Convenience functions
-- @section util_convenience

local table_keys = lib.ml.keys

--- Returns a list with all the keys contained in a table.
--
-- @param t A table.
-- @return Table-list.
--
util.dir = table_keys


--- Returns a deep copy of a value.
--
-- @param t Table to obtain a copy of.
-- @return A copy of the table passed as arguments, with all sub-tables
-- copies recursively.
-- @function util.deepcopy
--
local function _deepcopy (t)
  if type (t) == "table" then
    local r = {}
    for k, v in pairs (t) do
      r[k] = _deepcopy (v)
    end
    return r
  else
    return t
  end
end
util.deepcopy = _deepcopy


--- Updates a table recursively with the contents of another table.
--
-- @param dst Destination table.
-- @param src Source table.
-- @return Destination table.
-- @function util.rupdate
--
local function _rupdate (dst, src)
  if type (dst) == "table" and type (src) == "table" then
    for k, v in pairs (src) do
      dst[k] = _rupdate (dst[k], v)
    end
    return dst
  else
    return _deepcopy (src)
  end
end
util.rupdate = _rupdate


--- How many millimeters long is one PostScript Default Unit (1/72in).
local u_to_mm_ratio = 0.352777778

--- Converts PostScript Default Units to millimeters.
--
-- @param value Numeric value in PostScript Default Units (1u = 1/72in).
-- @return Value converted to millimeters.
-- @function util.u_to_mm
--
function util.u_to_mm (value)
  return value * u_to_mm_ratio
end

--- Convers millimeters to PostScript Default Units.
--
-- @param value Numeric value in millimeters.
-- @return Value converted to PostScript Default Units (1u = 1/72in).
-- @function util.mm_to_u
--
function util.mm_to_u (value)
  return value / u_to_mm_ratio
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
			result = result .. string.format ("[%s] = %s, ", i, ppv)
		elseif type (v) == "string" then
			result = result .. string.format ("[%q] = %s, ", i, ppv)
		else
			result = result .. string.format ("[%s] = %s, ", tostring (i), ppv)
		end
	end
	return result .. "}"
end

--- Pretty print the given value.
--
-- @param v Value to be pretty-printed.
-- @return String with a representation of the argument, which is suitable
-- for displaying to the user. Do <em>not</em> use this function for
-- object serializtion!
--
function util.pprint (v)
	return (pprint[type (v)] or tostring) (v)
end


return util

