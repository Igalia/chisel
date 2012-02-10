--
-- doctree.lua
-- Copyright (C) 2012 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local M = {}


--
-- Base doctument tree element.
--
M.element = object:clone
{
	-- Arbitrary data payload. Usage depends on the subclass.
	--
	data = "";

	-- Renders an element to a given output device. Note that the base class
	-- does not implement it and will raise an error.
	--
	render = function (self, dev)
		error ("unimplemented")
	end;

	-- Checks whether the node has children.
	--
	has_children = function (self)
		return self.children and #self.children > 0
	end;

	-- Appends (or inserts at a given position) a node as a new child.
	-- The interpretation of the arguments (position, etc) is the same
	-- as for table.insert()
	--
	-- The node itself is returned, to allow chaining operations.
	--
	add_child = function (self, ...)
		if self.children == nil then
			self.children = {}
		end
		table.insert (self.children, ...)
		return self
	end;

	-- Helper function to walk a node, which calls an "enter function",
	-- then calls :render() for each child (if any), and finally calls
	-- and an "exit function" on the output device.
	--
	-- For most cases, the :render() method for elements will just
	-- arrange to call :walk() with suitable parameters.
	--
	walk = function (self, nodename, dev)
		local beginf = dev["begin_" .. nodename]
		local endf   = dev["end_"   .. nodename]

		if beginf ~= nil then
			beginf (dev, self)
		end

		if self:has_children () then
			for _, child in ipairs (self.children) do
				child:render (dev)
			end
		end

		if endf ~= nil then
			endf (dev, self)
		end
	end;
}


--
-- Top-level document element.
--
M.document = M.element:clone
{
	render = function (self, dev)
		self:walk ("document", dev)
	end;
}


--
-- Text element. Contains a blob of plain text as data payload.
--
M.text = M.element:clone
{
	render = function (self, dev)
		self:walk ("text", dev)
	end;
}

return M

