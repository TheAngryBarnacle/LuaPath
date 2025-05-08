local grid = {
    size = 10,       -- spacing between lines
    width = 200,     -- total width in world units (X axis)
    height = 200,    -- total height in world units (Z axis)

    axisVisibility = { x = true, y = true, z = true }  -- initial state
}

-- Origin positions based on grid dimensions
local function getOriginPosition(originName)
    local halfWidth = grid.width / 2
    local halfHeight = grid.height / 2

    local positions = {
        bottomLeft  = { -halfWidth, -halfHeight },
        bottomRight = {  halfWidth, -halfHeight },
        topLeft     = { -halfWidth,  halfHeight },
        topRight    = {  halfWidth,  halfHeight },
        center      = { 0, 0 }
    }

    return positions[originName] or positions["center"]
end

-- Toggle all axes on/off based on current state
function grid.toggleAxis()
    -- Determine new state: if any axis is visible, turn all off; else turn all on
    local anyVisible = grid.axisVisibility.x or grid.axisVisibility.y or grid.axisVisibility.z
    local newState = not anyVisible

    grid.axisVisibility.x = newState
    grid.axisVisibility.y = newState
    grid.axisVisibility.z = newState
end

function grid.draw(canvas, camera, gridColor, axisColors, axisOrigin, axisLength)
    local halfWidth = grid.width / 2
    local halfHeight = grid.height / 2

    -- Draw vertical lines (along Z axis)
    for x = -halfWidth, halfWidth, grid.size do
        local prevX, prevY = nil, nil
        for z = -halfHeight, halfHeight, grid.size do
            local px, py = camera.projectPoint(x, 0, z, canvas)
            if prevX then
                canvas:line(prevX, prevY, px, py, gridColor)
            end
            prevX, prevY = px, py
        end
    end

    -- Draw horizontal lines (along X axis)
    for z = -halfHeight, halfHeight, grid.size do
        local prevX, prevY = nil, nil
        for x = -halfWidth, halfWidth, grid.size do
            local px, py = camera.projectPoint(x, 0, z, canvas)
            if prevX then
                canvas:line(prevX, prevY, px, py, gridColor)
            end
            prevX, prevY = px, py
        end
    end

    -- Get axis origin in world coordinates
    local ox, oz = table.unpack(getOriginPosition(axisOrigin))

    -- Draw X axis
    if grid.axisVisibility.x then
        local x1, y1 = camera.projectPoint(ox, 0, oz, canvas)
        local x2, y2 = camera.projectPoint(ox + axisLength, 0, oz, canvas)
        canvas:line(x1, y1, x2, y2, axisColors.x)
    end

    -- Draw Y axis
    if grid.axisVisibility.y then
        local yx1, yy1 = camera.projectPoint(ox, 0, oz, canvas)
        local yx2, yy2 = camera.projectPoint(ox, -axisLength, oz, canvas)
        canvas:line(yx1, yy1, yx2, yy2, axisColors.y)
    end

    -- Draw Z axis
    if grid.axisVisibility.z then
        local zx1, zy1 = camera.projectPoint(ox, 0, oz, canvas)
        local zx2, zy2 = camera.projectPoint(ox, 0, oz - axisLength, canvas)
        canvas:line(zx1, zy1, zx2, zy2, axisColors.z)
    end
end

--[[

-- OLD LINE FUNCTION

function grid.drawLine(canvas, camera, x1, z1, y1, x2, z2, y2, color)
  local sx1, sy1 = camera.projectPoint(x1, y1, z1, canvas)
  local sx2, sy2 = camera.projectPoint(x2, y2, z2, canvas)
  canvas:line(sx1, sy1, sx2, sy2, color)
end


]]--
-- NEW LINE FUNCTION

function grid.drawLine(canvas,camera,x1,y1,z1,x2,y2,z2,color)
  y1 = -y1
  y2 = -y2
  local sx1, sy1 = camera.projectPoint(x1, y1, z1, canvas)
  local sx2, sy2 = camera.projectPoint(x2, y2, z2, canvas)
  
  canvas:line(sx1,sy1,sx2,sy2,color)
end

--[[
function canvas:arc(cx, cy, radius, startAngle, endAngle, segments)
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

]]


