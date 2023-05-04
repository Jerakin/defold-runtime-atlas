# Runtime Atlas

This serves as both an exampel and a library to help you create atlases at runtime.

## Installation
You can use the runtime atlas in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your game.project file and in the dependencies field under project add:

https://github.com/Jerakin/defold-runtime-atlas/archive/refs/heads/main.zip

Or point to the ZIP file of a [specific release](https://github.com/Jerakin/defold-runtime-atlas/releases).

## Quick Start
You only need to supply a list of images as well as width and height to `rtatlas.pack()` use it.

```lua
local rtatlas = require "runtime-atlas.runtime-atlas"


local atlas_entries = {
    "example/assets/images/image0.png", "example/assets/images/image1.png"
}

local atlas_id = rtatlas.pack("example", atlas_entries, 256, 256)

go.set("#sprite", "image", atlas_id)
sprite.play_flipbook("#sprite", "image0.png")
```

The images added will be added with the full file name as the id. This always includes the `.png`.

## API

### rtatlas.pack(atlas_name_or_path, list_of_textures, width, height)
Packs the provided list_of_textures into an atlas

**PARAMETERS**
* ```atlas_name_or_path``` (string) - If an path is provided it will load the texture at that path and update image data on it. If a name is provided a new atlas will be created.
* ```list_of_textures``` (table) - A table of your images, these images needs to be available as resources.
* ```width``` (number) - The height of your atlas
* ```height``` (number) - The height of your atlas


### rtatlas.algorithm
Property which is the function that will be used to pack an atlas with. A simplistic rowpacking algorithm is provided as the default

## Packing Algorithm
If you want to write your own algoritm the signature should be
### algorithm.pack(list_of_textures, width, height)

**PARAMETERS**
* ```list_of_textures``` (table) - table of images to pack, each image is represented by a table `{name, w, h}` you are expected to return an extended version of this table where entries for positions `{x, y}` have been added.
* ```width``` (number) - The height of your atlas
* ```height``` (number) - The height of your atlas
