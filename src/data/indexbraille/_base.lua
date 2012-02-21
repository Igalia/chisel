#! /usr/bin/env lua
--
-- _base.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

manufacturer = "Index Braille"
output       = "indexbraille-v4"

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
}
