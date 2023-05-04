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
