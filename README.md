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
    require("window_geometry")
    ```

## How to Use

The script will automatically manage the geometry of windows based on their class. You don't need to take any manual action after installation.

### Example Usage

The script works automatically in the background. When you close a window, its geometry is saved. When you open a new window of the same class, the saved geometry is restored.