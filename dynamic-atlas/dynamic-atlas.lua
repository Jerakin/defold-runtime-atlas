local rowpacking = require "dynamic-atlas/row-packing"

local M  = {}

M.algorithm = rowpacking.pack

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

local function flip_texture_vertically(buffer_string, outw, outh, bytes_per_pixel)
	local pixels = {}
	buffer_string:gsub(".",function(c) table.insert(pixels,c) end)
	local byte1
	local byte2
	local offset1
	local offset2
	for yi=1, outh / 2 do
		for xi=1, outw do 
			offset1 = (xi + (yi * outw)) * bytes_per_pixel;
			offset2 = (xi + ((outh - 1 - yi) * outw)) * bytes_per_pixel;
			for bi=0, bytes_per_pixel do
				byte1 = pixels[offset1 + bi];
				byte2 = pixels[offset2 + bi];
				pixels[offset1 + bi] = byte2;
				pixels[offset2 + bi] = byte1;
			end
		end
	end
	return table.concat(pixels, "")
end

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


--This function finds the filename when given a complete path 
function get_filename(path)
	local parts = split(path, "/")
	return parts[#parts]
end


local function get_package_data(list_of_textures)
	local pack_data = {}
	for i in pairs(list_of_textures or {}) do
		local image_path = list_of_textures[i]
		local file = io.open(image_path, "rb")
		if file then
			local buffer = file:read("*all")
			file:close()
			local img = image.load(buffer)
			local buffer = flip_texture_vertically(img.buffer, img.width, img.height, 4)
			table.insert(pack_data, {name=get_filename(image_path), buffer=convert_string_buffer_to_buffer(buffer), w=img.width, h=img.height})
		end
	end
	return pack_data
end


local function get_atlas_parameters(image, atlas_params)
	table.insert(atlas_params.animations, {
		id          = image.name,
		width       = image.w,
		height      = image.h,
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
			image.x,   image.y,
			image.x,   image.y + image.h,
			image.x + image.w, image.y + image.h,
			image.x + image.w, image.y
		},
		indices = {0,1,2,0,2,3}
	})
	return atlas_params
end


function M.pack(atlas_name_or_resource, list_of_textures, width, height)
	local pack_data = get_package_data(list_of_textures)
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
	
	if type(atlas_name_or_resource) == "string" then
		local atlas_name = "/dynatlas/" .. atlas_name_or_resource .. ".texture"
		local texture_id = resource.create_texture(atlas_name .."c", atlas_creation_params)
		local set_params
		local atlas_params = {animations={}, geometries={}, texture = texture_id}
		
		for i in pairs(pack_data) do
			local img = pack_data[i]
			set_params = {width=img.w, height=img.h, x=img.x, y=height-img.h-img.y, type=resource.TEXTURE_TYPE_2D, format=resource.TEXTURE_FORMAT_RGBA}
			resource.set_texture(texture_id, set_params, img.buffer)
			atlas_params = get_atlas_parameters(img, atlas_params)
		end
		
		return resource.create_atlas(atlas_name .. "setc", atlas_params)
	else
		
	end	
end

function M.atlas_to_image(atlas_id, w, h, atlas_name)
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