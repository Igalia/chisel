#! /usr/bin/env lua
--
-- chisel-ppd.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local device = lib.device


local function cmd_cat (device_id)
  -- It is possible that the *CUPS* driver name is passed as a prefix.
  -- If that is the case, remove it before calling device.get()
  if device_id:sub (1, # "chisel-ppd:") == "chisel-ppd:" then
    device_id = device_id:sub (# "chisel-ppd:" + 1)
  end
  io.write (device.get (device_id):ppd ())
end


local function cmd_list ()
  local all = device.list ("*")
  if chisel.options.plain then
    print (table.concat (all, "\n"))
  else
    if chisel.options.simple then
      local lfmt = "%-26s %s %s"
      for _, item in ipairs (all) do
        local d = device.get (item)
        print (lfmt:format (item, d.manufacturer, d.model))
      end
    else
  	  local lfmt = '"chisel-ppd:%s" en "%s" "%s %s/chisel" "%s"'
	    for _, item in ipairs (all) do
	      local d = device.get (item)
	      print (lfmt:format (item,
	                          d.manufacturer,
	                          d.manufacturer,
	                          d.model,
	                          d.ieee1284_id))
      end
    end
	end
end


local cmds = {
	cat  = {
		cmd_func = cmd_cat;
		synopsis = "cat <device-id>";
		longdesc = "Generate a PPD file for the given device on stdout.";
	};
	list = {
		cmd_func = cmd_list;
		synopsis = "list [plain]";
		longdesc = "List all supported devices";
	};
}


if #chisel.argv == 0 or chisel.argv[1] == "help" or chisel.options["--help"] then
	io.stderr:write ("Usage:\n")
	for name, cmd in pairs (cmds) do
		io.stderr:write ((" chisel-ppd %s\n"):format (cmd.synopsis))
	end
	io.stderr:write ("\nCommands:\n")
	for name, cmd in pairs (cmds) do
		io.stderr:write ((" %-20s %s\n"):format (cmd.synopsis, cmd.longdesc))
	end
	os.exit (1)
end

local cmd = cmds[chisel.argv[1]]
if not cmd then
	io.stderr:write (("No such command \"%s\"\n"):format (chisel.argv[1]))
	os.exit (2)
end

cmd.cmd_func (table.unpack (chisel.argv, 2))

