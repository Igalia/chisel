--
-- chisel.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

-- This is the main chisel filter program. Converst a chisel document
-- tree to something that a particular embosser would understand.

local get_device = lib.ml.safe (lib.device.get)

-- Get output device. This is done as first step, so it is possible
-- to tell the user early whether the chosen device is not available.
--
if chisel.options.device then
  dev, err = get_device (chisel.options.device)
  if dev == nil then
    if chisel.loglevel > 0 then
      chisel.die ("Unknown device name %q\n%s\n",
                  chisel.options.device or "",
                  err)
    else
      chisel.die ("Unknown device name %q\n",
                  chisel.options.device or "")
    end
  end
else
  chisel.die ("Could not guess output device\n")
end

debug ("device: %s (%s)\n", dev, dev.name)

-- Parse stdin
doc, err = lib.loader.parse ()
if doc == nil then
  if chisel.loglevel > 0 then
    chisel.die ("Could not parse input document\n")
  else
    chisel.die ("Could not parse input document\n%s\n", err)
  end
end

-- Output document to the device
doc:render (dev)

