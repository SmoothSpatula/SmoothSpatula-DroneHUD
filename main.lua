-- DroneHUD v1.0.0
-- SmoothSpatula
log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)

mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 57,
        pos_y = 251,
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
local text_colour = 16777215 -- white
local bg_colour = gm.make_colour_rgb(73,74,91)

local drone_y = 0
local ratio = 0
local hp_colour = gm.make_colour_rgb(136, 211,103)

gm.post_code_execute(function(self, other, code, result, flags)
    if not gm.variable_global_get("__run_exists") then return end
    if code.name:match("oInit_Draw_7") then
            
        local players = Helper.find_active_instance_all(gm.constants.oP)
        if not players then return end
        
        local cam = gm.view_get_camera(0)
        surf_drones = gm.surface_create(gm.camera_get_view_width(cam), gm.camera_get_view_height(cam))
        gm.surface_set_target(surf_drones)
        gm.draw_clear_alpha(0, 0)
        local drones = Helper.find_active_instance_all(gm.constants.pDrone)
        -- Cycle through the drones
        for i, drone in ipairs(drones) do
            drone_y = params['pos_y'] + (i-1) * params['displacement_y']
            ratio = drone.hp/drone.maxhp
            hp_colour = gm.make_colour_rgb(136*ratio+180*(1-ratio), 211*ratio+73*(1-ratio), 103*ratio+73*(1-ratio)) -- from green at full hp to red at low hp
    
            gm.draw_rectangle_colour(params['pos_x']-53, drone_y-8, params['pos_x']+53 , drone_y+10, bg_colour, bg_colour, bg_colour, bg_colour, false) -- healthbare bg
            gm.hud_draw_health(drone, bg_colour, params['pos_x']-50, drone_y-5, 100, 12, true, hp_colour)
            gm.draw_sprite_ext(drone.sprite_index, 1, params['pos_x']+55, drone_y, 0.5, 0.5, 0.0, 16777215, 1.0) -- small drone picture
            
        end
    
        gm.surface_reset_target()
        gm.draw_surface(surf_drones, gm.camera_get_view_x(cam), gm.camera_get_view_y(cam))
        gm.surface_free(surf_drones) --do this or run out of memory
    end
end)

gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    zoom_scale = gm.prefs_get_hud_scale()
end)
