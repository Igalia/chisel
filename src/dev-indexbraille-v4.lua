--
-- indexbraille-v4.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local cset = lib.charset

--- Output device for Index Braille devices using the V4 protocol
--
-- @class table
-- @name ibv4
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
-- @param ... Format string and its argument. Those are passed as-is
--            to <tt>device:format()</tt>.
--
function ibv4:esc (...)
	self:write (cset.ESC)
	self:format (...)
	self:write (";")
end

function ibv4:begin_document (node)
	self:esc ("DVchisel-v%s", chisel.version)
end

function ibv4:begin_text (node)
	self:write (node.data)
end

return ibv4

