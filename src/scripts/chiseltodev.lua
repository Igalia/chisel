--
-- chisel.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

-- This is the main chisel filter program. Converst a chisel document
-- tree to something that a particular embosser would understand.

local get_device = lib.ml.safe (lib.device.get)

-- Check whether the process is running as a CUPS filter, and if a file
-- name is given in argv[6], pick that as input file instead of stdin.
--
local running_on_cups = os.getenv ("CUPS_SERVERROOT") ~= nil and
                        #chisel.argv >= 5

-- Read stdin by default.
local input_file = nil

-- Set of options which override document options.
local options_overrides = {}


if running_on_cups and chisel.argv[6] ~= nil then
  input_file = chisel.argv[6]

  -- CUPS passes the number of copies as 4th argument.
  options_overrides.copies = tonumber (chisel.argv[4])

  -- TODO CUPS passes more job options in argv[5]
end


-- Get output device. This is done as first step, so it is possible
-- to tell the user early whether the chosen device is not available.
--
local dev, err
if chisel.options.device or os.getenv ("CHISEL_DEVICE") ~= nil then
  local devname = chisel.options.device or os.getenv ("CHISEL_DEVICE") or ""
  dev, err = get_device (devname)
  if dev == nil then
    if chisel.loglevel > 0 then
      chisel.die ("Unknown device name %q\n%s\n", devname, err)
    else
      chisel.die ("Unknown device name %q\n", devname)
    end
  end
else
  -- Try to autodetect the device by scraping the PPD file from CUPS.
  --
  if running_on_cups then
    -- Check first whether there is a "PPD" environment variable
    local remove_ppd = false
    local ppd_path = os.getenv ("PPD")
    local ppd_text = nil

    -- Get PPD from server. It is needed to remove it afterwards.
    if not ppd_path and has_cups then
      local printer_name = os.getenv ("PRINTER")
      if printer_name then
        ppd_path = cups.get_ppd (printer_name)
        remove_ppd = true
      end
    end

    if ppd_path then
      debug ("scraping PPD file '%s'\n", ppd_path)

      local ppd_file = assert (io.open (ppd_path, "rb"))
      ppd_text = ppd_file:read ("*a")
      ppd_file:close ()

      if remove_ppd then
        os.remove (ppd_path)
      end

      local output_mode = lib.printerdata.output_mode_from_ppd (ppd_text)
      debug ("output mode (from CUPS-supplied PPD): %s\n", output_mode)
      dev, err = get_device (output_mode)
      if dev == nil then
        debug ("coult not get device: %s (continuing...)\n", err)
      end
    end
  end

  -- Try to autodetect the connected device by inquiring CUPS.
  --
  if dev == nil and chisel.has_cups then
    local device_id = lib.cups.get_device_id ()
    debug ("device id (from CUPS): '%s'\n", device_id)

    if device_id ~= nil then
      -- FIXME This is horribly ugly! We are traversing all supported devices
      -- for the solely purpose if checking whether one of them corresponds to
      -- the device id from CUPS!
      --
      for _, devname in ipairs (lib.printerdata.list ("*")) do
        local tmpdev
        tmpdev, err = lib.printerdata.get (devname)
        if tmpdev ~= nil then
          if tmpdev.ieee1284_id == device_id then
            dev, err = get_device (tmpdev.output)
            break
          end
        else
          debug ("Error while getting data for '%s'\n", devname)
        end
      end

      if dev == nil then
        chisel.die ("Device with IEEE1284 ID '%s' is unsupported\n", device_id)
      end
    end
  end
end


-- If control reaches here without actually having selected a device, assume
-- that autodetection is not possible, and inform the user about what to do.
--
if dev == nil then
  chisel.die ("Could not guess output device, you can either:\n" ..
              " - Pass 'device=...' in the command line.\n" ..
              " - Define the CHISEL_DEVICE environment variable.\n")
end

debug ("device: %s (%s)\n", dev, dev.name)


doc, err = lib.loader.parse (input_file)
if doc == nil then
  if chisel.loglevel > 0 then
    chisel.die ("Could not parse input document\n")
  else
    chisel.die ("Could not parse input document\n%s\n", err)
  end
end

-- Apply the extra options
options_overrides, err = lib.loader.validate_options (options_overrides)
if options_overrides == nil then
  chisel.die ("Invalid options: %s", err)
end

for name, value in pairs (options_overrides) do
  doc.options[name] = value
end

-- Output document to the device
doc:render (dev)

