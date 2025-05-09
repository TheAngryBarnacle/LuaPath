local ui = require("ui")
require("canvas")
local kb = require("keyboard")
local grid = require("modules/grid")
local cam = require("modules/camera")
local parser = require("modules/parser")


local data = {}

ui.theme = "light"

local themes = {
    dark = {
        background = 0x1e1e1e,
        text = 0xd4d4d4,
        axis = {
            x = 0xff5555,
            y = 0x55ff55,
            z = 0x5599ff,
        },
        card = 0x333333,
        canvasBG = 0x181818,
        grid = 0xFFFFFF,
        travel = 0x888888,
        cut = 0x00d4ff,
        extrusion = 0xff00ff,
        highlight = 0xffaa00,
        accent = 0x00c896,
        button = 0x00c896,
        buttonHover = 0x33dab1,
        buttonText = 0x1e1e1e,          -- dark text for light button
        buttonTextHover = 0x000000,     -- slightly darker on hover
    },
    light = {
        background = 0xffffff,
        text = 0x222222,
        axis = {
            x = 0xe63946,
            y = 0x2a9d8f,
            z = 0x457b9d,
        },
        card = 0xdddddd,
        canvasBG = 0xF0F0F0,
        grid = 0x000000,
        travel = 0xaaaaaa,
        cut = 0x0077b6,
        extrusion = 0xc1121f,
        highlight = 0xf4a261,
        accent = 0x264653,
        button = 0x264653,
        buttonHover = 0x3c6f75,
        buttonText = 0xffffff,         -- white text for dark button
        buttonTextHover = 0xe0e0e0,    -- slightly lighter on hover
    }
}

local currentTheme = themes[ui.theme]
--gcode.setTheme(currentTheme)
--print(currentTheme)

local currentFile = ""

local frameTime = 1/60

local frame = ui.Window("LuaPath 2025.1 RC")
--frame.menu = ui.Menu("&File", "&Edit", "&View", "&?")
frame.width = 1280
frame.height = 720
frame.bgcolor = currentTheme.background
frame:loadicon(sys.File("resources/icons/1.ico"))
frame:loadtrayicon(sys.File("resources/icons/1.ico"))

local sidebar = ui.Panel(frame,0,0,300,frame.height)
sidebar.bgcolor = currentTheme.card

local openFile = ui.Button(sidebar,"Open File...",10,10)
openFile.x = (sidebar.width - openFile.width) - 5
openFile.fgcolor = currentTheme.text


local currentFile_lbl = ui.Label(sidebar,"No File Selected",10,10)
currentFile_lbl.fontsize = 12
currentFile_lbl.y = (openFile.height - currentFile_lbl.height) / 2 + 10
currentFile_lbl.fgcolor = currentTheme.text

local currentFile_edit = ui.Edit(sidebar,"",10,currentFile_lbl.y + currentFile_lbl.height + 10,sidebar.width - 20,(sidebar.height - (currentFile_lbl.y + currentFile_lbl.height)) - 70)
--currentFile_edit.readonly = true

local function open_file(file)
  if file ~= nil then
    currentFile_edit:load(file)
    currentFile_lbl.text = file.name
    currentFile_lbl.fontsize = 10
    currentFile_lbl.y = (openFile.height - currentFile_lbl.height) / 2 + 10
  end
end
local viewport = ui.Canvas(frame,sidebar.width,0,frame.width - 300,frame.height)

function viewport:arc(cx, cy, radius, startAngle, endAngle, segments)
    local deg2rad = math.pi / 180
    local angleStep = (endAngle - startAngle) / segments
    local prevX = cx + math.cos(startAngle * deg2rad) * radius
    local prevY = cy + math.sin(startAngle * deg2rad) * radius

    for i = 1, segments do
        local angle = startAngle + i * angleStep
        local rad = angle * deg2rad
        local x = cx + math.cos(rad) * radius
        local y = cy - math.sin(rad) * radius  -- flip y-axis for typical arc direction
        self:line(prevX, prevY, x, y)
        prevX, prevY = x, y
    end
end

local axisImage = viewport:Image(sys.File("resources/images/show_hide_axis.png"))
local axisImage_white = viewport:Image(sys.File("resources/images/show_hide_axis_white.png"))

viewport.buttonisHover = false

function viewport:onPaint()
  self:begin()
  self:clear((currentTheme.canvasBG << 8) | 0xFF)

  -- Draw the grid
  grid.draw(self, cam, (currentTheme.grid << 8) | 0xFF, {
      x = (currentTheme.axis.x << 8) | 0xFF,
      y = (currentTheme.axis.y << 8) | 0xFF,
      z = (currentTheme.axis.z << 8) | 0xFF
  }, "center", 40)

local scale = 10
local segments = 50  -- number of segments for arc resolution

