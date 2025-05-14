local ui = require("ui")
require("canvas")
require("webview")
local json = require("json")

-- My Modules
local grid = require("modules/grid")
local cam = require("modules/camera")
local parser = require("modules/parser")

-- Theme Definitions
ui.theme = "dark"

local themes = {
    dark = {
        background = 0x1e1e1e, text = 0xd4d4d4,
        axis = { x = 0xff5555, y = 0x55ff55, z = 0x5599ff },
        card = 0x333333, canvasBG = 0x181818, grid = 0xFFFFFF,
        travel = 0x888888, cut = 0x00d4ff, extrusion = 0xff00ff,
        highlight = 0xffaa00, accent = 0x00c896,
        button = 0x00c896, buttonHover = 0x33dab1,
        buttonText = 0x1e1e1e, buttonTextHover = 0x000000,
    },
    light = {
        background = 0xffffff, text = 0x222222,
        axis = { x = 0xe63946, y = 0x2a9d8f, z = 0x457b9d },
        card = 0xdddddd, canvasBG = 0xF0F0F0, grid = 0x000000,
        travel = 0xaaaaaa, cut = 0x0077b6, extrusion = 0xc1121f,
        highlight = 0xf4a261, accent = 0x264653,
        button = 0x264653, buttonHover = 0x3c6f75,
        buttonText = 0xffffff, buttonTextHover = 0xe0e0e0,
    }
}

local currentTheme = themes[ui.theme]
local currentFile = ""
local data = {}
local frameTime = 1 / 60

-- Main Window Setup
local frame = ui.Window("LuaPath 2025.1 RC")
frame.width = 1280
frame.height = 720
frame.bgcolor = currentTheme.background
frame:loadicon(sys.File("resources/icons/1.ico"))
frame:loadtrayicon(sys.File("resources/icons/1.ico"))

-- Sidebar Panel
local sidebar = ui.Panel(frame, 0, 0, 300, frame.height)
sidebar.bgcolor = currentTheme.card

-- Open File Button
local openFile = ui.Button(sidebar, "Open File...", 10, 10)
openFile.x = (sidebar.width - openFile.width) - 5
openFile.fgcolor = currentTheme.text

-- File Label
local currentFile_lbl = ui.Label(sidebar, "No File Selected", 10, 10)
currentFile_lbl.fontsize = 12
currentFile_lbl.y = (openFile.height - currentFile_lbl.height) / 2 + 10
currentFile_lbl.fgcolor = currentTheme.text

-- File Editor
local currentFile_edit = ui.Edit(
    sidebar, "", 10,
    currentFile_lbl.y + currentFile_lbl.height + 10,
    sidebar.width - 20,
    sidebar.height - (currentFile_lbl.y + currentFile_lbl.height) - 70
)

-- Webview for G-code Visualization
local viewport = ui.Webview(frame, {
    url = "file:///web/gcode_viewer.html"
}, sidebar.width, 0, frame.width - 300, frame.height)


-- Helper: Update File Display
local function open_file(file)
    if file then
        currentFile_edit:load(file)
        currentFile_lbl.text = file.name
        currentFile_lbl.fontsize = 10
        currentFile_lbl.y = (openFile.height - currentFile_lbl.height) / 2 + 10
    end
    
    
end

function viewport:onMessage(str)
  print(str)
end

function sidebar:onClick()
  print("Clicked")
  e = json.encode(currentTheme)
  viewport:postmessage('{ "THEME" : '..e..'}', true)
end

-- File Open Button Click Handler
function openFile:onClick()
    
    local file = ui.opendialog("Open gcode file", false, "Tap Files (*.tap)|*.tap|NC Files (*.nc)|*.nc")
    if file then
        data = {}  -- Clear previous data
        file:open()
        for line in file.lines do
            local parsed = parser.parse_line(line)
            table.insert(data, parsed)
        end
        file:close()
        local encoded = json.encode(data)
        viewport:postmessage('{ "GCODE" : '..encoded..'}', true)
        open_file(file)
    end
end

-- Handle Window Resizing
function frame:onResize()
    viewport.width = self.width - 300
    viewport.height = self.height
    sidebar.height = self.height
    currentFile_edit.height = sidebar.height - (currentFile_lbl.y + currentFile_lbl.height) - 70
end

-- Start UI Event Loop
ui.run(frame):wait()