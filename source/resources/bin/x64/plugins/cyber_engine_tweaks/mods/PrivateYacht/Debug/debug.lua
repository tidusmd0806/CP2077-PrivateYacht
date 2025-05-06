local Debug = {}
Debug.__index = Debug

function Debug:New()
    local obj = {}

    -- set parameters
    obj.is_set_observer = false
    obj.is_im_gui_locked_number = false
    obj.spline_base_pos = { x = 0, y = 0, z = 0 }
    obj.spline_destination_pos = { x = 0, y = 0, z = 0 }
    obj.spline_pos = { x = 0, y = 0, z = 0 }
    obj.spline_pos_dest = { x = 0, y = 0, z = 0 }
    obj.is_recording = false
    obj.spline_count = 1
    obj.spline_debug_file = nil
    obj.spline_generator = nil
    obj.spline_num = 0
    obj.spline_route = 1
    obj.spline_speed = 10
    obj.spline_list_num = 0
    obj.spline_dist_offset = 0
    obj.route_decorded_json = nil

    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("PRIVATE YACHT DEBUG WINDOW")
    ImGui.Text("Version : " .. PrivateYacht.version)
    -- ImGui.Text("Saved Version : " .. Game.GetQuestsSystem():GetFactStr("ats_av_traffic_version"))
    -- ImGui.Text("Saved Number of AV : " .. Game.GetQuestsSystem():GetFactStr("ats_av_traffic_number_of_av"))

    self:SetObserver()
    self:ImGuiInputSplineNum()
    self:ImGuiInputSplineRoute()
    self:ImGuiInputSplineSpeed()
    self:ImGuiSplineRelativePosition()
    self:ImGuiPlayerPosition()
    self:ImGuiFactValue()
    -- self:ImGuiLockedNumber()
    self:ImGuiExcuteFunction()

    ImGui.End()
end

function Debug:SetObserver()
    if not self.is_set_observer then
        -- reserved
        -- Override("InteractionUIBase", "OnDialogsData", function(_, value, wrapped_method)
        --     local data = FromVariant(value)
        --     local Hubs = data.choiceHubs
        --     for i = 1, #Hubs[1].choices do
        --         print(Hubs[1].choices[i].localizedName)
        --         Hubs[1].choices[i].localizedName = "test"
        --     end
        --     data.choiceHubs = Hubs
        --     wrapped_method(ToVariant(data))
        -- end)
        -- Observe("DefaultTransition", "GetDistanceToGround;StateGameScriptInterface",
        -- ---@param scriptInterface StateGameScriptInterface
        -- function(scriptInterface)
        --     -- method has just been called
        --     print("GetDistanceToGround : ")
        -- end)

    end
    self.is_set_observer = true

    if self.is_set_observer then
        ImGui.Text("Observer : On")
    end
end

function Debug:ImGuiInputSplineNum()
    local spline_num, used = ImGui.InputInt("Num", self.spline_num)
    self.spline_num = spline_num
end

function Debug:ImGuiInputSplineRoute()
    local spline_route, used = ImGui.InputInt("Route", self.spline_route)
    self.spline_route = spline_route
end

function Debug:ImGuiInputSplineSpeed()
    local spline_speed, used = ImGui.InputInt("Speed", self.spline_speed)
    self.spline_speed = spline_speed
end

function Debug:ImGuiSplineRelativePosition()
    local x, y, z = self.spline_base_pos.x, self.spline_base_pos.y, self.spline_base_pos.z
    local player = Game.GetPlayer()
    if player == nil then
        return
    end
    local player_pos = player:GetWorldPosition()
    if player_pos == nil then
        return
    end
    self.spline_pos.x = player_pos.x - x
    self.spline_pos.y = player_pos.y - y
    self.spline_pos.z = player_pos.z - z
    ImGui.Text("Spline Relative Position : " .. self.spline_pos.x .. ", " .. self.spline_pos.y .. ", " .. self.spline_pos.z)
    self.spline_pos_dest.x = player_pos.x - self.spline_destination_pos.x
    self.spline_pos_dest.y = player_pos.y - self.spline_destination_pos.y
    self.spline_pos_dest.z = player_pos.z - self.spline_destination_pos.z
    ImGui.Text("Spline Relative Destination Position : " .. self.spline_pos_dest.x .. ", " .. self.spline_pos_dest.y .. ", " .. self.spline_pos_dest.z)
