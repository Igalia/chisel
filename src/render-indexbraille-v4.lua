---
-- Index Braille (V4 protocol) renderer.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local deepcopy = lib.util.deepcopy
local callable = lib.ml.callable
local tstring  = lib.ml.tstring
local renderer = lib.renderer
local cset     = lib.charset
local abs      = math.abs
local pairs    = pairs
local error    = error


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


--- Supported line spacing distance names.
--
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


--- Intersects two sets of device options, returning the changes.
--
-- @param old Table of *old* options (a.k.a. the currrent set of active
-- options).
-- @param new Table of *new* options. This table only needs to specify the
-- options which are to be changed.
-- @return Set of options to be changed: options present both in the old
-- *and* the new set of options *with changed values*. Note that options
-- for which the new value would be the same *will not* be in the result.
-- @function intersect_options
--
local function intersect_options (old, new)
  local diff = {}
  for key, value in pairs (new) do
    if old[key] ~= nil and old[key] ~= value then
      diff[key] = value
    end
  end
  return diff
end


--- Renderer implementation
-- @section ibv4_renderer

--- Output renderer for Index Braille devices using the V4 protocol.
--
-- Object derived from @{renderer}.
--
-- @table ibv4
--
local ibv4 = renderer:extend ()

--- Renderer name.
ibv4.name = "indexbraille-v4"

--- Renderer description.
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
-- to `renderer:format`.
-- @return The renderer itself, to allow chaining commands.
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
	log_debug ("%s:dot_distance requested %f, chosen %f\n", self.name, value, chosen)
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
	log_debug ("%s:line_spacing requested %f, chosen %f\n", self.name, value, chosen)
  self:esc ("DLS%i", code)
  return chosen
end


--- Sends a number-of-copies option, but only if needed. The renderer supports
-- specifying a number of copies *only if more than one copy is requested*.
-- This means that requesting only one copy *must not* generate anything.
-- Also, the maximum number of copies is `10.000`.
--
-- @param value Number of copies, range `1-10.000`.
--
function ibv4:copies_option (value)
  if value < 1 or value > 10000 then
    error (("%s: copies = %i out of the 1-10.000 range"):format (self.name, value))
  end
  if value > 2 then
    log_debug ("%s:copies %i\n", self.name, value)
    self:esc ("DMC%i", value)
  end
end


--- Sends a top-margin option.
--
-- @param value Number of empty lines to leave at the top of pages.
--
function ibv4:top_margin_option (value)
  if value < 0 then
    error (("%s: top_margin = %i is negative"):format (self.name, value))
  end
  log_debug ("%s:top_margin %i\n", self.name, value)
  self:esc ("DTM%i", value)
end


--- Sends a binding-margin option.
--
-- @param value Number of empty character cells to leave at the left
-- margin in each line.
--
function ibv4:binding_margin_option (value)
  if value < 0 then
    error (("%s: binding_margin = %i is negative"):format (self.name, value))
  end
  log_debug ("%s:binding_margin %i\n", self.name, value)
  self:esc ("DBI%i", value)
end


--- Sends a lines-per-page option.
--
-- @param value Number of lines to fit in each page.
--
function ibv4:lines_per_page_option (value)
  if value < 0 then
    error (("%s: lines_per_page = %i is negative"):format (self.name, value))
  end
  log_debug ("%s:lines_per_page %i\n", self.name, value)
  self:esc ("DLP%i", value)
end


--- Sends a character-per-line option.
--
-- @param value Number of character to fit in each line.
--
function ibv4:characters_per_line_option (value)
  if value < 0 then
    error (("%s: characters_per_line = %i is negative"):format (self.name, value))
  end
  log_debug ("%s:characters_per_line %i\n", self.name, value)
  self:esc ("DCH%i", value)
end


function ibv4:begin_document (node)
	-- The version parameter does not control any setting, but allows to
	-- track which combiation of driver/version generated the data stream.
	self:esc ("DVchisel-v%s", chisel.version)

	-- Set the initial options
	if self.device.default ~= nil then
		log_debug ("%s:begin_document resetting to default options\n", self.name)
		self:set_options (self.device.default)
	end

	-- Write commands needed to enable the requested options.
	if node.options then
		log_debug ("%s:begin_document setting document options\n", self.name)
		self:set_options (node.options)
	end
end


function ibv4:end_document (node)
	-- Also, reset the device to the default options at the end of
	-- the document, to leave it in a well-known state.
	if self.device.default ~= nil then
		log_debug ("%s:end_document resetting to default options\n", self.name)
		self:set_options (self.device.default)
	end
end


function ibv4:begin_text (node)
	self:write (node.data)
end


function ibv4:begin_graphics (node)
  local old_options = self:get_options ()
  local gfx_options = {}

  -- Modify the "graphics_*" options only
  for key, value in pairs (old_options) do
    if key:sub (1, #"graphics_") == "graphics_" then
      gfx_options[key:sub (#"graphics_" + 1)] = value
    end
  end

  -- Temporarily enable the graphics options, send out the
  -- graphics data, and the restore the saved options.
  self:set_options (gfx_options)
  self:write (cset.ESC):write ("\001") -- 0x1B 0x01 - begin 6-dot graphics.
  self:write (node.data)               -- Write graphics data payload.
  self:write (cset.ESC):write ("\002") -- 0x1B 0x02 - end 6-dot graphics.
  self:set_options (old_options)
end


function ibv4:set_options (options)
	log_debug ("ibv4:set_options(): %s\n", tstring (options))
	local changed_options
	if self._options == nil then
		changed_options = options
		self._options = {}
	else
		changed_options = intersect_options (self._options, options)
	end

	for option, value in pairs (changed_options) do
		-- Update the table tracking the current options
		self._options[option] = value

		-- Call the method which sets the option (if exists)
		local method = self[option .. "_option"]
		if callable (method) then
			method (self, value)
		else
			log_debug ("%s: ignoring option %q\n", self.name, option)
		end
	end

	return self
end

function ibv4:get_options ()
	-- This returns a *copy* of the options table
	return deepcopy (self._options)
end

return ibv4

