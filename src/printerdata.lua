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
local loadfile = loadfile
local tostring = tostring
local ipairs   = ipairs
local pairs    = pairs
local pcall    = pcall
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


-- Template for generated PPD files:
--
--	* Strings are emitted as-is, followed by a newline character.
--	* Functions are called passing the printer data object as only
--	  argument. They should return a string, which will get emitted
--	  as output.
--
local ppd_template = {
	-- Standard PPD header, and info blob
	[[*PPD-Adobe: "4.3"]];
	[[*%]];
	[[*% PPD generated by chisel-ppd version ]] .. chisel.version;
	[[*%]];

	-- XXX Those hardcoded values should go away at some point!
	[[*LanguageVersion: English]],
	[[*LanguageEncoding: Latin1]],

	-- Manufacturer, model names, etc
	ppd_attribute ("1284DeviceID", "ieee1284_id", true);
	ppd_attribute ("Manufacturer", "manufacturer");
	ppd_attribute ("ModelName",    "model");
	ppd_attribute ("Throughput",   "throughput", true);

	-- Extra redundant model infos which can be derived from the above
	function (data)
		return sprintf ("*Product: \"(%s)\"\n\z
			               *ShortNickName: \"%s\"\n\z
			               *NickName: \"%s %s\"",
										 data.model, data.model,
										 data.manufacturer, data.model)
	end;

	-- Filter command, for use with CUPS
	function (data)
		if data.output then
			return sprintf ("*cupsVersion: 1.0\n\z
			                 *cupsFilter: \"application/x-chisel-text 0 chisel device=%s\"",
			                 data.output)
		else
			return "*% No 'output' option defined, skipping CUPS attributes."
		end
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
	function (data)
		if not data.options then
			return "*% No options defined"
		end

		local result = {}
		for k, opt in pairs (data.options) do
			debug ("%s, %s, %s\n", k, opt, opt.ppd)
			tinsert (result, sprintf ("\n*%% options.%s", k))
			tinsert (result, opt:ppd ())
		end

		return tconcat (result, "\n")
	end;
}

--- Built-in option values
-- @section buitin_values

--- Built-in page sizes
local builtin_pagesizes =
{
	A3     = "A3";        -- Standard DIN A3 paper
	A4     = "A4";        -- Standard DIN A4 paper
	A5     = "A5";        -- Standard DIN A5 paper
	Legal  = "US Legal";  -- Standard US Legal paper
	Letter = "US Letter"; -- Standard US Letter paper
}

--- Built-in duplex operation values
local builtin_duplex =
{
	None     = "Off";               -- Duplex is disabled
	Tumble   = "Top Edge Binding";  -- Turn page on short (top) side
	NoTumble = "Left Edge Binding"; -- Turn page on long (left) side
}

--- Built-in media sizes
local builtin_media =
{
	Letter = { size={ 612;         792        } }; -- Standard US Letter paper
	Legal  = { size={ 612;        1008        } }; -- Standard US Legal paper
	A3     = { size={ 841.889765; 1190.551180 } }; -- Standard DIN A3 paper
	A4     = { size={ 595.275590;  841.889765 } }; -- Standard DIN A4 paper
	A5     = { size={ 419.527560;  595.275590 } }; -- Standard DIN A5 paper
}


--- Printer data.
-- @section printer_data

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
--  * `ui`: The option does have an UI, i.e. in the generated PPD
--     there will be both an `*OpenUI` and a `*CloseUI` statement
--     for the option. By default it is set to `true`.
--
-- @table printeroption
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
		local r = {}

		if self.comment then
			tinsert (r, sprintf ("*%% %s", self.comment))
		end

		if self.ui then
			tinsert (r, sprintf ("*OpenUI *%s/%s: %s", name, desc, self.ppd_kind))
		end

		if self.default then
			if self.ppd_default then
				tinsert (r, sprintf ("*%s: %s", self.ppd_default, self.default))
			else
				tinsert (r, sprintf ("*Default%s: %s", name, self.default))
			end
		end

		if self.values then
			for k, v in pairs (self.values) do
				if type (v) == "table" then
					tinsert (r, sprintf ("*%s %s/%s: \"%s\"", name, k, v[1], v[2]))
				else
					tinsert (r, sprintf ("*%s %s/%s: \"\"", name, k, v))
				end
			end
		end

		if self.ui then
			tinsert (r, sprintf ("*CloseUI: *%s\n", name))
		end

		return tconcat (r, "\n")
	end;

	-- Enabled by default.
	ui = true;
}


