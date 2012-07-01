---
-- Output rendering utlities.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local safe_require = lib.ml.safe (require)
local io_write = io.write
local M = {}

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
M.renderer = object:extend
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
	-- @name renderer:write
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
	-- @name device:format
	--
	format = function (self, format, ...)
		return self:write (format:format (...))
	end;

	--- Gets a particular renderer given its name.
	--
	-- @param name Name of the output renderer, e.g. `indexbraille-v4`.
	-- @param writef Write function. This can be used to override the
	--               @{device:write} method used to output the data.
	-- @name device.get
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

return M

