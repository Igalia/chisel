--
-- texttochisel.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local validate_options = lib.ml.safe (lib.loader.validate_options)
local optionformatq = "    %s = %q;"
local optionformats = "    %s = %s;"

if chisel.options["--help"] then
  print [[
Usage: texttochisel [option=value...] < input.txt > output.chsl

Any options eligible to be used in the "options" section of a
Chisel document can be used. Please refer to the documentation
for their reference.
]]
return
end

-- Check whether the process is running as a CUPS filter, and if a file
-- name is given in argv[6], pick that as input file instead of stdin.
--
-- TODO Make this check more robust.
--
local running_on_cups = os.getenv ("CUPS_SERVERROOT") ~= nil and
                        #chisel.argv >= 5

local options
if running_on_cups and chisel.argv[6] ~= nil then
  -- Reassign stdin
  io.input (chisel.argv[6])

  -- CUPS passes the number of copies as 4th argument.
  options = {}
  options.copies = tonumber (chisel.argv[4])

  -- TODO CUPS passes job options in argv[5]
else
  -- Validate options passed in the command line
  local err
  options, err = validate_options (chisel.options)
  if options == nil then
    chisel.die ("texttochisel: %s\n", err)
  end
end

-- header
print ("#!chisel")
print ("-- generated by texttochisel version " .. chisel.version)

-- optoins
print ("options {")
for option, value in pairs (options) do
	local f = type (value) == "string" and optionformatq or optionformats
	print (f:format (option, value))
end
print ("}")

-- contents
print ("document {")
print ("  text {")

for line in io.lines () do
	print (string.format ("    %q,", line .. "\n"))
end

-- footer
print ("  }")
print ("}")

