--
-- indexbraille-v4.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local cset = lib.charset
local ibv4 = lib.device:clone ()

-- Output device information
ibv4.name = "indexbraille-v4"
ibv4.description = [[\
Output to Index Braille embossers using version 4 of the protocol.
]]

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

