---
-- Character set constants
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

--- Character set constants
--
-- @table charset
--
local M = {
	NUL = "\x00"; -- ASCII null character.
	LF  = "\x0A"; -- ASCII line feed character.
	FF  = "\x0C"; -- ASCII form feed character.
	CR  = "\x0D"; -- ASCII carriage return character.
	ESC = "\x1B"; -- ASCII escape character.
	SPC = "\x20"; -- ASCII space character.
}

return M

