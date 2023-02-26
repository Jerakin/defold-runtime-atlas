-- Naive atlas packing algorithm to serve as an example, mainly serving
-- as an example of an algorithm you can use with dynamic-atlas.lua
-- Algorithms expects a table of images where an image is a table that
-- have w and h {w=64, h=32}, representing widht and height respectivly.
--
-- The algoritms jobb is to loop through the list of images and add x and y
-- which are the positions on the atlas.
--
-- Adopted from this article https://www.david-colson.com/2020/03/10/exploring-rect-packing.html

local M = {}

local function height_sort(a, b)
	return a.h > b.h
end


--- Algorithm that packs adds positions (x, y) to a Image table
-- @param list_of_textures Table of an Image table with a minimum of w and h
-- @param width Width of the atlas it will be packed on
-- @param height Height of the atlas it will be packed on
function M.pack(list_of_textures, width, height)
	assert(width, "Provide texture width")
	assert(height, "Provide texture height")
	table.sort(list_of_textures, height_sort)

	local xPos = 0;
	local yPos = 0;
	local largestHThisRow = 0;

	-- Loop over all the rectangles
	for i in pairs(list_of_textures) do
		local rect = list_of_textures[i]
		-- If this rectangle will go past the width of the image
		-- Then loop around to next row, using the largest height from the previous row
		if ((xPos + rect.w) > width) then
			yPos = yPos + largestHThisRow;
			xPos = 0;
			largestHThisRow = 0;
		end

		-- If we go off the bottom edge of the image, then we've failed
		if ((yPos + rect.h) > height) then
			return
		end
		
		-- This is the position of the rectangle
		rect.x = xPos;
		rect.y = yPos;

		-- Move along to the next spot in the row
		xPos = xPos + rect.w;

		-- Just saving the largest height in the new row
		if (rect.h > largestHThisRow) then
			largestHThisRow = rect.h;
		end
	end

	return list_of_textures
end

return M