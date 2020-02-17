MAP_WIDTH = 706.063
MAP_HEIGHT = 1462.32
MAP_BIAS_X = -41.3152
MAP_BIAS_Y = -86.5385

MAP_LEFT = MAP_WIDTH * -0.5
MAP_BOTTOM = MAP_HEIGHT * 0.5

MAP_TEX_POINT = "ui_minimap_point"
MAP_TEX_LEADER = "ui_minimap_squad_leader"
MAP_TEX_DESTROY = "ui_mapQuest_stalker_destroy"

PLAYER_ICON_SIZE = 20
PLAYER_POINT_SIZE = 8
LEADER_POINT_SIZE = 16
DESTROY_ICON_SIZE = 25

TEX_COLOR_WHITE = tocolor( 255, 255, 255, 255 )
TEX_COLOR_YELLOW = tocolor( 255, 255, 0, 230 )
TEX_COLOR_GRAY =  tocolor( 230, 230, 230, 230 )

local RADAR_PLAYER_THRESHOLD_SQR = 90*90
local RADAR_ZONE_THRESHOLD_SQR = 150*150

local ZONE_FLASHING_PERIOD = 800

local ZSS_IDLE = 1
local ZSS_TAKING = 2 -- Идет захват
local ZSS_AWAIT = 3 -- В зоне несколько группировок
local ZSS_ZERO = 4 -- В зоне никого нет

