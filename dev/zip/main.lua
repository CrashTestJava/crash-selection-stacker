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



require("stacker")

-- Keep track of visited sprites for event handling
local g_visitedSprites = {}
-- Save dialog bounds for preset creation
local g_dialogBounds = nil
-- Current preset in managepresets dialog
local g_currentPreset = nil

-- Parameter setter function
local function setParameters(pref, dlg)
    pref.stackDirection = dlg.data.direction
    pref.stackLengthUnit = dlg.data.unit
    pref.stackLength = dlg.data.length
    pref.stackXOffset = dlg.data.xoffset
    pref.stackYOffset = dlg.data.yoffset
end

-- Get index from value in table
local function indexOf(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Create preset function
local function createPreset(pref, name, direction, unit, length, xoffset, yoffset)
    if name ~= "" then
        local t = {
        ["id"] = "preset" .. tostring(math.random(99999999)),
        ["name"] = name,
        ["direction"] = direction,
        ["unit"] = unit,
        ["length"] = length,
        ["xoffset"] = xoffset,
        ["yoffset"] = yoffset
        }
        table.insert(pref.stackPresets, t)
    end
end

-- Create preset dialog function
local function createPresetDialog(parent, pref)
    local p = parent.data
    local dlg = Dialog{title="New Preset", parent=parent}
    dlg
        :entry{id="presetname", label="Name"}
        :separator()
        :button{text="Create", onclick=function()
            createPreset(pref, dlg.data.presetname, p.direction, p.unit, p.length, p.xoffset, p.yoffset)
            g_dialogBounds = parent.bounds
            dlg:close()
            parent:close()
            app.command.StackSelection()
            end}
        :button{text="Cancel"}
        :show()
end

-- Preset executor function
local function runPreset(dlg, pref, params)
    dlg
        :modify{id="direction", option=params[1]}
        :modify{id="unit", option=params[2]}
        :modify{id="length", text=params[3]}
        :modify{id="xoffset", text=params[4]}
        :modify{id="yoffset", text=params[5]}
    setParameters(pref, dlg)
end

-- Load preset function
local function loadPresets(dlg, pref, buttons)
    local presets = pref.stackPresets
    if presets[1] ~= nil then
        dlg:separator{id="presetseparator"}
        for i, p in ipairs(presets) do
            local selected = false
            if buttons then
                dlg:button{id=p.id, text=p.name, onclick=function() runPreset(dlg, pref, {p.direction, p.unit, p.length, p.xoffset, p.yoffset}) end}
            else
                if i == 1 then
                    selected = true
                    g_currentPreset = p
                end
                dlg:radio{id=p.id, text=p.name, selected=selected, onclick=function() g_currentPreset = p end}
            end
        end
    end
end

-- Show warning dialog function
local function showWarningDialog(parent, warning, firstclass)
    local dlg = Dialog{title="Warning", parent=parent}
    dlg
        :label{text=warning}
        :separator()
        :button{text="Confirm", onclick=function()
            firstclass()
            dlg:close()
        end}
        :button{text="Cancel", focus=true}
        :show()
end

-- Edit preset dialog function
local function editPresetDialog(preset, parent, superparent)
    local dlg = Dialog{title="Edit Preset", parent=parent}
    dlg
        :entry{id="name", text=preset.name}
        :separator()
        :button{text="Save", onclick=function()
            preset.name = dlg.data.name
            parent:modify{id=preset.id, text=dlg.data.name}
            superparent:modify{id=preset.id, text=dlg.data.name}
            dlg:close()
            end}
        :button{text="Cancel"}
        :show()
end

-- Delete preset function
local function deletePreset(preset, dlg, parent, pref)
    table.remove(pref.stackPresets, indexOf(pref.stackPresets, preset))
    parent:modify{id=preset.id, visible=false}
    if #pref.stackPresets == 0 then
        dlg:close()
        parent:modify{id="presetseparator", visible=false}
        parent:modify{id="managepresets", enabled=false}
    else
        dlg:modify{id=preset.id, visible=false}
        dlg:modify{id=pref.stackPresets[1].id, selected=true}
        g_currentPreset = pref.stackPresets[1]
    end
end

-- Delete all presets function
local function deleteAllPresets(dlg, parent, pref)
    for i, preset in ipairs(pref.stackPresets) do
        parent:modify{id=preset.id, visible=false}
    end
    parent:modify{id="presetseparator", visible=false}
    parent:modify{id="managepresets", enabled=false}
    dlg:close()
    pref.stackPresets = {}
    g_currentPreset = nil
end

-- Manage presets dialog function - Global to prevent lua error
function ManagePresetDialog(parent, pref)
    local dlg = Dialog{title="Manage Presets", parent=parent}
    dlg
        :button{id="editPreset", text="Edit", onclick=function() editPresetDialog(g_currentPreset, dlg, parent) end}
        :button{id="deletePreset", text="Delete", onclick=function() showWarningDialog(parent, "Are you sure you want to delete this preset?", function() deletePreset(g_currentPreset, dlg, parent, pref) end) end}
        :button{id="deleteAllPresets", text="Delete All", onclick=function() showWarningDialog(parent, "Are you sure you want to delete all presets?", function() deleteAllPresets(dlg, parent, pref) end) end}
        :newrow{always=true}
        loadPresets(dlg, pref, false)
    dlg
        :separator()
        :button{text="Close", focus=true}
        :show()
end

-- Enables stacking if conditions are met
local function stackEnabler(dlg)
    if app.sprite ~= nil then
        if app.sprite.selection.isEmpty or app.cel == nil or Image(app.cel.image, Rectangle(app.sprite.selection.bounds.x - app.cel.bounds.x, app.sprite.selection.bounds.y - app.cel.bounds.y, app.sprite.selection.bounds.width, app.sprite.selection.bounds.height)):isEmpty() then
            dlg:modify{id="stack", enabled=false, text="Empty or no selection!"}
        else
            -- If a portion of the active sprite is selected, and it isn't empty, enable stacking
            dlg:modify{id="stack", enabled=true, text="Stack"}
        end
    else
        -- If there isn't an active sprite, show an error message
        dlg:modify{id="stack", enabled=false, text="Empty or no selection!"}
    end
end

-- Extension command and dialog
function init(plugin)
    -- Define parameter defaults
    local pref = plugin.preferences
    if pref.stackDirection == nil then pref.stackDirection = "Up" end
    if pref.stackLengthUnit == nil then pref.stackLengthUnit = "Amount" end
    if pref.stackLength == nil then pref.stackLength = 1 end
    if pref.stackXOffset == nil then pref.stackXOffset = 0 end
    if pref.stackYOffset == nil then pref.stackYOffset = 0 end
    if pref.stackPresets == nil then pref.stackPresets = {} end
    -- Stack command
    local isUIOpen = false
    local firstOpen = true
    plugin:newCommand{
        id="StackSelection",
        title="Stack",
        group="edit_transform",
        onclick=function()
            -- Add the current sprite to the visited sprites list, set the current visited sprite
            if firstOpen == true then
                g_visitedSprites[tostring(app.sprite)] = true
                firstOpen = false
            end
            -- Disable duplicate window opening
            if isUIOpen == false then
                isUIOpen = true
            else
                return nil
            end
            -- Stack dialog
            local dlg = Dialog{title="Stack Selection", onclose=function() isUIOpen=false end}
            dlg
                :separator("Direction:")
                :combobox{id="direction", option=pref.stackDirection, options={"Up","Down","Left","Right"}, onchange=function() setParameters(pref, dlg) end}
                :separator("Length:")
                :combobox{id="unit", label="Unit:", option=pref.stackLengthUnit, options={"Amount","Pixels"}, onchange=function() setParameters(pref, dlg) end}
                :number{id="length", label="Length:", text=tostring(pref.stackLength), decimals=0, onchange=function() setParameters(pref, dlg) end}
                :separator("Offsets:")
                :number{id="xoffset", label="X-Offset:", text=tostring(pref.stackXOffset), decimals=0, onchange=function() setParameters(pref, dlg) end}
                :number{id="yoffset", label="Y-Offset:", text=tostring(pref.stackYOffset), decimals=0, onchange=function() setParameters(pref, dlg) end}
                :separator("Presets:")
                :newrow{always=true}
                :button{id="newpreset", text="New Preset from Current",onclick=function() createPresetDialog(dlg, pref) end}
                :button{id="managepresets", text="Manage presets", enabled=false, onclick=function() ManagePresetDialog(dlg, pref) end}
                -- Enable the manage presets button if there are presets available
                if pref.stackPresets[1] ~= nil then
                    dlg:modify{id="managepresets", enabled=true}
                end
                loadPresets(dlg, pref, true)
            dlg
                :separator()
                :button{id="stack", enabled=false, text="Empty or no selection!", focus=false, hexpand=true, onclick=function()
                    app.transaction("Stack",
                        function()
                            -- Stack the selection
                            StackSelection(app.cel.image, dlg.data.direction, dlg.data.unit, dlg.data.length, dlg.data.xoffset, dlg.data.yoffset)
                            app.refresh()
                        end
                    )
                end
                }
                :show{wait=false, autoscrollbars=true, bounds=g_dialogBounds}
            -- If the conditions are met, enable stacking    
            stackEnabler(dlg)
            -- Whenever the sprite changes, check if the stack conditions are met
            app.sprite.events:on('change', function() stackEnabler(dlg) end)
            -- If we switch, check if the stack conditions are met
            app.events:on('sitechange', function()
                stackEnabler(dlg)
                -- If the switched to sprite doesn't have an sprite change event, add it
                if app.sprite ~= nil then
                    if g_visitedSprites[tostring(app.sprite)] == nil then
                        app.sprite.events:on('change', function() stackEnabler(dlg) end)
                    end
                end
            end)
        end,
        onenabled=function()
            -- Disable the stack command when active sprite is nil
            if app.sprite == nil then
                return false
            else
                return true
            end
        end
    }
end
