--------------------------------------------------------
-- CopyRight (C) 2025, tidusmd. All rights reserved.
-- This mod is under the MIT License.
-- https://opensource.org/licenses/mit-license.php
--------------------------------------------------------
Cron = require("External/Cron.lua")
GameUI = require("External/GameUI.lua")

local Debug = require('Debug/debug.lua')

PrivateYacht = {
    -- static --
    description = "Private Yacht",
    version = "1.0.0",
    is_ready = false,
    is_debug_mode = false,
    is_update_version = false,
    setting_path = "user_settings.json",
    native_settings_required_version = 1.96,
    delay_updating_native_settings = 0.1,
    max_number_of_av = 50,
    default_setting_table = {
        version = "",
        number_of_av = 50,
    },
    -- dynamic --
    debug_obj = nil,
    setting_table = {},
    native_settings_mod = nil,
    is_valid_native_settings = false,
    option_table_list = {},
}

registerForEvent("onTweak",function ()
    if not TweakDB:GetRecord("Vehicle.sq028_yacht_private") then
        TweakDB:CloneRecord("Vehicle.sq028_yacht_private", "Vehicle.sq028_yacht")
    end
    TweakDB:SetFlat("Vehicle.sq028_yacht_private.entityTemplatePath", "private_yacht\\entities\\sq028_yacht_vehicle_private.ent")
end)

registerForEvent('onInit', function()

    PrivateYacht.debug_obj = Debug:New()

    -- LoadSettings()
    -- SetParameter()
    -- CheckNativeSettings()

    GameUI.Observe("SessionStart", function()
        if PrivateYacht.is_debug_mode then
            Game.GetQuestsSystem():SetFactStr("mod_private_yacht_debug", 1)
        elseif Game.GetQuestsSystem():GetFactStr("mod_private_yacht_debug") == 1 then
            Game.GetQuestsSystem():SetFactStr("mod_private_yacht_debug", 0)
        end

        -- local saved_version = Game.GetQuestsSystem():GetFactStr("ats_av_traffic_version")
        -- local current_version = VersionToInt(PrivateYacht.version)
        -- if saved_version ~= current_version then
        --     Game.GetQuestsSystem():SetFactStr("ats_av_traffic_version", current_version)
        --     PrivateYacht.is_update_version = true
        -- end

        -- local saved_number_of_av = Game.GetQuestsSystem():GetFactStr("ats_av_traffic_number_of_av")
        -- local current_number_of_av = PrivateYacht.setting_table.number_of_av
        -- if saved_number_of_av ~= current_number_of_av then
        --     Game.GetQuestsSystem():SetFactStr("ats_av_traffic_number_of_av", current_number_of_av)
        --     PrivateYacht.is_update_version = true
        -- end

        -- if PrivateYacht.is_update_version or not IsTrafficLoop() then
        --     PrivateYacht.is_update_version = false
        --     StartLoop()
        -- end
        Cron.After(2, function()
            Reset()
        end)
    end)

    -- if PrivateYacht.is_valid_native_settings then
	-- 	CreateNativeSettingsBasePage()
	-- end

    print('[PrivateYacht][Info] Finished initializing Private Yacht Mod.')
end)

registerForEvent("onDraw", function()
    if PrivateYacht.is_debug_mode then
        PrivateYacht.debug_obj:ImGuiMain()
    end
end)

registerForEvent('onUpdate', function(delta)
    Cron.Update(delta)
end)

-- function IsTrafficLoop()
--     return Game.GetQuestsSystem():GetFactStr("ats_av_traffic_loop") == 1
-- end

function Reset()
    Game.GetQuestsSystem():SetFactStr("mod_private_yacht_reset", 1)
end