function grid.drawArc(canvas, camera, x1, y1, z, x2, y2, i, j, clockwise, segments, scale, color)
  -- Apply scaling
  x1 = x1 * scale
  y1 = y1 * scale
  x2 = x2 * scale
  y2 = y2 * scale
  z  = z  * scale
  i  = i  * scale
  j  = j  * scale

  local cx = x1 + i
  local cy = y1 + j
  local radius = math.sqrt(i * i + j * j)

  local startAngle = math.deg(math.atan2(y1 - cy, x1 - cx))
  local endAngle = math.deg(math.atan2(y2 - cy, x2 - cx))

  if clockwise and endAngle > startAngle then
    endAngle = endAngle - 360
  elseif not clockwise and endAngle < startAngle then
    endAngle = endAngle + 360
  end

  local deg2rad = math.pi / 180
  local angleStep = (endAngle - startAngle) / segments

  local prevX = cx + math.cos(startAngle * deg2rad) * radius
  local prevY = cy + math.sin(startAngle * deg2rad) * radius
  local prevScreenX, prevScreenY = camera.projectPoint(prevX, z, prevY, canvas)

  for i = 1, segments do
    local angle = startAngle + i * angleStep
    local rad = angle * deg2rad

    local x = cx + math.cos(rad) * radius
    local y = cy + math.sin(rad) * radius
    local screenX, screenY = camera.projectPoint(x, z, y, canvas)

    canvas:line(prevScreenX, prevScreenY, screenX, screenY, color or 0x00FFFF)
    prevScreenX, prevScreenY = screenX, screenY
  end
end


function grid.drawCube(canvas, camera, cx, cy, cz, size, color)
    local half = size / 2
    cy = -cy

    -- Define 8 corners of the cube relative to center (cx, cy, cz)
    local corners = {
        -- Bottom face
        {cx - half, cy - half, cz - half}, -- 1: left-bottom-back
        {cx + half, cy - half, cz - half}, -- 2: right-bottom-back
        {cx + half, cy - half, cz + half}, -- 3: right-bottom-front
        {cx - half, cy - half, cz + half}, -- 4: left-bottom-front

        -- Top face
        {cx - half, cy + half, cz - half}, -- 5: left-top-back
        {cx + half, cy + half, cz - half}, -- 6: right-top-back
        {cx + half, cy + half, cz + half}, -- 7: right-top-front
        {cx - half, cy + half, cz + half}, -- 8: left-top-front
    }

    -- Helper to draw line between two corners
    local function connect(i, j)
    local cx1, cy1, cz1 = table.unpack(corners[i])
    local cx2, cy2, cz2 = table.unpack(corners[j])
    local x1, y1 = camera.projectPoint(cx1, cy1, cz1, canvas)
    local x2, y2 = camera.projectPoint(cx2, cy2, cz2, canvas)
    canvas:line(x1, y1, x2, y2, color)
end

    -- Bottom face
    connect(1, 2)
    connect(2, 3)
    connect(3, 4)
    connect(4, 1)

    -- Top face
    connect(5, 6)
    connect(6, 7)
    connect(7, 8)
    connect(8, 5)

    -- Vertical edges
    connect(1, 5)
    connect(2, 6)
    connect(3, 7)
    connect(4, 8)
end


function grid.drawCylinder(canvas, camera, cx, cy, cz, radius, height, color, segments)
    segments = segments or 16
    cy = -cy

    local topY = cy + height / 2
    local bottomY = cy - height / 2

    local top = {}
    local bottom = {}

    -- Generate circle points
    for i = 0, segments do
        local angle = (math.pi * 2) * (i / segments)
        local dx = math.cos(angle) * radius
        local dz = math.sin(angle) * radius

        table.insert(bottom, { cx + dx, bottomY, cz + dz })
        table.insert(top,    { cx + dx, topY,    cz + dz })
    end

    -- Draw top and bottom circles
    for i = 1, segments do
        local b1, b2 = bottom[i], bottom[i + 1]
        local t1, t2 = top[i], top[i + 1]

        -- Bottom circle segment
        local bx1, by1 = camera.projectPoint(b1[1], b1[2], b1[3], canvas)
        local bx2, by2 = camera.projectPoint(b2[1], b2[2], b2[3], canvas)
        canvas:line(bx1, by1, bx2, by2, color)

        -- Top circle segment
        local tx1, ty1 = camera.projectPoint(t1[1], t1[2], t1[3], canvas)
        local tx2, ty2 = camera.projectPoint(t2[1], t2[2], t2[3], canvas)
        canvas:line(tx1, ty1, tx2, ty2, color)

        -- Vertical side
        local vx1, vy1 = camera.projectPoint(b1[1], b1[2], b1[3], canvas)
        local vx2, vy2 = camera.projectPoint(t1[1], t1[2], t1[3], canvas)
        canvas:line(vx1, vy1, vx2, vy2, color)
    end
end


return grid
