-- DroneHUD v1.0.4
-- SmoothSpatula
log.info("Successfully loaded ".._ENV["!guid"]..".")
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

local maxhp_r, maxhp_g, maxhp_b = 136, 211,103
local lowhp_r, lowhp_g, lowhp_b = 180, 73, 73
local pos_x = 57
local displacement_y = 22
mods.on_all_mods_loaded(function() for k, v in pairs(mods) do if type(v) == "table" and v.tomlfuncs then Toml = v end end 
    params = {
        pos_x = 57,
        pos_y = 251,
        displacement_y = 22,
        drone_hud_enabled = true,
        dynamic_displacement_y = true,
        healthbar_alpha = 1.0,
        maxhp_colour = {136/255, 211/255,103/255},
        lowhp_colour = {180/255, 73/255, 73/255},

    }
    params = Toml.config_update(_ENV["!guid"], params) -- Load Save
    maxhp_r, maxhp_g, maxhp_b = math.floor(params['maxhp_colour'][1]*255), math.floor(params['maxhp_colour'][2]*255), math.floor(params['maxhp_colour'][3]*255)
    lowhp_r, lowhp_g, lowhp_b = math.floor(params['lowhp_colour'][1]*255), math.floor(params['lowhp_colour'][2]*255), math.floor(params['lowhp_colour'][3]*255)
    pos_x = params['pos_x']
end)

-- ========== ImGui ==========

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Drone HUD", params['drone_hud_enabled'])
    if clicked then
        params['drone_hud_enabled'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.Checkbox("Enable Dynamic Height Resizing", params['dynamic_displacement_y'])
    if clicked then
        params['dynamic_displacement_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
    displacement_y = params['displacement_y']
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("X position from the  left part of the screen", params['pos_x'], 1, 0, gm.display_get_gui_width())
    if clicked then
        params['pos_x'] = new_value   
        pos_x = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y position from the top part of the screen", params['pos_y'], 1, 0, gm.display_get_gui_height())
    if clicked then
        params['pos_y'] = new_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)

gui.add_to_menu_bar(function()
    local new_value, clicked = ImGui.DragInt("Y distance between each Healthbar", params['displacement_y'], 1, 0, 200)
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
    local col, used = ImGui.ColorPicker3("Max HP Colour", params['maxhp_colour'])
    if used then
        params['maxhp_colour'] = col
        Toml.save_cfg(_ENV["!guid"], params)
        maxhp_r, maxhp_g, maxhp_b = math.floor(col[1]*255), math.floor(col[2]*255), math.floor(col[3]*255)
    end
end)

gui.add_to_menu_bar(function()
    local col, used = ImGui.ColorPicker3("Low HP Colour", params['lowhp_colour'])
    if used then
        params['lowhp_colour'] = col
        Toml.save_cfg(_ENV["!guid"], params)
        lowhp_r, lowhp_g, lowhp_b = math.floor(col[1]*255), math.floor(col[2]*255), math.floor(col[3]*255)
    end
end)

-- ========== Main ==========

local text_colour = Color.WHITE -- white
local bg_colour = Color.from_rgb(73,74,91)

local friend_y = 0
local ratio = 0
local hp_colour = Color.from_rgb(136, 211,103)
local hud_scale = 1.0
local options_menu = false
local sprite_scale = 0.5
local chat_open = false
local drone_count = 0
local screen_height = 1080


local draw_drones = function()
    local friends = Instance.find_all(gm.constants.pFriend)
    -- Cycle through the friends
    friend_y = params['pos_y']
    drone_count = 0
    for i, friend in ipairs(friends) do
        friend = friend.value
        drone_count = drone_count + 1
        if friend.user_name == nil then
            ratio = friend.hp/friend.maxhp

            local r = math.floor(maxhp_r*ratio+lowhp_r*(1-ratio))
            local g = math.floor(maxhp_g*ratio+lowhp_g*(1-ratio))
            local b = math.floor(maxhp_b*ratio+lowhp_b*(1-ratio))
            hp_colour = Color.from_rgb(r, g, b)

            gm.draw_rectangle_colour(pos_x-53, (friend_y-8)*hud_scale, (pos_x+53)*hud_scale , (friend_y+10)*hud_scale, bg_colour, bg_colour, bg_colour, bg_colour, false) -- healthbare bg
            gm.hud_draw_health(friend, bg_colour, (pos_x-50), (friend_y-5)*hud_scale, 100*hud_scale, 12*hud_scale, false, hp_colour)

            if friend.sprite_index2 ~= nil then
                gm.draw_sprite_ext(friend.sprite_index2, 1, (pos_x+55)*hud_scale, friend_y*hud_scale, sprite_scale, sprite_scale, 0.0, Color.WHITE, 1) -- small friend picture
            end
            gm.draw_sprite_ext(friend.sprite_index, 1, (pos_x+55)*hud_scale, friend_y*hud_scale, sprite_scale, sprite_scale, 0.0, Color.WHITE, 1) -- small friend picture
            gm.draw_set_font(5)
            gm.draw_text_transformed(
                math.floor(pos_x+26)*hud_scale,
                (friend_y + 10) * hud_scale - 5,
                math.floor(friend.hp).."/"..math.floor(friend.maxhp),
                hud_scale,
                hud_scale,
                0)
            friend_y = friend_y + displacement_y
        end
    end
    if params['dynamic_displacement_y'] then
        screen_height = gm.camera_get_view_height(gm.view_get_camera(0))
        if screen_height < (friend_y) * hud_scale and displacement_y > 4 then 
            displacement_y = displacement_y - 1
        elseif screen_height > (friend_y+drone_count) * hud_scale and displacement_y <params["displacement_y"] then
            displacement_y = displacement_y + 1
        end
    end
end

-- fast post code execute
gm.post_code_execute("gml_Object_oInit_Draw_64", function(self, other)
    if gm.variable_global_get("__run_exists") and not self.chat_talking and params['drone_hud_enabled'] then
        draw_drones()
    end
end)

-- check when scale is changed
gm.pre_script_hook(gm.constants.prefs_set_hud_scale, function(self, other, result, args)
    hud_scale = args[1].value
    sprite_scale = hud_scale*0.5
end)

-- get params on loading level
gm.post_script_hook(gm.constants.stage_load_room, function(self, other, result, args)
    hud_scale = gm.prefs_get_hud_scale() 
    sprite_scale = hud_scale*0.5
    displacement_y = params['displacement_y']
end)

-- disable overlay when opening options
gm.post_script_hook(gm.constants.UIOptionsGroupHeader, function(self, other, result, args)
    options_menu = true
end)

-- reenable overlay when quit options
gm.post_script_hook(gm.constants.save_prefs, function(self, other, result, args)
    options_menu = false
end)
