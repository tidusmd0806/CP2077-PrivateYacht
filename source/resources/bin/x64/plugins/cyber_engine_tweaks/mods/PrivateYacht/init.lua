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
    -- is_update_version = false,
    native_settings_required_version = 1.96,
    delay_updating_native_settings = 0.1,
    -- dynamic --
    debug_obj = nil,
    -- setting_table = {},
    native_settings_mod = nil,
    is_valid_native_settings = false,
    option_table_list = {},
    is_enabled = true,
    is_automode = false
}

registerForEvent("onTweak",function ()
    if not TweakDB:GetRecord("Vehicle.sq028_yacht_private") then
        TweakDB:CloneRecord("Vehicle.sq028_yacht_private", "Vehicle.sq028_yacht")
    end
    TweakDB:SetFlat("Vehicle.sq028_yacht_private.entityTemplatePath", "private_yacht\\entities\\sq028_yacht_vehicle_private.ent")
end)

registerForEvent('onInit', function()

    PrivateYacht.debug_obj = Debug:New()

    CheckNativeSettings()

    GameUI.Observe("SessionStart", function()
        if PrivateYacht.is_debug_mode then
            Game.GetQuestsSystem():SetFactStr("mod_private_yacht_debug", 1)
        elseif Game.GetQuestsSystem():GetFactStr("mod_private_yacht_debug") == 1 then
            Game.GetQuestsSystem():SetFactStr("mod_private_yacht_debug", 0)
        end

        PrivateYacht.is_enabled = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_enable")
        PrivateYacht.is_automode = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_auto")

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
        -- Cron.After(2, function()
        --     PrivateYacht:Reset()
        -- end)
    end)

    if PrivateYacht.is_valid_native_settings then
		CreateNativeSettingsBasePage()
	end

    PrivateYacht.is_ready = true
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

function PrivateYacht:Reset()
    Game.GetQuestsSystem():SetFactStr("mod_private_yacht_reset", 1)
end

function PrivateYacht:ToggleActivation()
    if Game.GetQuestsSystem():GetFactStr("mod_private_yacht_enable") == 1 then
        Game.GetQuestsSystem():SetFactStr("mod_private_yacht_enable", 0)
    else
        Game.GetQuestsSystem():SetFactStr("mod_private_yacht_enable", 1)
    end
    PrivateYacht:Reset()
end

function PrivateYacht:ToggleAuto()
    if Game.GetQuestsSystem():GetFactStr("mod_private_yacht_auto") == 1 then
        Game.GetQuestsSystem():SetFactStr("mod_private_yacht_auto", 0)
    else
        Game.GetQuestsSystem():SetFactStr("mod_private_yacht_auto", 1)
    end
    PrivateYacht:Reset()
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

--- Create Native Settings Base Page.
function CreateNativeSettingsBasePage()
	if not PrivateYacht.is_valid_native_settings then
		return
	end
	PrivateYacht.native_settings_mod.addTab("/PrivateYacht", GetLocalizedText(LocKeyToString("private-yacht-top-title")))
	PrivateYacht.native_settings_mod.registerRestoreDefaultsCallback("/PrivateYacht", true, function()
		print('[PrivateYacht][Info] Restore All Settings')
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
	PrivateYacht.native_settings_mod.addSubcategory("/PrivateYacht/general", GetLocalizedText(LocKeyToString("private-yacht-general-subtitle")))
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
    PrivateYacht.is_enabled = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_enable")
    option_table = PrivateYacht.native_settings_mod.addSwitch("/PrivateYacht/general", GetLocalizedText(LocKeyToString("private-yacht-general-activation")), GetLocalizedText(LocKeyToString("private-yacht-general-activation-description")), PrivateYacht.is_enabled, PrivateYacht.is_enabled, function(state)
        if state ~= PrivateYacht.is_enabled then
            PrivateYacht:ToggleActivation()
        end
        Cron.After(PrivateYacht.delay_updating_native_settings, function()
			UpdateNativeSettingsPage()
		end)
	end)
	table.insert(PrivateYacht.option_table_list, option_table)

    PrivateYacht.is_automode = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_auto")
    option_table = PrivateYacht.native_settings_mod.addSwitch("/PrivateYacht/general", GetLocalizedText(LocKeyToString("private-yacht-general-automode")), GetLocalizedText(LocKeyToString("private-yacht-general-automode-description")), PrivateYacht.is_automode, PrivateYacht.is_automode, function(state)
        if state ~= PrivateYacht.is_automode then
            PrivateYacht:ToggleAuto()
        end
        Cron.After(PrivateYacht.delay_updating_native_settings, function()
			UpdateNativeSettingsPage()
		end)
	end)
	table.insert(PrivateYacht.option_table_list, option_table)

    option_table = PrivateYacht.native_settings_mod.addButton("/PrivateYacht/general", GetLocalizedText(LocKeyToString("private-yacht-general-reset")), GetLocalizedText(LocKeyToString("private-yacht-general-reset-description")), GetLocalizedText(LocKeyToString("private-yacht-general-reset-button-label")), 45, function()
        PrivateYacht:Reset()
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

function PrivateYacht:GetVersion()
    return PrivateYacht.version
end

function PrivateYacht:ToggleDebugMode()
    PrivateYacht.is_debug_mode = not PrivateYacht.is_debug_mode
end

return PrivateYacht
