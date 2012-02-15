---
-- Device output.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local strfmt = string.format

--- Base class for devices.
--
-- A device implements the conversion from a document tree to a data stream
-- that actual devices can understand. Device implementations can be
-- instantiated using <tt>create()</tt>.
--
-- @todo Describe functions that can/should be implemented in device
-- subclasses.
--
-- @section device
--
local device = object:clone
{
	--- Writes data to the backend.
	--
	-- By defaults, data is sent to the standard output stream, which is the
	-- common way of implementing printer filters. Subclasses may override or
	-- redefine this method in case sending the data to a different
	-- destination is desired.
	--
	-- @param data Data string to be written.
	-- @return The device itself, to allow call-chaining.
	-- @name device:write
	--
	write = function (self, data)
		io.write (data)
		return self
	end;

	--- Format a string and send it to the output device.
	--
	-- Uses the <tt>write()</tt> function to send the data to the output,
	-- after formatting it using <tt>string.format()</tt>.
	--
	-- @param format Format string.
	-- @param ... Format string arguments.
	-- @return The device itself, to allow call-chaining.
	-- @name device:format
	--
	format = function (self, format, ...)
		self:write (strfmt (format, ...))
		return self
	end;

	--- Gets a particular output device given its name.
	--
	-- @param name Name of the output device, e.g. `indexbraille-v4`.
	-- @param writef Write function. This can be used to override the
	--               @{device:write} method used to output the data.
	-- @name device.get
	--
	get = function (name, writef)
		local dev = lib["dev-" .. name]:clone ()
		if writef ~= nil then
			dev.write = writef
		end
		return dev
	end;
}

return device

