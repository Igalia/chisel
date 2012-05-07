---
-- Document tree.
--
-- @todo Describe what the document tree is for.
--
-- @copyright 2012 Adrian Perez <aperez@igalia.com>
-- @license Distributed under terms of the MIT license.
--

local M = {}
local tinsert = table.insert

--- Base element.
-- @section base_element

--- Base document tree element.
--
-- The base element provides the framework for the rest of the document tree
-- representation.
--
-- **Attributes**
--
-- * `children`: List of child nodes. To manipulate it, use
--   @{element:child}, @{element:add_child}, @{element:del_child},
--   @{element:has_child} and @{element:has_children}.
--
-- * `data`: Arbitrary data attached to the element. Usually leaf elements
--   (like [text](#Text_element)) use this to store their associated data.
--
-- @table element
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
	-- @function element:render
	--
	render = function (self, device)
		error ("unimplemented")
	end;

	--- Checks whether the node has children.
	--
	-- @function element:has_children
	--
	has_children = function (self)
		return self.children and #self.children > 0
	end;

	--- Checks whether an element is a children of another.
	--
	-- @param element Element to be checked.
	-- @return Whether *element* is a children.
	-- @function element:has_child
	--
	has_child = function (self, element)
		if self:has_children () then
			for _, v in ipairs (self.children) do
				if v == element then
					return true
				end
			end
		end
		return false
	end;

	--- Return a particular child, of a list of children
	--
	-- @param index Index of the element to obtain. If not given, the complete
	-- list of children elements is returned *(Optional)*.
	-- @return List, element, or `nil` if the requested element is not
	-- a child.
	-- @function element:child
	--
	child = function (self, index)
		if index == nil then
			return self.children or {}
		end
		return self.children[index]
	end;

	--- Removes a children from an element.
	--
	-- @param element Element to be removed as child. If the element is not
	-- a child, no error is produced. Also, it is possible to pass a numeric
	-- index instead of the element reference.
	-- @return The element itself, to allow chain-calls.
	-- @function element:del_child
	--
	del_child = function (self, element)
		local index = nil
		if self:has_children () then
			if type (element) == "number" then
				index = element
			else
				for i, v in ipairs (self.children) do
					if v == element then
						index = i
						break
					end
				end
			end
			if index ~= nil then
				table.remove (self.children, index)
			end
		end
		return self
	end;

	--- Appends (or inserts at a given position) a node as a new child.
	--
	-- @param element Element to be added as a child.
	-- @param position Position *(Optional)*.
	-- @return The element itself, to allow chain-calls.
	-- @function element:add_child
	--
	add_child = function (self, element, position)
		if self.children == nil then
			self.children = {}
		end
		if position ~= nil then
			tinsert (self.children, position, element)
		else
			self.children[#self.children+1] = element
		end
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
	-- @function element:walk
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


--- Top-level elements
-- @section toplevel_elements

--- Document element.
--
-- The document element represent a complete document and its attributes.
-- It *must* always be the top-level element in the document tree.
--
-- @table document
--
M.document = M.element:clone
{
	--- Renders a document.
	-- @param device Output @{device}.
	-- @function document:render
	render = function (self, device)
		self:walk ("document", device)
	end;
}


--- Grouping elements
-- @section grouping_elements

--- Document part.
--
-- A document part is a fragment of a document to which different options
-- that the global, document-level ones.
--
-- @table part
--
M.part = M.element:clone
{
  --- Renders a part.
  -- @param device Output @{device}.
  -- @function part:render
  render = function (self, device)
    self:walk ("part", device)
  end;
}

--- Content elements
-- @section content_elements

--- Text element.
--
-- Contains a blob of plain text as data payload. The payload is stored in
-- the `data` attribute.
--
-- @table text
--
M.text = M.element:clone
{
	--- Renders text.
	-- @param device Output @{device}.
	-- @function text:render
	render = function (self, device)
		self:walk ("text", device)
	end;
}


--- Raw data element.
--
-- Contains a blob of raw data, which will be sent as-is to the device.
-- Note that the contents of the `data` will be sent to the device if
-- the name of the output device specified in the `device` attribute
-- matches that of the final destination.
--
-- **Attributes:**
--
-- * `device`: Name of the device the raw data applies to.
-- * `data`: Raw data to be sent to the device.
--
-- @table raw
--
M.raw = M.element:clone {
	--- Reders raw data.
	-- @param device Output @{device}.
	-- @function raw:render
	render = function (self, device)
		if self.device == device.name then
			device:write (self.data)
		end
	end;
}

return M

