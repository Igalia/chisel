---
-- Output rendering.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local safe_require = lib.ml.safe (require)
local io_write = io.write

--- Base class for output rendering.
--
-- A renderer implements the conversion from a document tree to a data
-- stream that actual devices can understand.
--
-- @todo Describe functions that can/should be implemented in renderer
-- subclasses.
--
-- @section renderer
--
local renderer = object:extend
{
	--- Writes data to the backend.
	--
	-- By defaults, data is sent to the standard output stream, which is the
	-- common way of implementing printer filters. Subclasses may override or
	-- redefine this method in case sending the data to a different
	-- destination is desired.
	--
	-- @param data Data string to be written.
	-- @return The renderer itself, to allow call-chaining.
	-- @function renderer:write
	--
	write = function (self, data)
		io_write (data)
		return self
	end;

	--- Format a string and send it to the output.
	--
	-- Uses the <tt>write()</tt> function to send the data to the output,
	-- after formatting it using <tt>string.format()</tt>.
	--
	-- @param format Format string.
	-- @param ... Format string arguments.
	-- @return The renderer itself, to allow call-chaining.
	-- @function renderer:format
	--
	format = function (self, format, ...)
		return self:write (format:format (...))
	end;

	set_options = function (self, options)
		log_debug ("renderer:set_options() unimplemented for '%s'\n", self.name)
	end;

	get_options = function (self)
		log_debug ("renderer:get_options() unimplemented for '%s'\n", self.name)
	end;

	--- Gets a particular renderer given its name.
	--
	-- @param name Name of the output renderer, e.g. `indexbraille-v4`.
	-- @param writef Write function. This can be used to override the
	--               @{device:write} method used to output the data.
	-- @function renderer.get
	--
	get = function (name, writef)
		local rend, err = safe_require ("render-" .. name)
		if rend then
      if writef ~= nil then
        rend.write = writef
      end
		  if rend.init then
		    rend = rend:init ()
      end
    end
		return rend, err
	end;
}

return renderer

