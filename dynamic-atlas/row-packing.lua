local M = {}



local function height_sort(a, b)
	return a.h > b.h
end

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