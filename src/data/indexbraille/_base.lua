#! /usr/bin/env lua
--
-- _base.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

manufacturer = "Index Braille"
renderer     = "indexbraille-v4"
throughput   = 4

options = {
	pagesize = {
		default = "Letter";

		-- Standard sizes
		"Letter";
		"Legal";
		"A4";
		"A3";
		"A5";
		-- Index Braille specific paper sizes
		["110x115"] = "11x11.5";
		["110x120"] = "11x12";
		["110x170"] = "11x17";
		["115x110"] = "11.5x11";
		["A4TF"   ] = "A4 Tractor Feed";
	};

	duplex = {
		default = "None";

		-- Possible values
		"None";
		"NoTumble";
	};
}

-- Printing areas and margins for the supported paper sizes
-- Paper size does not need to be specified for standard ones.
media = {
	Letter = { margins={ 18; 36; 594;         756        } };
	Legal  = { margins={ 18; 36; 594;         972        } };
	A3     = { margins={ 18; 36; 823.889765; 1154.551180 } };
	A4     = { margins={ 18; 36; 577.275590;  805.889765 } };
	A5     = { margins={ 18; 36; 401.527560;  559.275590 } };

	-- Non-standard paper sizes: specify both size and margins
	["110x115"] = { size={ 792;  828 }; margins={ 18; 36; 774;  756 } };
	["110x120"] = { size={ 782;  864 }; margins={ 18; 36; 774;  828 } };
	["110x170"] = { size={ 792; 1224 }; margins={ 18; 36; 775; 1188 } };
	["115x110"] = { size={ 828;  792 }; margins={ 18; 36; 756;  774 } };
	["A4TF"   ] = { size={ 594;  846 }; margins={ 18; 36; 576;  810 } };
}
