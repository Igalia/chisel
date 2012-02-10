--
-- device.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local strfmt = string.format

local device = object:clone
{
	write = function (self, data)
		io.write (data)
		return self
	end;

	format = function (self, ...)
		self:write (strfmt (...))
		return self
	end;

	create = function (name, writef)
		local dev = lib["dev-" .. name]:clone ()
		if writef ~= nil then
			dev.write = writef
		end
		return dev
	end;
}

return device

