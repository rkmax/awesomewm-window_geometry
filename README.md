# AwesomeWM Window Geometry Manager

## What's This?

This project is a script for AwesomeWM that lets you manage window geometry based on their class. It automatically saves and restores window geometry using a cache file.

## What You Need

- AwesomeWM
- Lua
- AwesomeWM libraries: `awful`, `gears`, `naughty`

## How to Install

1. Clone this repository into your AwesomeWM configuration directory:

    ```sh
    git clone https://github.com/rkmax/awesomewm-window_geometry.git ~/.config/awesome/window_geometry
    ```

2. Include the script in your AwesomeWM configuration (`rc.lua`):

    ```lua
    local window_geometry = require("window_geometry")

    -- Connect the 'manage' signal to restore geometry when managing a new window
    client.connect_signal("manage", function(c)
        window_geometry.restore_client_geometry(c)
    end)

    -- Connect the 'unmanage' signal to save geometry when a window is unmanaged
    client.connect_signal("unmanage", function(c)
        window_geometry.save_client_geometry(c)
    end)
    ```

## How to Use

The script will automatically manage the geometry of windows based on their class. You don't need to take any manual action after installation.

### Example Usage

The script works automatically in the background. When you close a window, its geometry is saved. When you open a new window of the same class, the saved geometry is restored.

## Additional Information

If you need to adjust the geometry of a window programmatically, you can use the provided functions:

```lua
local window_geometry = require("window_geometry")

-- Save the geometry of the active window
if client.focus then
    window_geometry.save_client_geometry(client.focus)
end

-- Restore the geometry of the active window
if client.focus then
    window_geometry.restore_client_geometry(client.focus)
end
```

With these simple steps, your window geometries will be managed efficiently, saving and restoring their positions and sizes automatically.