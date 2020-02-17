function guiComboBoxAdjustHeight ( combobox, itemcount )
    if getElementType ( combobox ) ~= "gui-combobox" or type ( itemcount ) ~= "number" then error ( "Invalid arguments @ 'guiComboBoxAdjustHeight'", 2 ) end
    local width = guiGetSize ( combobox, false )
    return guiSetSize ( combobox, width, ( itemcount * 20 ) + 20, false )
end

function dxDrawLineRect( x, y, width, height, color, thickness, postGUI )
    dxDrawLine( x, y, x + width, y, color, thickness, postGUI )
    dxDrawLine( x + width, y, x + width, y + height, color, thickness, postGUI )
    dxDrawLine( x + width, y + height, x, y + height, color, thickness, postGUI )
    dxDrawLine( x, y + height, x, y, color, thickness, postGUI )
end

function isPointInRect( ax, ay, wx, wy, ww, wh )
    return ax >= wx and ax <= wx + ww and ay >= wy and ay <= wy + wh
end

function xmlNodeGetColor( xml, name, default )
	local value = xmlNodeGetAttribute( xml, name )
	if type( value ) ~= "string" then
		return default
	end

	local x = tonumber( gettok( value, 1, ' ' ) )
	local y = tonumber( gettok( value, 2, ' ' ) )
	local z = tonumber( gettok( value, 3, ' ' ) )
	if x and y and z then
		return { x, y, z }
	end

	outputDebugString( "Параметр типа Vector3 " .. tostring( name ) .. " был прочитан с ошибкой!", 2 )
	return default
end