end

function Debug:ImGuiFactValue()
    local fact_db = Game.GetQuestsSystem()
    if fact_db == nil then
        return
    end
    local mod_private_yacht_enable = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_enable")
    local mod_private_yacht_route = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_route")
    local mod_private_yacht_auto = Game.GetQuestsSystem():GetFactStr("mod_private_yacht_auto")
    ImGui.Text("mod_private_yacht_enable : " .. mod_private_yacht_enable)
    ImGui.Text("mod_private_yacht_route : " .. mod_private_yacht_route)
    ImGui.Text("mod_private_yacht_auto : " .. mod_private_yacht_auto)

end

function Debug:ImGuiPlayerPosition()
    local player = Game.GetPlayer()
    if player == nil then
        return
    end
    local player_pos = player:GetWorldPosition()
    local player_angle = player:GetWorldOrientation():ToEulerAngles()
    if player_pos == nil or player_angle == nil then
        return
    end
    ImGui.Text("player position : " .. player_pos.x .. " ," .. player_pos.y .. ", " .. player_pos.z)
    ImGui.Text("player angle : " .. player_angle.roll .. " ," .. player_angle.pitch .. ", " .. player_angle.yaw)
end

function Debug:ImGuiLockedNumber()
    self.is_im_gui_locked_number = ImGui.Checkbox("[ImGui] Open Locked Number", self.is_im_gui_locked_number)
    if self.is_im_gui_locked_number then
        ImGui.Text("Locked numbers : ")
        local fact_db = Game.GetQuestsSystem()
        for i = 1, ATS.max_number_of_av do
            ImGui.Text("[" .. i .. "]" .. fact_db:GetFactStr("ats_av_traffic_lock_" .. i))
        end
    end
end

