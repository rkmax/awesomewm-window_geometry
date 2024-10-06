local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

-- Define la clase WindowGeometryManager
local WindowGeometryManager = {}
WindowGeometryManager.__index = WindowGeometryManager

-- Constructor de la clase
function WindowGeometryManager:new(initial_ignored_classes)
    local self = setmetatable({}, WindowGeometryManager)
    self.geometry_file = gears.filesystem.get_cache_dir() .. "window_geometry"
    self.geometry_windows = gears.filesystem.get_cache_dir() .. "window_geometry_windows"
    self.already_loaded = false
    self.ignored_classes = initial_ignored_classes or {}
    return self
end

function WindowGeometryManager:is_ignored_class(class)
    for _, pattern in ipairs(self.ignored_classes) do
        if string.match(class, pattern) then
            return true
        end
    end
    return false
end

function WindowGeometryManager:should_ignore_client(c)
    if self:is_ignored_class(c.class) then
        return true
    end

    if c.fullscreen then
        return true
    end
    if c.type ~= "normal" then
        return true
    end

    return false
end

function WindowGeometryManager:geometries_to_string(geometries)
    local result = ""

    -- Obtener las claves de la tabla y ordenarlas
    local classes = {}
    for class in pairs(geometries) do
        table.insert(classes, class)
    end
    table.sort(classes)

    -- Construir la cadena usando las claves ordenadas
    for _, class in ipairs(classes) do
        local geom = geometries[class]
        result = result .. string.format("%s=%d,%d,%d,%d\n", class, geom.x, geom.y, geom.width, geom.height)
    end

    return result
end

function WindowGeometryManager:geometries_from_string(str)
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
function WindowGeometryManager:load_geometries()
    local geometries = {}
    local file = io.open(self.geometry_file, "r")
    if file then
        local str = file:read("*all")
        geometries = self:geometries_from_string(str)
        file:close()
    end
    return geometries
end

-- Save geometries to the file
function WindowGeometryManager:save_geometries(geometries)
    local file = io.open(self.geometry_file, "w")
    if not file then
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Geometry Error",
                         text = "Failed to open geometry file for writing." })
        return
    end
    file:write(self:geometries_to_string(geometries))
    file:close()
end

function WindowGeometryManager:save_all_window_geometries()
    local geometries = {}
    for _, c in ipairs(client.get()) do
        local window = c.window
        if window and not self:should_ignore_client(c) then
            geometries[window] = c:geometry()
        end
    end

    -- Create window geometry file
    local file = io.open(self.geometry_windows, "w")
    if not file then
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Geometry Error",
                         text = "Failed to open geometry file for writing." })
        return
    end
    file:write(self:geometries_to_string(geometries))
    file:close()
end

function WindowGeometryManager:restore_all_window_geometries()
    local geometries = {}
    local file = io.open(self.geometry_windows, "r")
    if file then
        local str = file:read("*all")
        geometries = self:geometries_from_string(str)
        file:close()
    end

    for _, c in ipairs(client.get()) do
        local window = c.window
        if window and geometries[window] then
            c:geometry(geometries[window])
        end
    end

    if file then
        os.remove(self.geometry_windows)
    end
    self.already_loaded = true
end

-- Save the geometry of a client window
function WindowGeometryManager:save_client_geometry(c)
    local geometries = self:load_geometries()
    local class = c.class
    if class and not self:should_ignore_client(c) then
        geometries[class] = c:geometry()
        self:save_geometries(geometries)
    end
end

-- Restore the saved geometry for a client window
function WindowGeometryManager:restore_client_geometry(c)
    if not self.already_loaded then
        return
    end
    local geometries = self:load_geometries()
    local class = c.class
    local window = c.window_geometry

    if class and geometries[class] and not self:should_ignore_client(c) then
        c:geometry(geometries[class])
    end
end

-- Static init function to create and initialize the manager
local function init(initial_ignored_classes)
    local manager = WindowGeometryManager:new(initial_ignored_classes)

    -- Connect the signals to save and restore the geometry of a client window
    client.connect_signal("manage", function(c)
        gears.timer.delayed_call(function()
            manager:restore_client_geometry(c)
        end)
    end)

    client.connect_signal("unmanage", function(c)
        manager:save_client_geometry(c)
    end)

    awesome.connect_signal("exit", function(restarting)
        if restarting then
            manager:save_all_window_geometries()
        end
    end)

    awesome.connect_signal("startup", function()
        gears.timer.delayed_call(function()
            manager:restore_all_window_geometries()
        end)
    end)
end

return {
    init = init
}