-- First pass: draw cut lines and arcs (Z ≤ 0)
if #data > 1 then
  for i = 2, #data do
    local p1 = data[i - 1]
    local p2 = data[i]

    if p1.X and p1.Y and p1.Z and p2.X and p2.Y and p2.Z then
      if p1.Z <= 0 or p2.Z <= 0 then
        if p2.isArc and p2.I and p2.J then
          grid.drawArc(
            self, cam,
            p1.X, p1.Y, p1.Z,
            p2.X, p2.Y,
            p2.I, p2.J,
            p2.Command == "G02",
            segments,
            scale,
            (currentTheme.cut << 8) | 0xFF
          )
        else
          grid.drawLine(
            self, cam,
            p1.X * scale, -p1.Z * scale, p1.Y * scale,
            p2.X * scale, -p2.Z * scale, p2.Y * scale,
            (currentTheme.cut << 8) | 0xFF
          )
        end
      end
    end
  end
end

-- Second pass: draw travel lines (Z > 0)
for i = 2, #data do
  local p1 = data[i - 1]
  local p2 = data[i]

  if p1.X and p1.Y and p1.Z and p2.X and p2.Y and p2.Z then
    if p1.Z > 0 and p2.Z > 0 then
      grid.drawLine(
        self, cam,
        p1.X * scale, p1.Z * scale, p1.Y * scale,
        p2.X * scale, p2.Z * scale, p2.Y * scale,
        (currentTheme.travel << 8) | 0xFF
      )
    end
  end
end

  -- UI variables
  self.buttonX = 10
  self.buttonY = self.height - 60
  self.buttonWidth = 135
  self.buttonHeight = 50
  self.buttonRadius = 5
  self.iconSize = 24
  self.buttonTextAlign = "center" -- "left", "right", or "center"
  self.spacing = 8 -- spacing between icon and text
  --self.buttonisHover = false
  self.buttonColor = (currentTheme.button << 8) | 0xFF
  
  if self.buttonisHover == true then
    self.buttonColor = (currentTheme.buttonHover << 8) | 0xFF
  else
    self.buttonColor = (currentTheme.button << 8) | 0xFF
  end

  -- Button background
  self:fillroundrect(self.buttonX, self.buttonY, self.buttonX + self.buttonWidth, self.buttonY + self.buttonHeight, self.buttonRadius, self.buttonRadius, self.buttonColor)

  -- Text setup
  local text = "  Show/Hide\nGlobal Axises"
  local size = self:measure(text)

  local iconX, textX
  local contentHeight = math.max(self.iconSize, size.height)
  local contentY = self.buttonY + (self.buttonHeight - contentHeight) / 2

  if self.buttonTextAlign == "left" then
    iconX = self.buttonX + 5
    textX = iconX + self.iconSize + self.spacing

  elseif self.buttonTextAlign == "right" then
    textX = self.buttonX + self.buttonWidth - size.width - 5
    iconX = textX - self.spacing - self.iconSize

  elseif self.buttonTextAlign == "center" then
    local groupWidth = self.iconSize + self.spacing + size.width
    local groupStart = self.buttonX + (self.buttonWidth - groupWidth) / 2
    iconX = groupStart
    textX = iconX + self.iconSize + self.spacing
  end

  -- Draw icon
  if ui.theme == "dark" then
    axisImage:draw(iconX, contentY + (contentHeight - self.iconSize) / 2)
  elseif ui.theme == "light" then
    axisImage_white:draw(iconX, contentY + (contentHeight - self.iconSize) / 2)
  end
  


  -- Draw text
  local textY = contentY + (contentHeight - size.height) / 2
  self:print(text, textX, textY, (currentTheme.buttonText << 8) | 0xFF)

  self:flip()
end

function viewport:onClick()
  if self.buttonisHover then
    grid.toggleAxis()
  end
end

function viewport:onMouseWheel(d)
  cam:onMouseWheel(d)
end

function viewport:onHover(x,y,button)
 cam.handleMouse(x, y, button)
 
 
  if x >= self.buttonX and x <= self.buttonX + self.buttonWidth and y >= self.buttonY and y <= self.buttonY + self.buttonHeight then
    self.buttonisHover = true
  else
    self.buttonisHover = false
  end
end

function openFile:onClick()
    local file = ui.opendialog("Open GCODE File", false, "NC Files (*.nc)|*.nc|Tap Files (*.tap)|*.tap")
    if file ~= nil then
        currentFile = file
        open_file(file)

        parser.reset()
        file:open()
        
        for line in file.lines do
            if line:match("^G") then
                p_line = parser.parse_line(line)
                table.insert(data,p_line)
            end -- close if line:match("^G")
        end -- close for
        file:close()
    end -- close if file ~= nil
end -- close function

function frame:onResize()
  viewport.width = self.width - 300
  sidebar.height = self.height
  viewport.height = self.height
  
  currentFile_edit.height = (sidebar.height - (currentFile_lbl.y + currentFile_lbl.height)) - 70
end

ui.run(frame):wait()