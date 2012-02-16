---
-- Descriptions for printers/devices.
--
-- This module provides functionality to describe the capabilities
-- of actual devices. Also, it supports generation of [PPD
-- files](http://en.wikipedia.org/wiki/PostScript_Printer_Description)
-- suitable to be used with [CUPS](http://cups.org)
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local sprintf  = string.format
local tconcat  = table.concat
local tinsert  = table.insert
local tostring = tostring
local ipairs   = ipairs
local pairs    = pairs
local type     = type


local function ppd_attribute (ppdname, attrname, optional)
	return function (data)
		if data[attrname] == nil then
			if optional then
				return sprintf ("*%% Attribute %s (%s) is undefined", ppdname, attrname)
			end
			error ("No attribute '" .. attrname .. "' in printer data", 2)
		end
		return sprintf ("*%s: \"%s\"", ppdname, data[attrname])
	end
end


local function ppd_template_options (data)
	return "" -- TODO
end


-- Template for generated PPD files:
--
--	* Strings are emitted as-is, followed by a newline character.
--	* Functions are called passing the printer data object as only
--	  argument. They should return a string, which will get emitted
--	  as output.
--
local ppd_template = {
	-- Standard PPD header, and info blob
	[[*PPD-Adoble: "4.3"]],
	[[*% PPD generated by chisel-ppd version ]] .. chisel.version;

	-- XXX Those hardcoded values should go away at some point!
	[[*LanguageVersion: English]],
	[[*LanguageEncoding: Latin1]],

	-- Manufacturer, model names, etc
	ppd_attribute ("1284DeviceID", "ieee1284_id", true);
	ppd_attribute ("Manufacturer", "manufacturer");
	ppd_attribute ("ModelName",    "model");

	-- Extra redundant model infos which can be derived from the above
	function (data)
		return sprintf ("*Product: \"(%s)\"\n\z
			               *ShortNickName: \"%s\"\n\z
			               *NickName: \"%s %s\"",
										 data.model, data.model,
										 data.manufacturer, data.model)
	end;

	-- Color model
	function (data)
		local colors = data.colorspace
		local retval = "*ColorDevice: False\n\z
			              *DefaultColorSpace: Gray"

		if colors == nil then
			colors = "gray"
		end

		-- For the moment, only grayscale is supported. Anything else
		-- causes an error to be raised.
		if colors ~= "gray" and colors ~= "grey" then
			error ("Color space '" .. tostring (colors) .. "' is not supported")
		end
		return retval
	end;

	-- PPD file versions. For the file version, pick chisel.version, and add
	-- the revision number from the printer data in between parentheses.
	[[*FormatVersion: "4.3"]],
	[[*PSVersion: "(3000.000) 100"]],
	function (data)
		return sprintf ("*FileVersion: \"%s(%i)\"",
		                chisel.version,
		                data.revision or 0)
	end;

	-- Generate options. This deserves a separate function...
	ppd_template_options;
}


--- Printer option.
--
-- Describes a printer option. The following attributes can (and should) be
-- defined:
--
--  * `name`: Name of the option (mandatory).
--  * `ppd_name`: Name of the option in a PPD file (optional, if different
--    from `name`).
--  * `ppd_type`: Type of the PPD option (e.g. `PickOne`, mandatory).
--  * `desc`: Long description suited for displaying to users (mandatory).
--  * `ppd_desc`: Long description of the option, to use in PPDs (optional,
--     if different from `desc`).
--  * `default`: Default value (optional).
--  * `ppd_default`: Attribute used in the PPD to define the default value
--    (optional).
--  * `values`: Possible values for the option (optional, needed for
--    `PickOne` options).
--
-- @section option
--
local printeroption = object:clone
{
	--- Generate a code snippet suitable for inclusion in a PPD.
	--
	-- @name printeroption:ppd
	--
	ppd = function (self)
		local name = self.ppd_name or self.name
		local desc = self.ppd_desc or self.desc or name
		local r = { sprintf ("*OpenUI *%s/%s: %s", name, desc, self.ppd_kind) }
		if self.default then
			if self.ppd_default then
				tinsert (r, sprintf ("*%s: %s", self.ppd_default, self.default))
			else
				tinsert (r, sprintf ("*Default%s: %s", name, self.default))
			end
		end
		if self.values then
			for k, v in pairs (self.values) do
				tinsert (r, sprintf ("*%s %s/%s: \"\"", name, k, v))
			end
		end
		tinsert (r, sprintf ("*CloseUI: *%s\n", name))
		return tconcat (r, "\n")
	end;
}


local option_class =
{
	pagesize = printeroption:clone
	{
		name     = "PageSize";
		desc     = "Media Size";
		ppd_kind = "PickOne";
		values   = {};
	};
}


--- Printer data base class.
--
-- The `printerdata` is a base class used to describe printers and similar
-- devices.
--
-- @todo Describe fields recognized, and how to make a minimal, valid
-- printer data file.
--
-- @section printerdata
--
local printerdata = object:clone
{
	--- Generates PPD data.
	--
	-- @return String wiht the contents of the PPD.
	-- @name printerdata:ppd
	--
	ppd = function (self)
		local result = {}
		for _, v in ipairs (ppd_template) do
			if type (v) == "function" then
				v = v (self)
			else
				v = tostring (v)
			end
			tinsert (result, v)
		end
		return tconcat (result, "\n")
	end;

	--- Obtain the data for a device given its name.
	--
	-- @param name Device name in `manufacturer/model` form.
	-- @name printerdata.get
	--
	get = function (name)
		return require("data/" .. name)
	end;

	--- Create a new device description by extending another.
	--
	-- To create a device description from scratch, do:
	--
	-- 	return lib.printerdata:extend {
	--		manufacturer = "ACME";
	--		model = "Print-O-Matic";
	--		-- ...
	-- 	}
	--
	-- To extend an existing `acme/print-o-matic` device with additional
	-- information, do:
	--
	-- 	return lib.printerdata:extend "acme/print-o-matic" {
	--		model = "Print-O-Matic Extended";
	--		-- ...
	--	}
	--
	-- @param arg Device description to extend, as a `manufacturer/model`
	-- string. If no argument (or `nil`) is given, a new device description
	-- is created without extending an existing one.
	--
	-- @return When a string is passed, a function that accepts a table
	-- as single argument and returns a new object is returned. When no
	-- arguments are passed, this is equivalent to clone the base object
	-- and extend it.
	--
	-- @name printerdata:extend
	--
	extend = function (self, arg)
		if type (arg) == "string" then
			local base = require("data/" .. arg)
			return function (t)
				return base:clone (t)
			end
		else
			return object.extend (self:clone (), arg)
		end
	end;
}


return printerdata

