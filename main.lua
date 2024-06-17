-- DroneHUD v1.0.0
-- SmoothSpatula
log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 50,
        pos_y = 100,
        scale = 1.0,
        displacement_y = 22,
        drone_hud_enabled = true,
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
end)

-- ========== ImGui ==========

local zoom_scale = 1.0
gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Drone HUD", params['drone_hud_enabled'])
    if clicked then
        params['drone_hud_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("X position from the  left part of the screen", params['pos_x'], 1, 0, gm.display_get_gui_width()//zoom_scale)
    if clicked then
        params['pos_x'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y position from the top part of the screen", params['pos_y'], 1, 0, gm.display_get_gui_height()//zoom_scale)
    if clicked then
        params['pos_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y distance between each Healthbar", params['displacement_y'], 1, 0, gm.display_get_gui_height()//zoom_scale)
    if clicked then
        params['displacement_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

-- ========== Main ==========

local surf_drones = -1
local text_colour = gm.make_colour_rgb(0, 0, 0)
local bg_colour = gm.make_colour_rgb(73,74,91)

gm.post_code_execute(function(self, other, code, result, flags)
    if not gm.variable_global_get("__run_exists") then return end
    if code.name:match("oInit_Draw_7") then
            
        local players = Helper.find_active_instance_all(gm.constants.oP)
        if not players then return end
        
        local cam = gm.view_get_camera(0)
        surf_drones = gm.surface_create(gm.camera_get_view_width(cam), gm.camera_get_view_height(cam))
        gm.surface_set_target(surf_drones)
        gm.draw_clear_alpha(0, 0) --put this here because I can't draw it with the map
        local drones = Helper.find_active_instance_all(gm.constants.pDrone) 
        -- Display the players
        for i, drone in ipairs(drones) do
            local drone_x = params['pos_x']
            local drone_y = params['pos_y'] + (i-1) * params['displacement_y']
            local ratio = drone.hp/drone.maxhp
            local hp_colour = gm.make_colour_rgb(255*(1-ratio), 255*ratio, 0)
    
            gm.draw_rectangle_colour(drone_x-53, drone_y-8, drone_x+53 , drone_y+10, bg_colour, bg_colour, bg_colour, bg_colour, false)
            gm.draw_rectangle_colour(drone_x-50, drone_y-5, drone_x-50 + 100*ratio, drone_y+7, hp_colour, hp_colour, hp_colour, hp_colour, false)
            gm.draw_text_colour(drone_x, drone_y, drone.name, text_colour, text_colour, text_colour, text_colour, 1)
            
        end
    
        gm.surface_reset_target()
        gm.draw_surface(surf_drones, gm.camera_get_view_x(cam), gm.camera_get_view_y(cam))
        gm.surface_free(surf_drones) --do this or run out of memory
    end
end)

gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    zoom_scale = gm.prefs_get_hud_scale()
end)


-- Testing stuff

-- gui.add_always_draw_imgui(function()
--     if ImGui.IsKeyPressed(80) then --P
--         -- local player = Helper.get_client_player()
--         local drones = Helper.find_active_instance_all(gm.constants.pDrone)
--         for _,drone in ipairs(drones) do
--             print(drone.object_name)
--             print(drone.name)
--             print(drone.hp.." / "..drone.maxhp)
--             print(drone.sprite_idle)
--             print(drone.sprite_index)
--         end
--         print("P")


--         local pl = Helper.get_client_player()
--         --pl.image_xscale = 0.5
--         --pl.image_yscale = 0.5
--         --pl.ystart = 20
--         --pl.xstart = -20
--     end
-- end)


-- local filename = "skills.txt"
-- local skills = gm.variable_global_get("class_skill")
-- i = 215
-- io.open(filename,"w"):close()
-- file = io.open(filename, "a")
-- file:write("Sprites dump new\n\n")
-- --string.gmatch(tostring(skills[i][3]), '%.()%.')
-- while i<300 do
--     --if skills[i] ==
--     local str = tostring(skills[i][2])
--     print(i.. " - "..str.. "\n")
--     file:write(i.. " - "..str.. "\n")
--     i = i + 1
-- end

--some bosses have enough attacks
-- Imp Overlord -procs with skills
-- gm.actor_skill_set(player, 0, 169) -- proc
-- gm.actor_skill_set(player, 1, 171) -- proc
-- gm.actor_skill_set(player, 2, 172) -- movement
-- gm.actor_skill_set(player, 3, 173) -- proc


-- Sprite index


-- 312 new boss jump
-- 464, 670,  cool animation
-- 672 invisible

--587, 589, 590, 596, 600 tower giant guy

-- 930 --before a bit Scavenger walk idle

-- 1040~ providence anims

-- 1211~ numbers


-- Scavenger guy 
-- gm.actor_skill_set(player, 0, 174) -- no proc
-- gm.actor_skill_set(player, 1, 175) -- procs
-- gm.actor_skill_set(player, 2, 176) -- no proc
-- gm.actor_skill_set(player, 3, 177) -- no proc


-- gm.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
--     print(result.value)
--     if not result.value.player_id then
--         result.value.sprite_index = math.random(1, 2000)
--     end
-- end)