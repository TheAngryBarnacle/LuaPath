-- camera.lua
local camera = {}

camera.fov = 800
camera.z = 300
camera.x = 0
camera.zPos = 0
camera.yaw = 0
camera.dragging = false
camera.draggingRight = false
camera.lastMouseX = 0
camera.lastMouseY = 0
camera.moveSpeed = 0.5
camera.zoomSpeed = 0.5
camera.flySpeed = 0.5
camera.rotateSpeed = math.rad(15)  -- Adjustable
camera.angle = math.rad(23)

local function rotateX(y, z, angle)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    local newY = y * cosA - z * sinA
    local newZ = y * sinA + z * cosA
    return newY, newZ
end

local function rotateY(x, z, angle)
    local cosA = math.cos(angle)
    local sinA = math.sin(angle)
    return x * cosA - z * sinA, x * sinA + z * cosA
end

function camera.projectPoint(x, y, z, canvas)
    x = x - camera.x
    z = z - camera.zPos

    x, z = rotateY(x, z, -camera.yaw)
    y, z = rotateX(y, z, camera.angle)

    local scale = camera.fov / (z + camera.z)
    local px = x * scale + canvas.width / 2
    local py = y * scale + canvas.height / 2

    return px, py
end

function camera.updateControls(kb, frameTime)
    local forwardX = math.sin(camera.yaw)
    local forwardZ = math.cos(camera.yaw)
    local rightX = math.cos(camera.yaw)
    local rightZ = -math.sin(camera.yaw)

    if kb.isdown("left") then
        camera.x = camera.x - rightX * camera.moveSpeed
        camera.zPos = camera.zPos - rightZ * camera.moveSpeed
    elseif kb.isdown("right") then
        camera.x = camera.x + rightX * camera.moveSpeed
        camera.zPos = camera.zPos + rightZ * camera.moveSpeed
    end

    if kb.isdown("up") then
        camera.x = camera.x + forwardX * camera.moveSpeed
        camera.zPos = camera.zPos + forwardZ * camera.moveSpeed
    elseif kb.isdown("down") then
        camera.x = camera.x - forwardX * camera.moveSpeed
        camera.zPos = camera.zPos - forwardZ * camera.moveSpeed
    end

    if kb.isdown("q") then
        camera.yaw = camera.yaw - camera.rotateSpeed * frameTime
    elseif kb.isdown("e") then
        camera.yaw = camera.yaw + camera.rotateSpeed * frameTime
    end
    
    if kb.isdown("z") then
      camera.fov = camera.fov + camera.zoomSpeed * 10
    elseif kb.isdown("x") then
      camera.fov = camera.fov - camera.zoomSpeed * 10
    end
    
end

function camera.handleMouse(mouseX, mouseY, button)
    -- Handle left mouse (translate camera)
    if button.left then
        if not camera.draggingLeft then
            camera.draggingLeft = true
            camera.lastMouseX = mouseX
            camera.lastMouseY = mouseY
        else
            local dx = mouseX - camera.lastMouseX
            local dy = mouseY - camera.lastMouseY

            -- Move camera relative to its orientation
            local forwardX = math.sin(camera.yaw)
            local forwardZ = math.cos(camera.yaw)
            local rightX = math.cos(camera.yaw)
            local rightZ = -math.sin(camera.yaw)

            -- dx controls left/right movement, dy controls forward/backward
            camera.x = camera.x - dx * 0.5 * rightX
            camera.zPos = camera.zPos - dx * 0.1 * rightZ

            camera.x = camera.x + dy * 0.5 * forwardX
            camera.zPos = camera.zPos + dy * 0.5 * forwardZ

            camera.lastMouseX = mouseX
            camera.lastMouseY = mouseY
        end
    else
        camera.draggingLeft = false
    end

    -- Handle right mouse (rotate camera)
    if button.right then
        if not camera.draggingRight then
            camera.draggingRight = true
            camera.lastMouseX = mouseX
            camera.lastMouseY = mouseY
        else
            local dx = mouseX - camera.lastMouseX
            local dy = mouseY - camera.lastMouseY

            -- Rotate yaw (horizontal) and pitch (vertical)
            camera.yaw = camera.yaw + dx * 0.005
            camera.angle = math.max(math.rad(5), math.min(math.rad(175), camera.angle - dy * 0.005))

            camera.lastMouseX = mouseX
            camera.lastMouseY = mouseY
        end
    else
        camera.draggingRight = false
    end
end

function camera.zoom(amount)
    camera.fov = math.max(10, math.min(2000, camera.fov + amount))
end

function camera:onMouseWheel(delta)
    -- Adjust FOV based on mouse wheel delta
    local zoomAmount = self.moveSpeed * delta --/ 120  -- Fine-tune sensitivity here (120 is standard wheel delta)
    self.zoom(zoomAmount)
end



return camera