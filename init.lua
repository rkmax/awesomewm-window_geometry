local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

-- Define the file path to store window geometry settings
local geometry_file = gears.filesystem.get_cache_dir() .. "window_geometry"
local geometry_windows = gears.filesystem.get_cache_dir() .. "window_geometry_windows"

local already_loaded = false

local function geometries_to_string(geometries)
    local result = ""
    for class, geom in pairs(geometries) do
        result = result .. string.format("%s=%d,%d,%d,%d\n", class, geom.x, geom.y, geom.width, geom.height)
    end
    return result
end

local function geometries_from_string(str)
    local geometries = {}
    for line in str:gmatch("[^\n]+") do
        local class, x, y, width, height = line:match("^(.-)=(.-),(.-),(.-),(.+)$")
        if class and x and y
            and width and height then
            geometries[class] = { x = tonumber(x), y = tonumber(y), width = tonumber(width), height = tonumber(height) }
        end
    end
    return geometries
end

-- Load saved geometries from the file
local function load_geometries()
    local geometries = {}
    local file = io.open(geometry_file, "r")
    if file then
        local str = file:read("*all")
        geometries = geometries_from_string(str)
        file:close()
    end
    return geometries
end

-- Save geometries to the file
local function save_geometries(geometries)
    local file = io.open(geometry_file, "w")
    if not file then
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Geometry Error",
                         text = "Failed to open geometry file for writing." })
        return
    end
    file:write(geometries_to_string(geometries))
    file:close()
end

local function save_all_window_geometries()
    local geometries = {}
    for _, c in ipairs(client.get()) do
        local window = c.window
        if window then
            geometries[window] = c:geometry()
        end
    end


    -- create window geometry file
    local file = io.open(geometry_windows, "w")
    if not file then
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Geometry Error",
                         text = "Failed to open geometry file for writing." })
        return
    end
    file:write(geometries_to_string(geometries))
    file:close()
end

local function restore_all_window_geometries()
    local geometries = {}
    local file = io.open(geometry_windows, "r")
    if file then
        local str = file:read("*all")
        geometries = geometries_from_string(str)
        file:close()
    end

    for _, c in ipairs(client.get()) do
        local window = c.window
        if window and geometries[window] then
            c:geometry(geometries[window])
        end
    end

    if file then
        os.remove(geometry_windows)
    end
    already_loaded = true
end

-- Save the geometry of a client window
local function save_client_geometry(c)
    local geometries = load_geometries()
    local class = c.class
    if class then
        geometries[class] = c:geometry()
        save_geometries(geometries)
    end
end

-- Restore the saved geometry for a client window
local function restore_client_geometry(c)
    if not already_loaded then
        return
    end
    local geometries = load_geometries()
    local class = c.class
    local window = c.window_geometry

    if class and geometries[class] then
        c:geometry(geometries[class])
    end
end

-- Connect the signals to save and restore the geometry of a client window

client.connect_signal("manage", function(c)
	gears.timer.delayed_call(function()
        restore_client_geometry(c)
    end)
end)

client.connect_signal("unmanage", function(c)
    save_client_geometry(c)
end)

awesome.connect_signal("exit", function(restarting)
	if restarting then
		save_all_window_geometries()
	end
end)

awesome.connect_signal("startup", function()
	gears.timer.delayed_call(function()
        restore_all_window_geometries()
    end)
end)

-- Return the functions to be used externally if needed
return {
    save_client_geometry = save_client_geometry,
    restore_client_geometry = restore_client_geometry,
    save_all_window_geometries = save_all_window_geometries,
    restore_all_window_geometries = restore_all_window_geometries
}
