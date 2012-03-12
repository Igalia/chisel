---
-- Index Braille (V4 protocol) device.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local callable = lib.ml.callable
local cset     = lib.charset
local abs      = math.abs
local pairs    = pairs


--- Support functions
-- @section dev_ibv4_support

--- Supported dot distances, in millimeters.
--
local dot_distances = {
	[2.0] = 0; -- 2.0mm dot distance.
	[2.5] = 1; -- 2.5mm dot distance.
	[1.6] = 2; -- 1.6mm dot distance.
}


--- Supported line spacing distances, in millimeters.
--
local line_spacings = {
  [ 5.0] =  50; -- 5.0mm line spacing (single spacing).
  [10.0] = 100; -- 10.0mm line spacing (double spacing).
}

local line_spacings_by_name = { single = 5.0; double = 10.0 }


local function value_for_closest_key (tab, value)
  local code = tab[value]
  if code == nil then
    -- Search for the closest match
    local closest
    for candidate, candidate_code in pairs (tab) do
      if closest == nil or abs (candidate - value) < abs (closest - value) then
        closest, code = candidate, candidate_code
      end
    end
    value = closest
  end
  return value, code
end


--- Device implementation
-- @section dev_ibv4_device

--- Output device for Index Braille devices using the V4 protocol.
--
-- Object derived from @{device}.
--
-- @table ibv4
--
local ibv4 = lib.device:clone ()

--- Device name.
ibv4.name = "indexbraille-v4"

--- Device description.
ibv4.description = [[\
Output to Index Braille embossers using version 4 of the protocol.
]]

--- Sends data inside an escape sequence.
--
-- Escape sequences are made by an ASCII escape character, a sequence of
-- a command and its arguments, and a semicolon used for terminating the
-- escape sequence.
--
-- @param ... Format string and its arguments. Those are passed as-is
-- to `device:format`.
-- @return The device itself, to allow chaining commands.
--
function ibv4:esc (...)
	return self:write (cset.ESC):format (...):write (";")
end

--- Sends a dot-distance option. The value passed will be searched in
-- the @{dot_distances} table. If not found, the closest value will be
-- chosen.
--
-- @param value Dot distance, in millimeters.
-- @return Actual value selected.
--
function ibv4:dot_distance_option (value)
  local chosen, code = value_for_closest_key (dot_distances, value,
                                              self.name .. ":dot_distance_option")
	debug ("%s:dot_distance requested %f, chosen %f\n", self.name, value, chosen)
	self:esc ("DGD%i", code)
	return chosen
end


--- Sends a line-spacing option. The value passed will be searched in the
-- @{line_spacings} table. If not found, the closest value will be chosen.
--
-- @param value Line spacing, in millimeters. The string values `"single"`
--   and `"double"` are also accepted.
-- @return Actual value selected.
--
function ibv4:line_spacing_option (value)
  if type (value) == "string" then
    value = line_spacings_by_name[value]
  end

  local chosen, code = value_for_closest_key (line_spacings, value,
                                              self.name .. ":line_spacing_option")
	debug ("%s:line_spacing requested %f, chosen %f\n", self.name, value, chosen)
  self:esc ("DLS%i", code)
  return chosen
end


function ibv4:begin_document (node)
	-- The version parameter does not control any setting, but allows to
	-- track which combiation of driver/version generated the data stream.
	self:esc ("DVchisel-v%s", chisel.version)

	-- Write commands needed to enable the requested options.
	if node.options then
		for option, value in pairs (node.options) do
			local method = self[option .. "_option"]
			if callable (method) then
				method (self, value)
			else
				debug ("%s: Ignoring option %q\n", self.name, option)
			end
		end
	end
end

function ibv4:begin_text (node)
	self:write (node.data)
end

return ibv4

