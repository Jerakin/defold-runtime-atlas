local rowpacking = require "runtime-atlas/row-packing"

local M  = {}

-- You can provide your own packing algorithm and set it with this property.
M.algorithm = rowpacking.pack

-- Loading images on disk loads the buffers as strings, here we convert them into defolds buffer format
local function convert_string_buffer_to_buffer(blob)
	-- string with binary pixel data in rgba format
	local size = #blob / 4

	-- create rgba buffer and get the stream where the pixcels should be stored
	local new_buffer = buffer.create( size, { {name=hash("rgba"), type=buffer.VALUE_TYPE_UINT8, count=4 } })
	local stream = buffer.get_stream(new_buffer, hash("rgba"))

	-- copy pixels to stream in buffer
	local i = 1
	while i < #blob do
		stream[i] = string.byte(blob, i) -- r
		i = i + 1

		stream[i] = string.byte(blob, i) -- g
		i = i + 1

		stream[i] = string.byte(blob, i) -- b
		i = i + 1

		stream[i] = string.byte(blob, i) -- a
		i = i + 1
	end
	return new_buffer
end

-- String end_swith
local function ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end


-- String split
local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end


-- Get the filename (image.png) when given a complete path 
function get_filename(path)
	local parts = split(path, "/")
	return parts[#parts]
end

-- Loads all images into memory and saves some additional data needed for packing.
-- We need to load the images to get the width and height of them, for our packing algorithm.
local function get_package_data(list_of_textures, options)
	local pack_data = {}
	for i in pairs(list_of_textures or {}) do
		local image_path = list_of_textures[i]
		local file = io.open(image_path, "rb")
		if file then
			local buffer = file:read("*all")
			file:close()
			local img = image.load(buffer, {flip_vertically=true, premultiply_alpha=options.premultiply_alpha or false})
			table.insert(pack_data, {name=get_filename(image_path), buffer=convert_string_buffer_to_buffer(img.buffer), w=img.width, h=img.height})
		end
	end
	return pack_data
end


local function get_atlas_parameters(image, atlas_params)
	table.insert(atlas_params.animations, {
		id          = image.name,
		width       = image.w,
		height      = image.h,
		-- We have to increase the frame range, this is what decided which geometies belong to this id
		frame_start = #atlas_params.animations+1,
		frame_end   = #atlas_params.animations+2,
	})
	table.insert(atlas_params.geometries, {
		vertices  = {
			0,   0,
			0,   image.h,
			image.w, image.h,
			image.w, 0
		},
		uvs = {
			-- The UVs are in texture space so we have to make sure to update it to take our position on
			-- the atlas into account.
			image.x,   image.y,
			image.x,   image.y + image.h,
			image.x + image.w, image.y + image.h,
			image.x + image.w, image.y
		},
		-- We are adding our images as rectangles so we don't have to touch the indices
		indices = {0,1,2,0,2,3}
	})
	return atlas_params
end

-- Here we set the buffer data onto the actual texture as well as calculate the data needed for
-- our atlas to map the frames and ids to a position on the texture.
local function set_texture_data(texture_id, pack_data, height)
	local set_params
	local atlas_params = {animations={}, geometries={}, texture = texture_id}

	for i in pairs(pack_data) do
		local img = pack_data[i]
		set_params = {
			width=img.w,
			height=img.h,
			x=img.x,
			-- 0, 0 for an atlas is top left, that means we need to convert the y 
			-- to make sure it is inserted at the correct place
			y=height-img.h-img.y,
			type=resource.TEXTURE_TYPE_2D,
			format=resource.TEXTURE_FORMAT_RGBA
		}
		
		resource.set_texture(texture_id, set_params, img.buffer)
		atlas_params = get_atlas_parameters(img, atlas_params)
	end
	return atlas_params
end


--- Pack a list of images into a atlas
-- @param atlas_name_or_path either name of your dynamic atlas or path to an 
-- existing atlas that will be over reused and over written.
-- @param list_of_textures Table image paths
-- @param width Atlas width
-- @param height Atlas height
-- @param options table containing if you want to **premultiply_alpha** (Defaults to false).
function M.pack(atlas_name_or_path, list_of_textures, width, height, options)
	local pack_data = get_package_data(list_of_textures, options or {})
	local e = M.algorithm(pack_data, width, height)
	if e == nil then
		print("ERROR!")
	end

	local atlas_creation_params = {
		width  = width,
		height = height,
		type   = resource.TEXTURE_TYPE_2D,
		format = resource.TEXTURE_FORMAT_RGBA,
	}

	if not ends_with(atlas_name_or_path, ".texturesetc") then
		local atlas_name = "/dynatlas/" .. atlas_name_or_path .. ".texture"
		local texture_id = resource.create_texture(atlas_name .."c", atlas_creation_params)
		local atlas_params = set_texture_data(texture_id, pack_data, height)
		
		return resource.create_atlas(atlas_name .. "setc", atlas_params)
	else
		local texture_id = resource.get_atlas(atlas_name_or_path).texture

		local atlas_params = set_texture_data(texture_id, pack_data, height)
		resource.set_atlas(atlas_name_or_path, atlas_params)
		return 
	end	
end

-- Debug function, creates a new atlas from an existing texture. This is used to view
-- to whole atlas with play_flipbook
function M._atlas_to_image(atlas_id, w, h, atlas_name)
	local atlas_name = atlas_name or "debug"
	local atlas_res = resource.get_atlas(atlas_id)
	local atlas_data = {
		texture = atlas_res.texture,
		animations = {
			{
				id          = "atlas",
				width       = w,
				height      = h,
				frame_start = 1,
				frame_end   = 2
			}
		},
		geometries = {
			{
				vertices = {
					0, 0,
					0, h,
					w, h,
					w, 0
				},
				uvs = {
					0, 0,
					0, h,
					w, h,
					w, 0
				},
				indices = {0,1,2,0,2,3}
			}
		}
	}
	return resource.create_atlas("/dynatlas/" .. atlas_name .. ".texturesetc", atlas_data)
end

return M