xrTextureSectionNames = {
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

xrTextureDescriptors = {

}

HULL_MODE_STRETCH = 1
HULL_MODE_EMPLACE = 2

xrHullModeNames = {
    [ "stretch" ] = 1,
    [ "emplace" ] = 2
}

--[[
    TextureSection
]]
TextureSection = {

}
TextureSectionMT = {
    __index = TextureSection
}

function TextureSection:draw( tex, x, y, width, height, rot, rotOffsetX, rotOffsetY, color )
    dxDrawImageSection( x, y, width, height, self.x, self.y, self.width, self.height, tex, rot, rotOffsetX, rotOffsetY, color )
end

function TextureSection:drawSection( tex, x, y, width, height, u, v, us, vs, rot, rotOffsetX, rotOffsetY, color )
    dxDrawImageSection( x, y, width, height, u, v, us, vs, tex, rot, rotOffsetX, rotOffsetY, color )
end

function TextureSection:drawProgress( tex, x, y, width, height, progressWidth, progressHeight )
    progressWidth = tonumber( progressWidth ) or 1
    progressHeight = tonumber( progressHeight ) or 1

    dxDrawImageSection( x, y, width * progressWidth, height * progressHeight, self.x, self.y, self.width * progressWidth, self.height * progressHeight, tex )
end

--[[
    HullFactory
]]
HullPatternFactory = {

}

function HullPatternFactory:create( typeName )
    local pattern = nil

    if typeName == "full" then
        pattern = HullPatternFull:new()
    elseif typeName == "strip" then
        pattern = HullPatternStrip:new()
    end

    if pattern then
        return pattern
    end

    outputDebugString( "Ошибка при создании паттерна", 2 )
    return false
end

--[[
    HullPattern
]]
HullPattern = {
    typeName = "pattern"
}
HullPatternMT = {
    __index = HullPattern
}

function HullPattern:load( xmlnode )
    local elements = self.elements
    local nodeNames = self.nodeNames

    local boxMinX
    local boxMinY
    local boxMaxX
    local boxMaxY

    for _, child in ipairs( xmlNodeGetChildren( xmlnode ) ) do
        local childName = xmlNodeGetName( child )
        local suffixName = nodeNames[ childName ]

        if childName == "texture" or suffixName then
            local x = tonumber( xmlNodeGetAttribute( child, "x" ) )
            local y = tonumber( xmlNodeGetAttribute( child, "y" ) )
            local width = tonumber( xmlNodeGetAttribute( child, "width" ) )
            local height = tonumber( xmlNodeGetAttribute( child, "height" ) )

            local section = {
                x = x, y = y,
                width = width, height = height
            }

            --[[
                Костыль для чтения старых версий дескрипторов
            ]]
            if childName == "texture" then
                local id = xmlNodeGetAttribute( child, "id" )
                suffixName = string.sub( id, string.len( self.id ) + 1 )
            end

            elements[ suffixName ] = setmetatable( section, TextureSectionMT )

            boxMinX = math.min( boxMinX or x, x )
            boxMinY = math.min( boxMinY or y, y )
            boxMaxX = math.max( boxMaxX or ( x + width ), ( x + width ) )
            boxMaxY = math.max( boxMaxY or ( y + height ), ( y + height ) )
        end
    end

    if boxMaxX and boxMaxY then
        self.x = boxMinX
        self.y = boxMinY
        self.width = boxMaxX - boxMinX
        self.height = boxMaxY - boxMinY
    end
end

--[[
    HullPatternFull
]]
HullPatternFull = {
    typeName = "full",
    nodeNames = {
        [ "left_top" ] = "_lt",
        [ "left" ] = "_l",
        [ "left_bottom" ] = "_lb",
        [ "top" ] = "_t",
        [ "back" ] = "_back",
        [ "bottom" ] = "_b",
        [ "right_top" ] = "_rt",
        [ "right" ] = "_r",
        [ "right_bottom" ] = "_rb"
    }
}
HullPatternFullMT = {
    __index = HullPatternFull
}
setmetatable( HullPatternFull, HullPatternMT )

function HullPatternFull:new()
    local pattern = {
        elements = {},
        x = 0, y = 0,
        width = 0, height = 0,
        mode = HULL_MODE_STRETCH
    }

    return setmetatable( pattern, HullPatternFullMT )
end

function HullPatternFull:draw( tex, px, py, pwidth, pheight, rot, rotOffsetX, rotOffsetY, color )
    local elements = self.elements

    local corner = elements._lt
    local horizontal = elements._t
    local vertical = elements._l
    local back = elements._back

    local x = px
    local y = py

    -- Top left fragment
    local fragment = elements._lt
    if fragment then
        fragment:draw( tex, x, y, corner.width, corner.height )
    end
    -- Top fragment
    x = x + corner.width
    local width = pwidth - corner.width*2
    fragment = elements._t
    if fragment then
        if self.mode == HULL_MODE_EMPLACE then     
            local integerPartsNum = math.max( math.floor( width / fragment.width ), 0 )
            local _x = x
            for i = 1, integerPartsNum do
                fragment:draw( tex, _x, y, fragment.width, fragment.height )
                _x = _x + fragment.width
            end
            
            local fractionPartWidth = math.max( width - integerPartsNum*fragment.width, 0 )
            fragment:drawProgress( tex, _x, y, fragment.width, corner.height, fractionPartWidth / fragment.width, 1 )
        else        
            fragment:draw( tex, x, y, width, corner.height )
        end
    end
    -- Top right fragment
    x = x + width
    fragment = elements._rt
    if fragment then
        fragment:draw( tex, x, y, corner.width, corner.height )
    end
    -- Left fragment
    x = px
    y = y + corner.height
    local height = pheight - corner.height*2
    fragment = elements._l
    if fragment then      
        if self.mode == HULL_MODE_EMPLACE then     
            local integerPartsNum = math.max( math.floor( height / fragment.height ), 0 )
            local _y = y
            for i = 1, integerPartsNum do
                fragment:draw( tex, x, _y, fragment.width, fragment.height )
                _y = _y + fragment.height
            end

            local fractionPartHeight = math.max( height - integerPartsNum*fragment.height, 0 )
            fragment:drawProgress( tex, x, _y, vertical.width, fragment.height, 1, fractionPartHeight / fragment.height )
        else     
            fragment:draw( tex, x, y, vertical.width, height )
        end
    end
    -- Back
    x = x + vertical.width
    fragment = elements._back
    if fragment then       
        if self.mode == HULL_MODE_EMPLACE then     
            local integerPartsHorNum = math.max( math.floor( width / fragment.width ), 0 )
            local integerPartsVertNum = math.max( math.floor( height / fragment.height ), 0 )

            local _x = x
            local _y = y
            for i = 1, integerPartsVertNum do
                _x = x
                for j = 1, integerPartsHorNum do
                    fragment:draw( tex, _x, _y, fragment.width, fragment.height )
                    _x = _x + fragment.width
                end
                _y = _y + fragment.height
            end

            local fractionPartWidth = math.max( width - integerPartsHorNum*fragment.width, 0 )
            local fractionPartHeight = math.max( height - integerPartsVertNum*fragment.height, 0 )

            _y = y
            for i = 1, integerPartsVertNum do
                fragment:drawProgress( tex, _x, _y, fragment.width, fragment.height, fractionPartWidth / fragment.width, 1 )
                _y = _y + fragment.height
            end
            _x = x
            for i = 1, integerPartsHorNum do
                fragment:drawProgress( tex, _x, _y, fragment.width, fragment.height, 1, fractionPartHeight / fragment.height )
                _x = _x + fragment.width
            end
            fragment:drawProgress( tex, _x, _y, fragment.width, fragment.height, fractionPartWidth / fragment.width, fractionPartHeight / fragment.height )
        else  
            fragment:draw( tex, x, y, width, height )
        end
    end
    -- Right fragment
    x = x + width
    fragment = elements._r
    if fragment then
        if self.mode == HULL_MODE_EMPLACE then     
            local integerPartsNum = math.max( math.floor( height / fragment.height ), 0 )
            local _y = y
            for i = 1, integerPartsNum do
                fragment:draw( tex, x, _y, fragment.width, fragment.height )
                _y = _y + fragment.height
            end

            local fractionPartHeight = math.max( height - integerPartsNum*fragment.height, 0 )
            fragment:drawProgress( tex, x, _y, vertical.width, fragment.height, 1, fractionPartHeight / fragment.height )
        else
            fragment:draw( tex, x, y, vertical.width, height )
        end
    end
    -- Bottom left
    x = px
    y = y + height
    fragment = elements._lb
    if fragment then
        fragment:draw( tex, x, y, corner.width, corner.height )
    end
    -- Bottom
    x = x + corner.width
    fragment = elements._b
    if fragment then         
        if self.mode == HULL_MODE_EMPLACE then     
            local integerPartsNum = math.max( math.floor( width / fragment.width ), 0 )
            local _x = x
            for i = 1, integerPartsNum do
                fragment:draw( tex, _x, y, fragment.width, fragment.height )
                _x = _x + fragment.width
            end

            local fractionPartWidth = math.max( width - integerPartsNum*fragment.width, 0 )
            fragment:drawProgress( tex, _x, y, fragment.width, corner.height, fractionPartWidth / fragment.width, 1 )
        else   
            fragment:draw( tex, x, y, width, horizontal.height )
        end
    end
    -- Bottom right
    x = x + width
    fragment = elements._rb
    if fragment then
        fragment:draw( tex, x, y, corner.width, corner.height )
    end
end

--[[
    HullPatternStrip
]]
HullPatternStrip = {
    typeName = "strip",
    nodeNames = {
        [ "left" ] = "_b",
        [ "back" ] = "_back",
        [ "right" ] = "_e"
    }
}
HullPatternStripMT = {
    __index = HullPatternStrip
}  
setmetatable( HullPatternStrip, HullPatternMT )

function HullPatternStrip:new()
    local pattern = {
        elements = {},
        x = 0, y = 0,
        width = 0, height = 0,
        vertical = false,
        mode = HULL_MODE_STRETCH
    }

    return setmetatable( pattern, HullPatternStripMT )
end

function HullPatternStrip:load( xmlnode )
    self.vertical = xmlNodeGetAttribute( xmlnode, "vertical" ) == "true"
    
    HullPattern.load( self, xmlnode )
end

function HullPatternStrip:draw( tex, px, py, pwidth, pheight, rot, rotOffsetX, rotOffsetY, color )
    local vertical = self.vertical
    local elements = self.elements    

    local cornerLeft = elements._b
    local cornerRight = elements._e

    local x = px
    local y = py
    local width = pwidth
    local height = pheight

    local fragment = elements._b
    if fragment then
        if vertical then
            fragment:draw( tex, x, y, width, cornerLeft.height )
        else
            fragment:draw( tex, x, y, cornerLeft.width, height )
        end
    end
    fragment = elements._back
    if fragment then
        if vertical then
            local fragmentHeight = height - cornerLeft.height - cornerRight.height
            local _y = y + cornerLeft.height

            if self.mode == HULL_MODE_EMPLACE then     
                local integerPartsNum = math.max( math.floor( fragmentHeight / fragment.height ), 0 )
                for i = 1, integerPartsNum do
                    fragment:draw( tex, x, _y, width, fragment.height )
                    _y = _y + fragment.height
                end
                
                local fractionPartHeight = math.max( fragmentHeight - integerPartsNum*fragment.height, 0 )
                fragment:drawProgress( tex, x, _y, width, fragment.height, 1, fractionPartHeight / fragment.height )
            else
                fragment:draw( tex, x, _y, width, fragmentHeight )
            end
        else
            local fragmentWidth = width - cornerLeft.width - cornerRight.width
            local _x = x + cornerLeft.width

            if self.mode == HULL_MODE_EMPLACE then     
                local integerPartsNum = math.max( math.floor( fragmentWidth / fragment.width ), 0 )
                for i = 1, integerPartsNum do
                    fragment:draw( tex, _x, y, fragment.width, height )
                    _x = _x + fragment.width
                end
                
                local fractionPartWidth = math.max( fragmentWidth - integerPartsNum*fragment.width, 0 )
                fragment:drawProgress( tex, _x, y, fragment.width, height, fractionPartWidth / fragment.width, 1 )
            else
                fragment:draw( tex, _x, y, fragmentWidth, height )
            end
        end
    end
    fragment = elements._e
    if fragment then
        if vertical then
            fragment:draw( tex, x, y + height - cornerRight.height, width, cornerRight.height )
        else
            fragment:draw( tex, x + width - cornerRight.width, y, cornerRight.width, height )
        end
    end
end

--[[
    Loading
]]
local function xrLoadTextureEntry( descriptor, xmlnode )
    local id = xmlNodeGetAttribute( xmlnode, "id" )
    local x = tonumber( xmlNodeGetAttribute( xmlnode, "x" ) )
    local y = tonumber( xmlNodeGetAttribute( xmlnode, "y" ) )
    local width = tonumber( xmlNodeGetAttribute( xmlnode, "width" ) )
    local height = tonumber( xmlNodeGetAttribute( xmlnode, "height" ) )

    local section = {
        id = id,
        x = x, y = y,
        width = width, height = height
    }

    xrTextureSections[ id ] = setmetatable( section, TextureSectionMT )
    table.insert( descriptor.sections, section )
end

local function xrLoadHullEntry( descriptor, xmlnode )
    local id = xmlNodeGetAttribute( xmlnode, "id" )
    local typeName = xmlNodeGetAttribute( xmlnode, "type" )
    local modeName = xmlNodeGetAttribute( xmlnode, "mode" )

    local hull = HullPatternFactory:create( typeName )
    if hull then
        hull.mode = xrHullModeNames[ modeName ] or HULL_MODE_STRETCH
        hull.id = id
        hull:load( xmlnode )

        xrTextureSections[ id ] = hull
        table.insert( descriptor.sections, hull )
    end
end

local function xrLoadTextureDescriptor( xmlnode )
	local name = xmlNodeGetAttribute( xmlnode, "name" )
	
	local descriptor = {
		texName = name,
		sections = {}
	}

    for _, child in ipairs( xmlNodeGetChildren( xmlnode ) ) do
        if xmlNodeGetName( child ) == "texture" then
            xrLoadTextureEntry( descriptor, child )
        elseif xmlNodeGetName( child ) == "hull" then
            xrLoadHullEntry( descriptor, child )
        end
	end

	return descriptor
end

function xrLoadUIFileDescriptor( name )
    local filename = ":xrcore/config/ui/textures_descr/" .. name .. ".xml"
    
    local xml = xmlLoadFile( filename, true )
    if not xml then
        return false
    end

    for _, child in ipairs( xmlNodeGetChildren( xml ) ) do
        if xmlNodeGetName( child ) == "file" then
			local descriptor = xrLoadTextureDescriptor( child )

			xrTextureDescriptors[ name ] = descriptor

			break
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