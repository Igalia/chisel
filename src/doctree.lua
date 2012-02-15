---
-- Document tree.
--
-- @todo Describe what the document tree is for.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local M = {}


--- Base document tree element.
--
-- @section element
--
M.element = object:clone
{
	-- Arbitrary data payload. Usage depends on the subclass.
	data = "";

	--- Renders an element to a given output device.
	--
	-- Note that the base class does not implement it and will raise an error.
	--
	-- @param device Output @{device}.
	-- @name element:render
	--
	render = function (self, device)
		error ("unimplemented")
	end;

	--- Checks whether the node has children.
	--
	-- @name element:has_children
	--
	has_children = function (self)
		return self.children and #self.children > 0
	end;

	--- Appends (or inserts at a given position) a node as a new child.
	--
	-- The interpretation of the arguments (position, etc) is the same
	-- as for @{table.insert}.
	--
	-- @return The element itself, to allow chain-calls.
	-- @name element:add_child
	--
	add_child = function (self, ...)
		if self.children == nil then
			self.children = {}
		end
		table.insert (self.children, ...)
		return self
	end;

	--- Walk over a node.
	--
	-- Helper function to walk a node, which calls an *enter function*,
	-- then calls @{element:render} for each child (if any), and finally
	-- calls and an *exit function* on the output device:
	--
	--  * The *enter function* has to be called
	--    <code>begin_<em>name</em></code>.
	--  * The *exit function* has to be called
	--    <code>end_<em>name</em></code>.
	--
	-- For most cases, the @{element:render} method for elements will
	-- just arrange to call @{element:walk} with suitable parameters.
	--
	-- @param name Name used as suffix to derive the names of the
	-- enter and exit function in the output device.
	-- @param device Output device.
	-- @name element:walk
	--
	walk = function (self, name, device)
		local beginf = device["begin_" .. name]
		local endf   = device["end_"   .. name]

		if beginf ~= nil then
			beginf (device, self)
		end

		if self:has_children () then
			for _, child in ipairs (self.children) do
				child:render (device)
			end
		end

		if endf ~= nil then
			endf (device, self)
		end
	end;
}


--- Top-level document element.
--
-- The document element represent a complete document and its attributes.
-- It *must* always be the top-level element in the document tree.
--
-- @section document
--
M.document = M.element:clone
{
	--- Renders a document.
	-- @param device Output @{device}.
	-- @name document:render
	render = function (self, device)
		self:walk ("document", device)
	end;
}


--- Text element.
--
-- Contains a blob of plain text as data payload. The payload is stored in
-- the `data` attribute.
--
-- @section text
--
M.text = M.element:clone
{
	--- Renders text.
	-- @param device Output @{device}.
	-- @name text:render
	render = function (self, device)
		self:walk ("text", device)
	end;
}

return M

