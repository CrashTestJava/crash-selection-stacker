-- Crash's Selection Stacker
-- https://crashtestjava.itch.io/selection-stacker


local visitedSprites = {}

-- Length function
local function getLength(width, height, direction)
    if direction == "Up" or direction == "Down" then
        return height
    elseif direction == "Left" or direction == "Right" then
        return width
    end
end

-- Coordinate function
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
local function stack(image, direction, unit, length, xoffset, yoffset)
    local pos = image.cel.position
    image = Image(image)
    local cel = app.sprite:newCel(app.layer, app.frame)
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

-- Parameter setter function
local function setParameters(pref, dlg)
    pref.stackDirection = dlg.data.direction
    pref.stackLengthUnit = dlg.data.unit
    pref.stackLength = dlg.data.length
    pref.stackXOffset = dlg.data.xoffset
    pref.stackYOffset = dlg.data.yoffset
end

-- Selection event handler function
local function selectionHandler(dlg)
    if app.sprite ~= nil then
        if app.sprite.selection.isEmpty or app.cel == nil or Image(app.cel.image, Rectangle(app.sprite.selection.bounds.x - app.cel.bounds.x, app.sprite.selection.bounds.y - app.cel.bounds.y, app.sprite.selection.bounds.width, app.sprite.selection.bounds.height)):isEmpty() then
            dlg:modify{id="stack", enabled=false, text="Empty or no selection!"}
        else
            dlg:modify{id="stack", enabled=true, text="Stack"}
        end
    else
        dlg:modify{id="stack", enabled=false, text="Empty or no selection!"}
    end
end

-- Extension command and dialog
function init(plugin)
    -- Parameter defaults
    local pref = plugin.preferences
    if pref.stackDirection == nil then pref.stackDirection = "Up" end
    if pref.stackLengthUnit == nil then pref.stackLengthUnit = "Amount" end
    if pref.stackLength == nil then pref.stackLength = 1 end
    if pref.stackXOffset == nil then pref.stackXOffset = 0 end
    if pref.stackYOffset == nil then pref.stackYOffset = 0 end
    -- Stack command
    local isUIOpen = false
    local firstOpen = true
    plugin:newCommand{
        id="StackSelection",
        title="Stack",
        group="edit_transform",
        onclick=function()
            if firstOpen == true then
                visitedSprites[tostring(app.sprite)] = true
                firstOpen = false
            end
            if isUIOpen == false then
                isUIOpen = true
            else
                return nil
            end
            -- Dialog
            local dlg = Dialog{title="Stack Selection", onclose=function() isUIOpen=false end}
            dlg
            :separator("Direction:")
            :combobox{id="direction", option=pref.stackDirection, options={"Up","Down","Left","Right"}, onchange=function() setParameters(pref, dlg) end}
            :separator("Length:")
            :combobox{id="unit", label="Length Unit:", option=pref.stackLengthUnit, options={"Amount","Pixels"}, onchange=function() setParameters(pref, dlg) end}
            :number{id="length", label="Length:", text=tostring(pref.stackLength), decimals=0, onchange=function() setParameters(pref, dlg) end}
            :separator("Offsets:")
            :number{id="xoffset", label="X-Offset:", text=tostring(pref.stackXOffset), decimals=0, onchange=function() setParameters(pref, dlg) end}
            :number{id="yoffset", label="Y-Offset:", text=tostring(pref.stackYOffset), decimals=0, onchange=function() setParameters(pref, dlg) end}
            :separator()
            :button{id="stack", enabled=false, text="Empty or no selection!", focus=false, hexpand=true, onclick=function()
                app.transaction("Stack",
                    function()
                        stack(app.cel.image, dlg.data.direction, dlg.data.unit, dlg.data.length, dlg.data.xoffset, dlg.data.yoffset)
                        app.refresh()
                    end
                )
            end
            }
            :show{wait=false}
            selectionHandler(dlg)
            app.sprite.events:on('change', function() selectionHandler(dlg) end)
            app.events:on('sitechange', function()
                selectionHandler(dlg)
                if app.sprite ~= nil then
                    if visitedSprites[tostring(app.sprite)] == nil then
                        app.sprite.events:on('change', function() selectionHandler(dlg) end)
                    end
                end
            end)
        end,
        onenabled=function()
            if app.sprite == nil then
                return false
            else
                return true
            end
        end
    }
end