function ManageNumberOfAV()
    local selected_numbers = {}
    local count = PrivateYacht.max_number_of_av - PrivateYacht.setting_table.number_of_av
    local range = PrivateYacht.max_number_of_av
    local total_lock_count = 0

    if count < range / 2 then
        for i = 1, range do
            selected_numbers[i] = false
        end
        while total_lock_count < count do
            local random_number = math.random(1, range)
            if not selected_numbers[random_number] then
                selected_numbers[random_number] = true
                total_lock_count = total_lock_count + 1
            end
        end
    else
        total_lock_count = range
        for i = 1, range do
            selected_numbers[i] = true
        end
        while total_lock_count > count do
            local random_number = math.random(1, range)
            if selected_numbers[random_number] then
                selected_numbers[random_number] = false
                total_lock_count = total_lock_count - 1
            end
        end
    end

    for i = 1, range do
        if not selected_numbers[i] then
            Game.GetQuestsSystem():SetFactStr("ats_av_traffic_lock_" .. i, 0)
        else
            Game.GetQuestsSystem():SetFactStr("ats_av_traffic_lock_" .. i, 1)
        end
    end
end

function LoadSettings()
    local table = ReadJson(PrivateYacht.setting_path)
    if table == nil then
        PrivateYacht.setting_table = {}
    else
        PrivateYacht.setting_table = table
    end
end

function SetParameter()
    if PrivateYacht.setting_table.version == nil or PrivateYacht.setting_table.version ~= PrivateYacht.version then
        PrivateYacht.setting_table.version = PrivateYacht.version
        WriteJson(PrivateYacht.setting_path, PrivateYacht.setting_table)
    end
    if PrivateYacht.setting_table.number_of_av == nil then
        PrivateYacht.setting_table.number_of_av = PrivateYacht.default_setting_table.number_of_av
        WriteJson(PrivateYacht.setting_path, PrivateYacht.setting_table)
    end
end

function CheckNativeSettings()
    PrivateYacht.native_settings_mod = GetMod("nativeSettings")
    if PrivateYacht.native_settings_mod == nil then
		PrivateYacht.is_valid_native_settings = false
        return
	end
    if PrivateYacht.native_settings_mod.version < PrivateYacht.native_settings_required_version then
        PrivateYacht.is_valid_native_settings = false
        print("[PrivateYacht][Error] requires Native Settings version " .. PrivateYacht.native_settings_required_version .. " or higher.")
        return
    end
    PrivateYacht.is_valid_native_settings = true
end

function VersionToInt(version)
    local parts = {}
    for part in version:gmatch("%d+") do
        table.insert(parts, tonumber(part))
    end
    local result = 0
    for i, part in ipairs(parts) do
        result = result * 100 + part
    end
    return result
end

--- Create Native Settings Base Page.
function CreateNativeSettingsBasePage()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	PrivateYacht.native_settings_mod.addTab("/PrivateYacht", GetLocalizedText(LocKeyToString("ats-top-title")))
	PrivateYacht.native_settings_mod.registerRestoreDefaultsCallback("/PrivateYacht", true, function()
		print('[PrivateYacht][Info] Restore All Settings')
		ResetParameters()
		Cron.After(PrivateYacht.delay_updating_native_settings, function()
			UpdateNativeSettingsPage()
		end)
	end)
	CreateNativeSettingsSubCategory()
	CreateNativeSettingsPage()
end

--- Create Native Settings Sub Category
function CreateNativeSettingsSubCategory()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	PrivateYacht.native_settings_mod.addSubcategory("/PrivateYacht/general", GetLocalizedText(LocKeyToString("ats-general-subtitle")))
end

--- Clear Native Settings Sub Category
function ClearAllNativeSettingsSubCategory()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	PrivateYacht.native_settings_mod.removeSubcategory("/PrivateYacht/general")
end

