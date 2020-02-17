xrTextureSectionNames = {
    "keyboard",
    "ui_actor_achivments",
    "ui_actor_armor",
    "ui_actor_dialog_screen",
    "ui_actor_hint_wnd",
    "ui_actor_main_menu",
    "ui_actor_main_menu_options",
    "ui_actor_menu",
    "ui_actor_mp_buyscreen",
    "ui_actor_mp_hud",
    "ui_actor_mp_ingame_menu",
    "ui_actor_mp_screen",
    "ui_actor_multiplayer_menu_screen",
    "ui_actor_newsmanager_icons",
    "ui_actor_pda",
    "ui_actor_pda_icons",
    "ui_actor_portrets",
    "ui_actor_sleep_screen",
    "ui_actor_upgrades",
    "ui_actor_upgrades_armor",
    "ui_alife",
    "ui_asus_intro",
    "ui_buy_menu",
    "ui_common",
    "ui_hud",
    "ui_iconstotal",
    "ui_icons_map",
    "ui_icons_npc",
    "ui_icon_equipment",
    "ui_ingame",
    "ui_ingame2_back_01",
    "ui_ingame2_back_02",
    "ui_ingame2_back_03",
    "ui_ingame2_back_add2_w",
    "ui_ingame2_back_add3_w",
    "ui_ingame2_back_add_w",
    "ui_ingame2_common",
    "ui_inventory",
    "ui_inventory2",
    "ui_logos",
    "ui_magnifier2",
    "ui_mainmenu",
    "ui_mainmenu2",
    "ui_map_description",
    "ui_models_multiplayer",
    "ui_monsters_pda",
    "ui_mp_achivements",
    "ui_mp_icon_rank",
    "ui_mp_main",
    "ui_npc_monster",
    "ui_npc_unique",
    "ui_numpad",
    "ui_old_textures",
    "ui_pda",
    "ui_pda2",
    "ui_pda2_noice",
    "ui_statistics",
    "ui_team_logo",
    "ui_team_logo_small",
    "ui_test_slideshow_1",
    "ui_test_slideshow_2"
}

xrTextureSections = {

}

--[[
    TextureSection
]]
TextureSection = {

}
TextureSectionMT = {
    __index = TextureSection
}

function TextureSection:draw( texturesDict, x, y, width, height, color )
    local tex = texturesDict[ self.tex ]
    if tex then
        dxDrawImageSection( x, y, width, height, self.x, self.y, self.width, self.height, tex, 0, 0, 0, color )
    end
end

function TextureSection:drawSection( texturesDict, x, y, width, height, u, v, us, vs )
    local tex = texturesDict[ self.tex ]
    if tex then
        dxDrawImageSection( x, y, width, height, u, v, us, vs, tex )
    end
end

function TextureSection:drawProgress( texturesDict, x, y, width, height, progress )
    local tex = texturesDict[ self.tex ]
    if tex then
        dxDrawImageSection( x, y, width * progress, height, self.x, self.y, self.width * progress, self.height, tex )
    end
end

local function xrLoadTextureDescriptor( xmlnode )
    local name = xmlNodeGetAttribute( xmlnode, "name" )

    for _, child in ipairs( xmlNodeGetChildren( xmlnode ) ) do
        if xmlNodeGetName( child ) == "texture" then
            local id = xmlNodeGetAttribute( child, "id" )
            local x = tonumber( xmlNodeGetAttribute( child, "x" ) )
            local y = tonumber( xmlNodeGetAttribute( child, "y" ) )
            local width = tonumber( xmlNodeGetAttribute( child, "width" ) )
            local height = tonumber( xmlNodeGetAttribute( child, "height" ) )

            local section = {
                tex = name,
                x = x, y = y,
                width = width, height = height
            }

            xrTextureSections[ id ] = setmetatable( section, TextureSectionMT )
        end
    end
end

function xrLoadUIFileDescriptor( name )
    local filename = ":xrcore/config/ui/textures_descr/" .. name .. ".xml"
    
    local xml = xmlLoadFile( filename, true )
    if not xml then
        return false
    end

    for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
        if xmlNodeGetName( child ) == "file" then
            xrLoadTextureDescriptor( child )
        end
    end

    xmlUnloadFile( xml )

    return true
end

function xrLoadAllUIFileDescriptors()
    for _, name in ipairs( xrTextureSectionNames ) do
        xrLoadUIFileDescriptor( name )
    end
end