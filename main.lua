-- DroneHUD v1.0.1
-- SmoothSpatula
log.info("Successfully loaded ".._ENV["!guid"]..".")
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.hfuncs then Helper = v end end end)


local maxhp_r, maxhp_g, maxhp_b = 136, 211,103
local lowhp_r, lowhp_g, lowhp_b = 180, 73, 73
local pos_x = 57
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 57,
        pos_y = 251,
        displacement_y = 22,
        drone_hud_enabled = true,
        healthbar_alpha = 1.0,
        max_hp_colour = {136, 211,103},
        low_hp_colour = {180, 73, 73}
    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
    maxhp_r, maxhp_g, maxhp_b = math.floor(params['max_hp_colour'][1]*255), math.floor(params['max_hp_colour'][2]*255), math.floor(params['max_hp_colour'][3]*255)
    lowhp_r, lowhp_g, lowhp_b = math.floor(params['low_hp_colour'][1]*255), math.floor(params['low_hp_colour'][2]*255), math.floor(params['low_hp_colour'][3]*255)
    pos_x = params['pos_x']
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
        pos_x = new_value
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

gui.add_to_menu_bar(function()
    local new_value, isChanged = ImGui.InputFloat("Healthbar Alpha", params['healthbar_alpha'], 0.01, 0.05, "%.2f", 0)
    if isChanged and new_value >= -0.01 and new_value <= 1 then -- due to floating point precision error, checking against 0 does not work
        params['healthbar_alpha'] = math.abs(new_value) -- same as above, so it display -0.0
        Toml.save_cfg(_ENV["!guid"], params)
        redraw = true
    end
end)


gui.add_to_menu_bar(function()
    local col, used = ImGui.ColorPicker3("Max HP Colour", params['max_hp_colour'])
    if used then
        params['max_hp_colour'] = col
        Toml.save_cfg(_ENV["!guid"], params)
        maxhp_r, maxhp_g, maxhp_b = math.floor(col[1]*255), math.floor(col[2]*255), math.floor(col[3]*255)
    end
end)

gui.add_to_menu_bar(function()
    local col, used = ImGui.ColorPicker3("Low HP Colour", params['low_hp_colour'])
    if used then
        params['low_hp_colour'] = col
        Toml.save_cfg(_ENV["!guid"], params)
        lowhp_r, lowhp_g, lowhp_b = math.floor(col[1]*255), math.floor(col[2]*255), math.floor(col[3]*255)
    end
end)

-- ========== Main ==========

local surf_drones = -1
local text_colour = 16777215 -- white
local bg_colour = gm.make_colour_rgb(73,74,91)

local drone_y = 0
local ratio = 0
local hp_colour = gm.make_colour_rgb(136, 211,103)
local cam = nil


gm.post_code_execute(function(self, other, code, result, flags)
    if not gm.variable_global_get("__run_exists") then return end
    if code.name:match("oInit_Draw_7") then
        
        cam = gm.view_get_camera(0)
        surf_drones = gm.surface_create(gm.camera_get_view_width(cam), gm.camera_get_view_height(cam))
        gm.surface_set_target(surf_drones)
        gm.draw_clear_alpha(0, 0)
        gm.draw_set_alpha(params['healthbar_alpha'])
        local drones = Helper.find_active_instance_all(gm.constants.pDrone)
        -- Cycle through the drones
        drone_y = params['pos_y']
        for i, drone in ipairs(drones) do
            ratio = drone.hp/drone.maxhp
            hp_colour = gm.make_colour_rgb(maxhp_r*ratio+lowhp_r*(1-ratio),  maxhp_g*ratio+lowhp_g*(1-ratio), maxhp_b*ratio+lowhp_b*(1-ratio)) -- from green at full hp to red at low hp
            
            gm.draw_rectangle_colour(pos_x-53, drone_y-8, pos_x+53 , drone_y+10, bg_colour, bg_colour, bg_colour, bg_colour, false) -- healthbare bg
            gm.hud_draw_health(drone, bg_colour, pos_x-50, drone_y-5, 100, 12, true, hp_colour)
            gm.draw_sprite_ext(drone.sprite_index, 1, pos_x+55, drone_y, 0.5, 0.5, 0.0, 16777215, 1) -- small drone picture
            drone_y = drone_y + params['displacement_y']
        end
    
        gm.surface_reset_target()
        gm.draw_surface(surf_drones, gm.camera_get_view_x(cam), gm.camera_get_view_y(cam))
        gm.surface_free(surf_drones) --do this or run out of memory
        gm.draw_set_alpha(1)
    end
end)

gm.pre_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    zoom_scale = gm.prefs_get_hud_scale()
end)
