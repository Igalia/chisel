#! /usr/bin/env lua
--
-- chisel.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local isdir = lib.fs.isdir
local listdir = lib.fs.listdir
local basename = lib.fs.basename

local filter_out_commands = {
  ["chisel-ut"] = true;
  ["chisel"] = true;
}

print [[
Usage: chisel -S <command> -- <command arguments...>
The following is a list of the available commands:
]]

for _, name in ipairs (listdir (chisel.libdir .. "/scripts/")) do
  if name:sub (-#".lua") == ".lua" then
    name = name:sub (1, -#".lua"-1)
    if not filter_out_commands[name] then
      print (" - " .. name)
    end
  end
end

print [[

More information on how to use each of the commands can be
obtained by passing "--help" to the command, or by running
it without arguments:

 chisel -S chisel-ppd -- --help
 chisel -S chisel-ppd
]]

