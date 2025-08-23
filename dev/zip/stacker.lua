--[[
MIT License

Copyright (c) 2025 CrashTestJava

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Crash's Selection Stacker
-- https://crashtestjava.itch.io/selection-stacker



-- Get the length of the selection based on the direction
local function getLength(width, height, direction)
    if direction == "Up" or direction == "Down" then
        return height
    elseif direction == "Left" or direction == "Right" then
        return width
    end
end

-- Get the Point to paste to based on the length, direction, and offsets
local function getNewPoint(point, length, direction, xoffset, yoffset)
    local output
    if direction == "Up" then
        output = Point(point.x, point.y - length)
    elseif direction == "Down" then
        output = Point(point.x, point.y + length)
    elseif direction == "Left" then
        output = Point(point.x - length, point.y)
    elseif direction == "Right" then
        output = Point(point.x + length, point.y)
    end
    return Point(output.x + xoffset, output.y + yoffset)
end

-- Stack function
function StackSelection(image, direction, unit, length, xoffset, yoffset)
    local pos = image.cel.position
    image = Image(image)
    local cel = app.sprite:newCel(app.layer, app.frame)
    -- Move the cel to position to 0,0
    cel.image:drawImage(image, pos)
    local selectionBounds = app.sprite.selection.bounds
    local selectedContent = Image(cel.image, selectionBounds)
    local point = Point(selectionBounds.x, selectionBounds.y)
    local width = selectionBounds.width
    local height = selectionBounds.height
    if unit == "Amount" then
        for i=1, length, 1 do
            point = getNewPoint(point, getLength(width, height, direction), direction, xoffset, yoffset)
            cel.image:drawImage(selectedContent, point)
        end
    elseif unit == "Pixels" then
        local calcLength = getLength(width, height, direction)
        if direction == "Down" or direction == "Right" then
            point = getNewPoint(point, calcLength - 1, direction, 0, 0)
        end
        local sectionCount = 0
        for i=1, length, 1 do
            local rectangle = Rectangle(selectionBounds)
            if direction == "Up" then
                rectangle.y = rectangle.height - sectionCount - 1
                rectangle.x = 0
                rectangle.height = 1
            elseif direction == "Down" then
                rectangle.y = sectionCount
                rectangle.x = 0
                rectangle.height = 1
            elseif direction == "Left" then
                rectangle.x = rectangle.width - sectionCount - 1
                rectangle.y = 0
                rectangle.width = 1
            elseif direction == "Right" then
                rectangle.x = sectionCount
                rectangle.y = 0
                rectangle.width = 1
            end
            local section = Image(selectedContent, rectangle)
            point = getNewPoint(point, 1, direction, xoffset, yoffset)
            cel.image:drawImage(section, point)
            sectionCount = sectionCount + 1
            if sectionCount == calcLength then sectionCount = 0 end
        end
    end
    local shrunkenImageBounds = cel.image:shrinkBounds()
    cel.position = Point(shrunkenImageBounds.x, shrunkenImageBounds.y)
    cel.image = Image(cel.image, shrunkenImageBounds)
end