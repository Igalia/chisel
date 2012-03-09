--
-- texttochisel.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local validate_options = lib.ml.safe (lib.loader.validate_options)
local optionformatq = "    %s = %q;"
local optionformats = "    %s = %s;"

-- Validate options passed in the command line
local options, err = validate_options (chisel.options)
if options == nil then
	chisel.die ("texttochisel: %s\n", err)
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

