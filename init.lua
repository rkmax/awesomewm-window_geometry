local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

-- Define the file path to store window geometry settings
local geometry_file = gears.filesystem.get_cache_dir() .. "window_geometry"

-- Load saved geometries from the file
local function load_geometries()
    local geometries = {}
    local file = io.open(geometry_file, "r")
    if file then
        for line in file:lines() do
            local class, x, y, width, height = line:match("^(.-)=(.-),(.-),(.-),(.+)$")
            if class and x and y and width and height then
                geometries[class] = { x = tonumber(x), y = tonumber(y), width = tonumber(width), height = tonumber(height) }
            end
        end
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
    for class, geom in pairs(geometries) do
        local success, result = pcall(function()
            return string.format("%s=%d,%d,%d,%d\n", class, geom.x, geom.y, geom.width, geom.height)
        end)
        if success then
            file:write(result)
        else
            naughty.notify({ preset = naughty.config.presets.critical,
                             title = "Geometry Error",
                             text = "Failed to format geometry for class: " .. class .. "\nError: " .. result })
        end
    end
    file:close()
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
    local geometries = load_geometries()
    local class = c.class
    if class and geometries[class] then
        c:geometry(geometries[class])
    end
end

-- Return the functions to be used externally if needed
return {
    save_client_geometry = save_client_geometry,
    restore_client_geometry = restore_client_geometry
}
