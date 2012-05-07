--
-- chisel-ut.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local lunit = lib.lunit

for _, filename in ipairs (chisel.argv) do
  print ("loading: " .. filename)
  local ut_env = lunit.module (filename, "seeall")
  local chunk  = assert (loadfile (filename, "bt", ut_env))
  chunk ()
end

io.stdout:write ("running:")
local stats = lunit.run ()
if stats.errors > 0 or stats.failed > 0 then
  os.exit (1)
end
