MAP_WIDTH = 706.063
MAP_HEIGHT = 1462.32
MAP_BIAS_X = -41.3152
MAP_BIAS_Y = -86.5385

MAP_LEFT = MAP_WIDTH * -0.5
MAP_BOTTOM = MAP_HEIGHT * 0.5

MAP_TEX_POINT = "ui_minimap_point"
MAP_TEX_LEADER = "ui_minimap_squad_leader"
MAP_TEX_DESTROY = "ui_mapQuest_stalker_destroy"

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

xrRadar = {

}

function xrRadar:setup( width, height )
    if self.rt then
        return false
    end

    self.rt = dxCreateRenderTarget( width, height, true )
    self.texture = dxCreateTexture( "textures/ui/map_escape.dds" )
    self.shader = dxCreateShader( "shaders/circle.fx" )
    dxSetShaderValue( self.shader, "Tex0", self.rt )

    local texWidth, texHeight = dxGetMaterialSize( self.texture )
    local scale = 1

    self.rtWidth = width
    self.rtHeight = height
    self.imgWidth = texWidth * scale
    self.imgHeight = texHeight * scale

    self.zones = {}
    self.players = {}
    self.peds = {}
    self.flashingAlpha = 0
    self.flashingState = false
    
    return true
end

function xrRadar:destroy()
    if not self.rt then
        return
    end

    destroyElement( self.rt )
    self.rt = nil

    destroyElement( self.texture )
    self.texture = nil

    destroyElement( self.shader )
    self.shader = nil
end

