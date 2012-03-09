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
-- the @{dot_distances} table. If not found, the closer value will be
-- chosen.
--
-- @param value Dot distance, in millimeters.
-- @return Actual value selected.
--
function ibv4:dot_distance_option (value)
	local code = dot_distances[value]
	if code == nil then
		-- Search for the closest match
		local closest
		for candidate, candidate_code in pairs (dot_distances) do
			if closest == nil or abs (candidate - value) < abs (closest - value) then
				closest, code = candidate, candidate_code
			end
		end
		debug ("%s: dot_distance: requested %f, chosen %f\n",
		       self.name, value, closest)
		value = closest
	end
	self:esc ("DGD%i", code)
	return value
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