--- Create Setting items.
function CreateNativeSettingsPage()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	PrivateYacht.option_table_list = {}
	local option_table

	-- general
    option_table = PrivateYacht.native_settings_mod.addRangeInt("/PrivateYacht/general", GetLocalizedText(LocKeyToString("ats-general-number-of-av-item")), GetLocalizedText(LocKeyToString("ats-general-number-of-av-description")), 0, PrivateYacht.max_number_of_av, 1, PrivateYacht.setting_table.number_of_av, PrivateYacht.default_setting_table.number_of_av, function(value)
        PrivateYacht.setting_table.number_of_av = value
        WriteJson(PrivateYacht.setting_path, PrivateYacht.setting_table)
        Cron.After(PrivateYacht.delay_updating_native_settings, function()
			UpdateNativeSettingsPage()
		end)
	end)
	table.insert(PrivateYacht.option_table_list, option_table)

    option_table = PrivateYacht.native_settings_mod.addButton("/PrivateYacht/general", GetLocalizedText(LocKeyToString("ats-general-apply-settings")), GetLocalizedText(LocKeyToString("ats-general-apply-settings-description")), GetLocalizedText(LocKeyToString("ats-general-apply-settings-button-label")), 45, function()
        Game.GetQuestsSystem():SetFactStr("ats_av_traffic_number_of_av", PrivateYacht.setting_table.number_of_av)
        StartLoop()
    end)
    table.insert(PrivateYacht.option_table_list, option_table)
end

--- Clear setting items.
function ClearNativeSettingsPage()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	for _, option_table in ipairs(PrivateYacht.option_table_list) do
		PrivateYacht.native_settings_mod.removeOption(option_table)
	end
	PrivateYacht.option_table_list = {}

	ClearAllNativeSettingsSubCategory()
end

--- Update setting items.
function UpdateNativeSettingsPage()
	ClearNativeSettingsPage()
	CreateNativeSettingsSubCategory()
	CreateNativeSettingsPage()
end

--- Reset parameters.
function ResetParameters()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
    PrivateYacht.setting_table = PrivateYacht.default_setting_table
    PrivateYacht.setting_table.version = PrivateYacht.version
    WriteJson(PrivateYacht.setting_path, PrivateYacht.setting_table)
end

--- Read json file.
function ReadJson(fill_path)
    local success, result = pcall(function()
       local file = io.open(fill_path, "r")
       if file then
            local contents = file:read("*a")
            local data = json.decode(contents)
            file:close()
            return data
       else
            print("[PrivateYacht][Info] File not found: " .. fill_path)
            return {}
       end
    end)
    if not success then
        print("[PrivateYacht][Error] Unexpected error while reading file: " .. fill_path)
        return nil
    end
    return result
end

--- Write json file.
function WriteJson(fill_path, write_data)
local success, result = pcall(function()
    local file = io.open(fill_path, "w")
    if file then
        local contents = json.encode(write_data)
        file:write(contents)
        file:close()
        return true
    else
        print("[PrivateYacht][Error] Failed to write file: " .. fill_path)
        return false
    end
end)
if not success then
    print("[PrivateYacht][Error] Unexpected error while writing file: " .. fill_path)
    return false
end
return result
end

function PrivateYacht:GetVersion()
    return PrivateYacht.version
end

function PrivateYacht:ToggleDebugMode()
    PrivateYacht.is_debug_mode = not PrivateYacht.is_debug_mode
end

function PrivateYacht:SetNumberOfAV(number)
    if type(number) ~= "number" or number < 0 or number > PrivateYacht.max_number_of_av or math.floor(number) ~= number then
        print("SetNumberOfAV must be an integer from 0 to " .. PrivateYacht.max_number_of_av)
        return
    end
    PrivateYacht.setting_table.number_of_av = number
    WriteJson(PrivateYacht.setting_path, PrivateYacht.setting_table)
    Cron.After(PrivateYacht.delay_updating_native_settings, function()
        UpdateNativeSettingsPage()
    end)
end

function PrivateYacht:GetNumberOfAV()
    return Game.GetQuestsSystem():GetFactStr("ats_av_traffic_number_of_av")
end

return PrivateYacht
