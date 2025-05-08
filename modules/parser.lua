-- gcode_parser.lua
local M = {}

-- Keeps track of the last known values for coordinates and command
local last_values = {
    Command = nil,
    X = nil,
    Y = nil,
    Z = nil
}

--- Parse a single line of G-code and return a table with command and coordinates
-- @param line string: a line from a G-code file
-- @return table: parsed values {Command, X, Y, Z, I, J, isArc}
function M.parse_line(line)
    local result = {
        Command = line:match("(G%d%d?)") or last_values.Command,
        X = tonumber(line:match("X([%+%-]?%d+%.?%d*)")) or last_values.X,
        Y = tonumber(line:match("Y([%+%-]?%d+%.?%d*)")) or last_values.Y,
        Z = tonumber(line:match("Z([%+%-]?%d+%.?%d*)")) or last_values.Z,
        I = tonumber(line:match("I([%+%-]?%d+%.?%d*)")) or nil,
        J = tonumber(line:match("J([%+%-]?%d+%.?%d*)")) or nil,
    }

    -- Determine if this is an arc move (I and J present)
    result.isArc = (result.I ~= nil and result.J ~= nil)

    -- Update the last known values
    last_values.Command = result.Command
    last_values.X = result.X
    last_values.Y = result.Y
    last_values.Z = result.Z

    return result
end

--- Reset the stored last values (useful between files or passes)
function M.reset()
    last_values = {
        Command = nil,
        X = nil,
        Y = nil,
        Z = nil
    }
end

return M