local function getElementMapPosition( element )
	local x, y = getElementPosition( element )
	local rx, ry = ( x - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, -( y - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT

	return rx, ry
end

xrRadar = {

}

function xrRadar:setup( canvas )
    do
        xrRadar.time = canvas:getFrame( "TimeLbl", true )
        xrRadar.compass = canvas:getFrame( "Compass", true )
        xrRadar.mapRt = canvas:getFrame( "RadarRT", true )

        local cropShader = dxCreateShader( "shaders/circle.fx" )
        if cropShader then
            xrRadar.mapRt:setShader( cropShader )
        end

        do
            xrRadar.mapCanvas = xrCreateUICanvas( 0, 0, ORIGIN_TEX_WIDTH, ORIGIN_TEX_HEIGHT )				
            
            local mapXml = xmlLoadFile( "config/Map.xml", true )
            if mapXml then
                xrRadar.mapCanvas:load( mapXml )					

                xrRadar.mapRt:setTargetCanvas( xrRadar.mapCanvas )

                xrRadar.mapFrame = xrRadar.mapCanvas:getFrame( "Map", true )

                xrRadar.mapCanvas:update()		
    
                xmlUnloadFile( mapXml )
            end						
        end
    end

    self.zones = {}
    self.players = {}
    self.peds = {}
    self.flashingAlpha = 0
    self.flashingState = false
    
    return true
end

function xrRadar:destroy()

end

function xrRadar:draw()
    do
		local tw = ( ORIGIN_TEX_WIDTH * 2 )
		local th = ( tw / ORIGIN_TEX_ASPECT )

		local scale = 0.35
		tw = tw * scale
		th = th * scale

		local rx, ry = getElementMapPosition( localPlayer )
		local tx, ty = xrRadar.mapRt.tw / 2 - rx * tw, xrRadar.mapRt.th / 2 - ry * th
		xrRadar.mapCanvas:setPosition( tx, ty )
		xrRadar.mapCanvas:setSize( tw, th )
        xrRadar.mapCanvas:update()

		local _, _, rot = getElementRotation( getCamera() )
		xrRadar.compass:setRotation( rot )
	end

    --[[
        Обновляем стробоскоп
	]]
	local secs = getTickCount() / 1000
	local flashingAlpha = ( math.sin( secs * math.pi - math.pi/2 ) + 1 ) / 2
	local flashingState = secs % 4 <= 2

	--[[
		Map
	]]
	for player, frame in pairs( xrRadar.players ) do
		if isElement( player ) then
			local rx, ry = getElementMapPosition( player )

			frame:applyTransform( 
				rx * xrRadar.mapFrame.originWidth - frame.originWidth/2, ry * xrRadar.mapFrame.originHeight - frame.originWidth/2, 
				frame.originWidth, frame.originWidth, 
				false 
			)
			frame:update()
		end
	end

	-- Zones
    for zone, frame in pairs( xrRadar.zones ) do
        local logoFrame = frame:getFrame( "ZoneLogo" )

		if isElement( zone ) then
			local ownerTeam = zone:getData( "zowner", false )
			local teamSection = xrSettingsGetSection( ownerTeam )
			--[[if flashingState and zone:getData( "zstate", false ) ~= ZSS_IDLE then
				local takerTeam = zone:getData( "ztaker", false )
				teamSection = xrSettingsGetSection( takerTeam )
			end]]
			
			if teamSection then
				logoFrame:setVisible( true )
				logoFrame:setTextureSection( teamSection.logo )
			else
				logoFrame:setVisible( false )
			end

			if zone:getData( "zstate", false ) ~= ZSS_IDLE then
				frame:setColor( 255, 255, 255, flashingAlpha * 200 )
			else
				frame:setColor( 255, 255, 255, 200 )
			end
		end
	end
end

function xrRadar:insertPed( ped )
    local frame = xrRadar.mapFrame:createChild( "image", "Player" )

    local rx, ry = getElementMapPosition( ped )

    if getElementData( ped, "fake", false ) then
        frame:applyTransform( rx * xrRadar.mapFrame.originWidth - PLAYER_POINT_SIZE/2, ry * xrRadar.mapFrame.originHeight - PLAYER_POINT_SIZE/2, PLAYER_POINT_SIZE, PLAYER_POINT_SIZE, false )
        frame:setTexture( "ui_common" )
        frame:setTextureSection( MAP_TEX_POINT )
        frame:setColor( 130, 130, 130 )
    elseif getElementData( ped, "leader", false ) then
        frame:applyTransform( rx * xrRadar.mapFrame.originWidth - LEADER_POINT_SIZE/2, ry * xrRadar.mapFrame.originHeight - LEADER_POINT_SIZE/2, LEADER_POINT_SIZE, LEADER_POINT_SIZE, false )
        frame:setTexture( "ui_common" )
        frame:setTextureSection( MAP_TEX_LEADER )
        frame:setColor( 255, 255, 0 )
    end
    
    self.peds[ ped ] = frame
end

function xrRadar:update()
    local hours, mins = getTime()
	if hours < 10 then
		hours = "0" .. hours
	end
	if mins < 10 then
		mins = "0" .. mins
	end
	xrRadar.time:setText( hours .. " : " .. mins )

    self.zones = {
        -- Очищаем очередь
    }
    self.players = {
		-- Очищаем очередь
	}
	self.peds = {
		-- Очищаем очередь
    }

    -- Удаляем с карты все метки
	xrRadar.mapFrame:destroyChildren()

    local ourTeam = getPlayerTeam( localPlayer )
    local ourTeamHash = ourTeam and getElementData( ourTeam, "cl", false ) or 0
    local ourTeamName = ourTeam and getTeamName( ourTeam ) or EMPTY_STR
    local cx, cy = getCameraMatrix()

    for i, zone in ipairs( getElementsByType( "zone" ) ) do
        local class = zone:getData( "type", false )
        local ownerTeamHash = zone:getData( "zowner", false )
        if class == EHashes.ZoneSector --[[or ( class == EHashes.ZoneGreen and ownerTeamHash == ourTeamHash )]] then
            local x, y = getElementPosition( zone )
            local radius = zone:getData( "radius", false )
            local distSqr = ( cx - x )^2 + ( cy - y )^2
            if distSqr - radius*radius <= RADAR_ZONE_THRESHOLD_SQR then
                local frame = xrRadar.mapFrame:createChild( "image", "Zone" )
                frame:setColor( 255, 255, 255, 200 )
                frame:setTexture( "ui_common" )
                frame:setTextureSection( "ui_icons_newPDA_Crclbig_h" )	
                
                local rx, ry = getElementMapPosition( zone )
                frame:applyTransform( rx * xrRadar.mapFrame.originWidth - 50, ry * xrRadar.mapFrame.originHeight - 50, 100, 100, true )

                do
                    local logoFrame = frame:createChild( "image", "ZoneLogo" )
                    logoFrame:setColor( 255, 255, 255, 130 )	
                    logoFrame:applyTransform( 50-30, 50-30, 60, 60, true )
                    logoFrame:setTexture( "ui_logos" )
                    
                    local ownerTeam = zone:getData( "zowner", false )
                    local teamSection = xrSettingsGetSection( ownerTeam )
                    if teamSection then					
                        logoFrame:setTextureSection( teamSection.logo )
                    else
                        logoFrame:setVisible( false )
                    end
                end

                self.zones[ zone ] = frame
            end
        end
    end
    
    for _, player in ipairs( getElementsByType( "player", root, true ) ) do
        local x, y = getElementPosition( player )
        local distSqr = ( cx - x )^2 + ( cy - y )^2
        local isOurTeam = getPlayerTeam( player ) == ourTeam 
        local isWanted = xrIsPlayerWanted( player, ourTeam )

        if distSqr <= RADAR_PLAYER_THRESHOLD_SQR and ( isOurTeam or isWanted ) then				
            local frame = xrRadar.mapFrame:createChild( "image", "Player" )

            local rx, ry = getElementMapPosition( player )

            frame:setTexture( "ui_common" )
            if isWanted and player ~= localPlayer then
                frame:applyTransform( rx * xrRadar.mapFrame.originWidth - DESTROY_ICON_SIZE/2, ry * xrRadar.mapFrame.originHeight - DESTROY_ICON_SIZE/2, DESTROY_ICON_SIZE, DESTROY_ICON_SIZE, false )
                frame:setTexture( "ui_common" )
                frame:setTextureSection( MAP_TEX_DESTROY )
            else
                frame:applyTransform( rx * xrRadar.mapFrame.originWidth - PLAYER_POINT_SIZE/2, ry * xrRadar.mapFrame.originHeight - PLAYER_POINT_SIZE/2, PLAYER_POINT_SIZE, PLAYER_POINT_SIZE, false )
                frame:setTexture( "ui_common" )
                frame:setTextureSection( MAP_TEX_POINT )
            end
            
            self.players[ player ] = frame
        end
    end

    for i, blip in ipairs( getElementsByType( "xrblip" ) ) do
		local frame = xrRadar.mapFrame:createChild( "image", "Blip" )

		local rx, ry = getElementMapPosition( blip )
		local texName = getElementData( blip, "tex" )
		local sectionName = getElementData( blip, "sect" )
		local size = getElementData( blip, "size" )

		frame:applyTransform( rx * xrRadar.mapFrame.originWidth - size/2, ry * xrRadar.mapFrame.originHeight - size/2, size, size, true )
		frame:setTexture( texName )
        frame:setTextureSection( sectionName )
	end

    for _, ped in ipairs( getElementsByType( "ped", root, true ) ) do
        local x, y = getElementPosition( ped )
        local distSqr = ( cx - x )^2 + ( cy - y )^2

        if distSqr <= RADAR_PLAYER_THRESHOLD_SQR then			
            -- Клон мертвого игрока
            if getElementData( ped, "fake", false ) then                
                self:insertPed( ped )
            elseif getElementData( ped, "leader", false ) then
                local pedTeamName = getElementData( ped, "team", false )
                if not pedTeamName or pedTeamName == ourTeamName then
                    self:insertPed( ped )
                end
            end
        end
    end
end