function xrRadar:drawPedAt( wx, wy, width, height, sectionName, color )
    local rx, ry = ( wx - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, ( wy - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT 
    local px = self.imgWidth * rx
    local py = self.imgHeight * -ry

    local halfWidth = width / 2
    local halfHeight = height / 2

    local texSection = xrTextureSections[ sectionName ]
    if texSection then
        texSection:draw( xrExtraTexDict, self.leftTopX + px - halfWidth, self.leftTopY + py - halfHeight, width, height, color )
    end
end

function xrRadar:drawZoneAt( zone, width, height )
    local sectorHash = EHashes.ZoneSector
	local greenHash = EHashes.ZoneGreen
    local class = zone:getData( "type", false )
    local zoneX, zoneY = getElementPosition( zone )
    local zoneRadius = zone:getData( "radius", false )
    
    local rx, ry = ( zoneX - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, ( zoneY - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT 
    local rad = zoneRadius / MAP_WIDTH
    
    local px = width * rx
    local py = height * -ry    

    if class == sectorHash then
        local prad = width * rad * 1.5

        local ownerTeam = zone:getData( "zowner", false )
        local teamSection = xrSettingsGetSection( ownerTeam )
        if self.flashingState and zone:getData( "zstate", false ) ~= ZSS_IDLE then
            local takerTeam = zone:getData( "ztaker", false )
            teamSection = xrSettingsGetSection( takerTeam )
        end

        local sectionName = "stalker_logo"
        if teamSection then
            sectionName = teamSection.logo
        end

        local color = tocolor( 255, 255, 255, 140 )
        if zone:getData( "zstate", false ) ~= ZSS_IDLE then
            color = tocolor( 255, 255, 255, self.flashingAlpha * 140 )
        end

        local texSection = xrTextureSections[ sectionName ]
        if texSection then
            local texAspect = texSection.width / texSection.height
            texSection:draw( xrExtraTexDict, self.leftTopX + px - prad*texAspect, self.leftTopY + py - prad, prad*texAspect*2, prad*2, color )
        end
    elseif class == greenHash then
        local prad = width * rad

        local color = tocolor( 11, 102, 35, 180 ) -- Forest color
        dxDrawCircle( self.leftTopX + px, self.leftTopY + py, prad, 0, 360, color )
    end
end

function xrRadar:draw()
    if not self.rt then
        return
    end

    --[[
        Обновляем стробоскоп
    ]]    
    local secs = getTickCount() / 1000
	self.flashingAlpha = ( math.sin( secs * math.pi - math.pi/2 ) + 1 ) / 2
	self.flashingState = secs % 4 <= 2

    --[[
        Рендерим радар
    ]]
    dxSetRenderTarget( self.rt, true )
		local x, y = getCameraMatrix()
		local rx, ry = ( x - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, ( y - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT
	
		local mx = self.imgWidth * -rx + self.rtWidth/2
        local my = self.imgHeight * ry + self.rtHeight/2
        
        self.leftTopX = mx
        self.leftTopY = my

		dxDrawImage( mx, my, self.imgWidth, self.imgHeight, self.texture )
       
        for _, element in ipairs( self.zones ) do
            if isElement( element ) then
                self:drawZoneAt( element, self.imgWidth, self.imgHeight )
            end 
        end

        for _, element in ipairs( self.players ) do
            if isElement( element ) then
                local x, y = getElementPosition( element )                
                local color = TEX_COLOR_YELLOW
				if element ~= localPlayer then
					color = TEX_COLOR_GRAY
                end

                local width = 8
                local height = 8
                local tex = MAP_TEX_POINT

                local wantedReward = xrEvaluatePlayerWantedLevel( element )
                if wantedReward > 0 then
                    color = TEX_COLOR_WHITE
                    width = 32
                    height = 32
                    tex = MAP_TEX_DESTROY
                end
                
                self:drawPedAt( x, y, width, height, tex, color )               
            end
        end
    
        for _, element in ipairs( self.peds ) do
            if isElement( element ) then
                local x, y = getElementPosition( element )

                -- Клон мертвого игрока
                if getElementData( element, "fake", false ) then                
                    self:drawPedAt( x, y, 8, 8, MAP_TEX_POINT, tocolor( 160, 160, 160, 210 ) )
                elseif getElementData( element, "leader", false ) then
                    self:drawPedAt( x, y, 12, 12, MAP_TEX_LEADER, tocolor( 255, 255, 0, 230 ) )
                end
            end
        end	
	dxSetRenderTarget()
end

function xrRadar:update()
    self.zones = {
        -- Очищаем очередь
    }
    self.players = {
		-- Очищаем очередь
	}
	self.peds = {
		-- Очищаем очередь
    }

    local ourTeam = getPlayerTeam( localPlayer )
    local ourTeamHash = ourTeam and getElementData( ourTeam, "cl", false ) or 0
    local ourTeamName = ourTeam and getTeamName( ourTeam ) or EMPTY_STR
    local cx, cy = getCameraMatrix()

    for i, zone in ipairs( getElementsByType( "zone" ) ) do
        local class = zone:getData( "type", false )
        local ownerTeamHash = zone:getData( "zowner", false )
        if class == EHashes.ZoneSector or ( class == EHashes.ZoneGreen and ownerTeamHash == ourTeamHash ) then
            local x, y = getElementPosition( zone )
            local radius = zone:getData( "radius", false )
            local distSqr = ( cx - x )^2 + ( cy - y )^2
            if distSqr - radius*radius <= RADAR_ZONE_THRESHOLD_SQR then
                table.insert( self.zones, zone )
            end
        end
    end
    
    for _, player in ipairs( getElementsByType( "player", root, true ) ) do
        local x, y = getElementPosition( player )
        local distSqr = ( cx - x )^2 + ( cy - y )^2

        local wantedReward = xrEvaluatePlayerWantedLevel( player )

        if distSqr <= RADAR_PLAYER_THRESHOLD_SQR and ( getPlayerTeam( player ) == ourTeam  or wantedReward > 0 ) then				
            table.insert( self.players, player )
        end
    end

    for _, ped in ipairs( getElementsByType( "ped", root, true ) ) do
        local x, y = getElementPosition( ped )
        local distSqr = ( cx - x )^2 + ( cy - y )^2

        if distSqr <= RADAR_PLAYER_THRESHOLD_SQR then			
            -- Клон мертвого игрока
            if getElementData( ped, "fake", false ) then                
                table.insert( self.peds, ped )
            elseif getElementData( ped, "leader", false ) then
                local pedTeamName = getElementData( ped, "team", false )
                if not pedTeamName or pedTeamName == ourTeamName then
                    table.insert( self.peds, ped )
                end
            end
        end
    end
end