function Debug:ImGuiExcuteFunction()
    if ImGui.Button("Spline Start/Stop") then
        if self.is_recording then
            if self.spline_count < 3 then
                print("Invalid Spline Count : " .. self.spline_count)
                return
            end
            for i = #self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points, self.spline_count + 2, -1 do
                table.remove(self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points, i)
            end
            for i = #self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections, self.spline_count + 1, -1 do
                table.remove(self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections, i)
            end
            local distance = 0
            for index, point in ipairs(self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points) do
                if index == 1 then
                    point.automaticTangents = 0
                    point.continuousTangents = 0
                elseif index == 2 then
                    point.automaticTangents = 0
                    point.continuousTangents = 0
                elseif index == self.spline_count + 1 then
                    point.automaticTangents = 0
                    point.continuousTangents = 0
                    point.position.X = self.spline_destination_pos.x - self.spline_base_pos.x
                    point.position.Y = self.spline_destination_pos.y - self.spline_base_pos.y
                    point.position.Z = self.spline_destination_pos.z - self.spline_base_pos.z
                elseif index > self.spline_count + 1 then
                    break
                end
                if index > 1 then
                    local x = point.position.X - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.X
                    local y = point.position.Y - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Y
                    local z = point.position.Z - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Z
                    distance = distance + math.sqrt(x * x + y * y + z * z)
                end
            end
            local orientation_num = #self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.speedChangeSections[3]["end"] = distance - 1
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.speedChangeSections[3]["start"] = distance - 50
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.speedChangeSections[4]["end"] = distance + 100
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.speedChangeSections[4]["start"] = distance + 20
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections[orientation_num].pos = distance
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections[orientation_num].targetOrientation.Yaw = Game.GetPlayer():GetWorldOrientation():ToEulerAngles().yaw

            local encoded_json = json.encode(self.route_decorded_json)
            local f_handle = io.open("yacht_route.streamingsector.json","w")
            if f_handle == nil then
                return
            end
            f_handle:write(encoded_json)
            f_handle:close()
            self.is_recording = false
        else
            self.spline_count = 1
            self.spline_list_num = self.spline_num * 2 + self.spline_route - 2
            if self.spline_route == 1 then
                self.spline_dist_offset = 1
            elseif self.spline_route == 2 then
                self.spline_dist_offset = -1
            end
            local f_handle = io.open("yacht_route.streamingsector.json", "r")
            if f_handle == nil then
                return
            end
            self.route_decorded_json = json.decode(f_handle:read("*a"))
            f_handle:close()

            self.spline_base_pos.x = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num].Position.X
            self.spline_base_pos.y = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num].Position.Y
            self.spline_base_pos.z = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num].Position.Z
            self.spline_destination_pos.x = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num + self.spline_dist_offset].Position.X
            self.spline_destination_pos.y = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num + self.spline_dist_offset].Position.Y
            self.spline_destination_pos.z = self.route_decorded_json.Data.RootChunk.nodeData.Data[self.spline_list_num + self.spline_dist_offset].Position.Z
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.speedChangeSections[2].targetSpeed_M_P_S = self.spline_speed
            self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections[1].targetOrientation.Yaw = Game.GetPlayer():GetWorldOrientation():ToEulerAngles().yaw

            self.is_recording = true
        end
    end
    if self.is_recording then
        ImGui.Text("Recording : On")
        ImGui.Text("Current Spline Count : " .. self.spline_count)
    else
        ImGui.Text("Recording : Off")
    end
    if ImGui.Button("Spline Point (WorldSpace)") then
        self.spline_count = self.spline_count + 1
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.X = self.spline_pos.x
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.Y = self.spline_pos.y
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.Z = 0
        local distance = 0
        for index, point in ipairs(self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points) do
            if index > 1 then
                local x = point.position.X - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.X
                local y = point.position.Y - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Y
                local z = point.position.Z - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Z
                distance = distance + math.sqrt(x * x + y * y + z * z)
            end
        end
        local pos_list = {}
        pos_list["$type"] = "EulerAngles"
        pos_list.Pitch = 0
        pos_list.Roll = 0
        pos_list.Yaw = Game.GetPlayer():GetWorldOrientation():ToEulerAngles().yaw
        local orientaion_change_list = {}
        orientaion_change_list["$type"] = "worldSpeedSplineNodeOrientationChangeSection"
        orientaion_change_list.pos = distance
        orientaion_change_list.targetOrientation = pos_list
        orientaion_change_list.type = "WorldSpace"
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections[self.spline_count] = orientaion_change_list

    end
    if ImGui.Button("Spline Point (UseSplineOrientation)") then
        self.spline_count = self.spline_count + 1
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.X = self.spline_pos.x
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.Y = self.spline_pos.y
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[self.spline_count].position.Z = 0
        local distance = 0
        for index, point in ipairs(self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points) do
            if index > 1 then
                local x = point.position.X - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.X
                local y = point.position.Y - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Y
                local z = point.position.Z - self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.splineData.Data.points[index - 1].position.Z
                distance = distance + math.sqrt(x * x + y * y + z * z)
            end
        end
        local pos_list = {}
        pos_list["$type"] = "EulerAngles"
        pos_list.Pitch = 0
        pos_list.Roll = 0
        pos_list.Yaw = Game.GetPlayer():GetWorldOrientation():ToEulerAngles().yaw
        local orientaion_change_list = {}
        orientaion_change_list["$type"] = "worldSpeedSplineNodeOrientationChangeSection"
        orientaion_change_list.pos = distance
        orientaion_change_list.targetOrientation = pos_list
        orientaion_change_list.type = "UseSplineOrientation"
        self.route_decorded_json.Data.RootChunk.nodes[self.spline_list_num].Data.orientationChangeSections[self.spline_count] = orientaion_change_list
    end
    ImGui.Separator()
    ImGui.Separator()
    ImGui.Separator()
    if ImGui.Button("ToggleActivation") then
        ToggleActivation()
        if Game.GetQuestsSystem():GetFactStr("mod_private_yacht_enable") == 1 then
            print("Enable")
        else
            print("Disable")
        end
    end
    if ImGui.Button("ToggleAuto") then
        ToggleAuto()
        if Game.GetQuestsSystem():GetFactStr("mod_private_yacht_auto") == 1 then
            print("Auto")
        else
            print("Manual")
        end
    end
    if ImGui.Button("Reset") then
        Reset()
        print("Reset")
    end
    ImGui.SameLine()
    -- if ImGui.Button("Delete Settings") then
    --     io.open(ATS.setting_path, "w"):close()
    --     print("Delete Settings")
    -- end

end

return Debug