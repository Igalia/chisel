#! /usr/bin/env lua
--
-- chisel-ppd.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local function cmd_cat (device_id)
  -- It is possible that the driver name is passed as a prefix. If that is
  -- the case, remove it before calling printerdata.get()
  if device_id:sub (1, # "chisel-ppd:") == "chisel-ppd:" then
    device_id = device_id:sub (# "chisel-ppd:" + 1)
  end
  io.write (lib.printerdata.get (device_id):ppd ())
end


local function cmd_list ()
	local lfmt = '"chisel-ppd:%s/%s" en "%s" "%s %s/chisel" "%s"'
	for _, manufacturer in ipairs (fs.listdir (chisel.libdir .. "/data")) do
		local manufacturer_path = chisel.libdir .. "/data/" .. manufacturer
		if manufacturer:sub (1, 1) ~= "_" and fs.isdir (manufacturer_path) then
			for _, model in ipairs (fs.listdir (manufacturer_path)) do
				if model:sub (1, 1) ~= "_" then
					model = model:sub (1, -5) -- Remove ".lua" suffix
					if chisel.options.plain then
						print (manufacturer .. "/" .. model)
					else
						local d = lib.printerdata.get (manufacturer .. "/" .. model)
						print (lfmt:format (manufacturer, model,
						                    d.manufacturer,
						                    d.manufacturer, d.model,
						                    d.ieee1284_id or ""))
					end
				end
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


if #chisel.argv == 0 or chisel.argv[1] == "help" then
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

