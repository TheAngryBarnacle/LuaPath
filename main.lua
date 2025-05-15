local ui = require("ui")
require("canvas")
require("webview")
local json = require("json")
--print(_VERSION)
-- My Modules
local grid = require("modules/grid")
local cam = require("modules/camera")
local parser = require("modules/parser")

-- Theme Definitions
--ui.theme = "dark"
local themes = {
    dark = {
        background = 0x1e1e1e, text = 0xd4d4d4,
        axis = { x = 0xff5555, y = 0x55ff55, z = 0x5599ff },
        card = 0x333333,cardHover = 0x181818, canvasBG = 0x181818, grid = 0xFFFFFF,
        travel = 0x888888, cut = 0x00d4ff, extrusion = 0xff00ff,
        highlight = 0xffaa00, accent = 0x00c896,
        button = 0x00c896, buttonHover = 0x33dab1,
        buttonText = 0x1e1e1e, buttonTextHover = 0x000000,
    },
    light = {
        background = 0xffffff, text = 0x222222,
        axis = { x = 0xe63946, y = 0x2a9d8f, z = 0x457b9d },
        card = 0xdddddd,cardHover = 0xF0F0F0, canvasBG = 0xF0F0F0, grid = 0x000000,
        travel = 0xaaaaaa, cut = 0x0077b6, extrusion = 0xc1121f,
        highlight = 0xf4a261, accent = 0x264653,
        button = 0x264653, buttonHover = 0x3c6f75,
        buttonText = 0xffffff, buttonTextHover = 0xe0e0e0,
    }
}

local currentTheme = themes[ui.theme]
--local currentFile = ""
local data = {}
local frameTime = 1 / 60

-- Main Window Setup
local frame = ui.Window("LuaPath 2025.2 DEV")
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


local sidebar_bottomUI = ui.Panel(sidebar,0,sidebar.height - 55,sidebar.width,55)
sidebar_bottomUI.bgcolor = currentTheme.card
--print(sidebar_bottomUI.bgcolor) = 15790320 || 0xF0F0F0

local sidebar_bottomUI_settings = ui.Panel(sidebar_bottomUI,10,0,50,50)
sidebar_bottomUI_settings.bgcolor = currentTheme.card
local sidebar_bottomUI_settings_iconLight = ui.Picture(sidebar_bottomUI_settings,"resources/icons/settings_light.png",nil,nil,32,32)
local sidebar_bottomUI_settings_iconDark = ui.Picture(sidebar_bottomUI_settings,"resources/icons/settings_dark.png",nil,nil,32,32)

--print(sidebar_bottomUI_settings.bgcolor) = 1579032 || 181818

function sidebar_bottomUI_settings:onHover()
  self.bgcolor = currentTheme.cardHover
end

function sidebar_bottomUI_settings:onLeave()
  self.bgcolor = currentTheme.card
end

function sidebar_bottomUI_settings:onClick()
  local settings = {}
  
  local setting_window = ui.Window("Settings","fixed",600,300)
  setting_window.bgcolor = currentTheme.card
  setting_window:loadicon(sys.File("resources/icons/1.ico"))
 -- setting_window:loadtrayicon(sys.File("resources/icons/1.ico"))
  frame:showmodal(setting_window)
  --frame:center()
  setting_window:center()
  
  local window_lbl = ui.Label(setting_window,"Appearance",10,10)
  --window_lbl.fontsize = 12
  window_lbl.font = "Arial Bold"
  
  local breakLine_lbl = ui.Panel(setting_window,0,window_lbl.y + window_lbl.height + 2,setting_window.width,2)
  breakLine_lbl.bgcolor = currentTheme.card
  breakLine_lbl.border = true
  
  local apperance_group = ui.Panel(setting_window,0,breakLine_lbl.y + breakLine_lbl.height,setting_window.width,65)
  
  local theme_light_r = ui.Radiobutton(apperance_group,"Light Theme",10,10)
  local theme_dark_r = ui.Radiobutton(apperance_group,"Dark Theme",10,10)
  theme_dark_r.x = theme_light_r.x + theme_light_r.width + 5
  local theme_sysDef_r = ui.Radiobutton(apperance_group,"System Default",10,10)
  theme_sysDef_r.x = theme_dark_r.x + theme_dark_r.width + 5
  
  local lineThickness_lbl = ui.Label(apperance_group,"Line Thickness: ",10,theme_dark_r.y + theme_dark_r.height + 10)
  local lineThickness_combo = ui.Combobox(apperance_group,{"1","2","3","4"},lineThickness_lbl.x + lineThickness_lbl.width + 5,lineThickness_lbl.y - 3)
  lineThickness_combo.selected = lineThickness_combo.items[1]
  
  local filePath_header = ui.Label(setting_window,"File Paths",10,apperance_group.y + apperance_group.height+5)
  filePath_header.font = "Arial Bold"
  
  local filePath_break = ui.Panel(setting_window,0,filePath_header.y + filePath_header.height + 2,setting_window.width,2)
  filePath_break.bgcolor = currentTheme.card
  filePath_break.border = true
  
  local saveSettings = ui.Button(setting_window,"Save Settings",10,10)
  
  saveSettings.x = 600 - saveSettings.width - 10
  saveSettings.y = 300 - saveSettings.height - 10
  
  local closeWindow = ui.Button(setting_window,"Close Settings",10)
  closeWindow.y = 300 - closeWindow.height - 10
  
  function saveSettings:onClick()
    ui.theme = setting_theme_drop.selected.text
  end
  
 
  function setting_window:onHide()
    frame:tofront()
  end
end

if ui.theme == "dark" then
  sidebar_bottomUI_settings_iconDark:show()
  sidebar_bottomUI_settings_iconDark:center()
  sidebar_bottomUI_settings_iconDark.enabled = false
  sidebar_bottomUI_settings_iconLight:hide()
else
  sidebar_bottomUI_settings_iconDark:hide()
  sidebar_bottomUI_settings_iconLight:show()
  sidebar_bottomUI_settings_iconLight:center()
  sidebar_bottomUI_settings_iconLight.enabled = false
end

-- Webview for G-code Visualization
local viewport = ui.Webview(frame, {
    url = "file:///web/gcode_viewer.html"
}, sidebar.width, 0, frame.width - 300, frame.height)

function viewport:onLoaded()
  if ui.theme == "dark" then
    self:postmessage('{ "THEME" : "dark" }', true)
  elseif ui.theme == "light" then
    self:postmessage('{ "THEME" : "light" }', true)
  else
    ui.warn("Could not set theme for viewport, invalid theme","ERROR SETTING VIEWPORT THEME")
  end
end
-- Helper: Update File Display
local function open_file(file)
    if file then
        currentFile_edit:load(file)
        currentFile_lbl.text = file.name
        currentFile_lbl.fontsize = 10
        currentFile_lbl.y = (openFile.height - currentFile_lbl.height) / 2 + 10
    end
end
-- File Open Button Click Handler
function openFile:onClick()
    
    local file = ui.opendialog("Open gcode file", false, "Tap Files (*.tap)|*.tap|NC Files (*.nc)|*.nc|GCODE Files (*.gcode)|*.gcode")
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
    
    --sidebar_bottomUI.y = sidebar.height- 50
   -- sidebar_bottomUI.height = 50
end

-- Start UI Event Loop
ui.run(frame):wait()