local option_class =
{
	pagesize = printeroption:clone
	{
		name     = "PageSize";
		desc     = "Media Size";
		ppd_kind = "PickOne";
	};

	pageregion = printeroption:clone
	{
		name     = "PageRegion";
		ppd_kind = "PickOne";
	};

	duplex = printeroption:clone
	{
		name     = "Duplex";
		ppd_kind = "PickOne";
	};

	paperdimension = printeroption:clone { name = "PaperDimension"; ui = false };
	imageablearea  = printeroption:clone { name = "ImageableArea" ; ui = false };
}


local function _printerdata_get (name)
	local base = {}
	local data = {}
	local path = sprintf ("%s/data/%s.lua", chisel.libdir, name)

	-- Load the chunk, if there is some error, return nil+error
	local chunk, err = loadfile (path, "t", data)
	if chunk == nil  then
		return nil, e
	end
	chunk, err = pcall (chunk)

	if not chunk then
		return nil, err
	end

	if data.base then
		base, err = _printerdata_get (data.base)
		if base == nil then
			return nil, err
		end
	end

	-- TODO Make merging of items better using recursive merge.
	for k, v in pairs (data) do
		base[k] = v
	end

	return base
end


local function option_gather_function (name, builtins, optclass)
	return function (self, ps)
		if type (ps) ~= "table" then
			error (name .. "s must be a table/list")
		end

		local vals = {}
		for k, v in pairs (ps) do
			if type (k) == "number" then
				-- Numeric index, pick built-in value
				if builtins[v] == nil then
					error ("unknown bultin " .. name .. " '" .. v .. "'")
				end
				debug (" adding builtin %s '%s'\n", name, v)
				vals[v] = builtins[v]
			else
				-- Pick value as-is
				debug (" adding %s '%s' (%s)\n", name, k, v)
				vals[k] = v
			end
		end

		local defval = vals.default
		vals.default = nil

		return optclass:clone { values = vals, default = defval }
	end
end


local function calculate_iarea_and_paperdim (psize, media)
	local iarea = {}
	local ppdim = {}

	for name, attributes in pairs (media) do
		if not attributes.margins then
			error ("no margins specified for media '" .. name .. "'")
		end

		iarea[name] = attributes.margins

		if attributes.size then
			ppdim[name] = attributes.size
		elseif builtin_media[name] ~= nil then
			ppdim[name] = builtin_media[name].size
		else
			error ("size not specified for media '" .. name .. "'")
		end

		iarea[name] = { psize.values[name];
			              sprintf ("%.6f %.6f %.6f %.6f", table.unpack (iarea[name])) }
		ppdim[name] = { psize.values[name];
	                  sprintf ("%.6f %.6f", table.unpack (ppdim[name])) }
	end

	return option_class.imageablearea:clone  { default=psize.default; values=iarea },
	       option_class.paperdimension:clone { default=psize.default; values=ppdim }
end


--- Printer data base class.
--
-- The `printerdata` is a base class used to describe printers and similar
-- devices.
--
-- @todo Describe fields recognized, and how to make a minimal, valid
-- printer data file.
--
-- @table printerdata
--
local printerdata = object:clone
{
	_init = function (self)
		debug ("printerdata:_init: %s/%s\n", self.manufacturer, self.model)

		if self.options then
			for k, v in pairs (self.options) do
				local opt_init_func = self["_init_option_" .. k]
				debug ("printerdata:_init_option_%s: %s\n", k, opt_init_func)
				if opt_init_func then
					self.options[k] = opt_init_func (self, v)
				end
			end

			if not self.options.pagesize then
				error ("no options.pagesize defined")
			end

			-- If there is no "pageregion" options, create one by copying from
			-- an existing "pagesize" one.
			if self.options.pageregion == nil then
				self.options.pageregion = option_class.pageregion:clone {
					values  = self.options.pagesize.values,
					default = self.options.pagesize.default,
					comment = "Note: copied from options.pagesize",
				}
			end
		end

		if self.media then
			self.options.imageablearea, self.options.paperdimension =
				calculate_iarea_and_paperdim (self.options.pagesize, self.media)
		end

		return self
	end;

	_init_option_duplex = option_gather_function ("duplex mode",
	                                              builtin_duplex,
	                                              option_class.duplex);

	_init_option_pagesize = option_gather_function ("page size",
	                                                builtin_pagesizes,
	                                                option_class.pagesize);

	_init_option_pageregion = option_gather_function ("page region",
	                                                  builtin_pagesizes,
	                                                  option_class.pageregion);

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
}


--- Obtain the data for a device given its name.
--
-- @param name Device name in `manufacturer/model` form.
-- @function printerdata.get
--
function printerdata.get (name)
	return printerdata:clone (_printerdata_get (name))
end;


return printerdata
