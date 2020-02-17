local sw, sh = guiGetScreenSize ( )

MAP_WIDTH = 706.063
MAP_HEIGHT = 1462.32
MAP_BIAS_X = -41.3152
MAP_BIAS_Y = -86.5385

MAP_LEFT = MAP_WIDTH * -0.5
MAP_BOTTOM = MAP_HEIGHT * 0.5

MAP_MIN_SCALE = 0.5
MAP_MAX_SCALE = 4

ORIGIN_TEX_WIDTH = 1024
ORIGIN_TEX_HEIGHT = 2048
ORIGIN_TEX_ASPECT = ORIGIN_TEX_WIDTH / ORIGIN_TEX_HEIGHT

PLAYER_ICON_SIZE = 30
PLAYER_POINT_SIZE = 12
DESTROY_ICON_SIZE = 35

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

xrExtraTexDict = {

}

xrMap = {
	isEnabled = false
}

function xrMap.init( canvas )
	local xml = xmlLoadFile( "PDAmap.xml", true )
	if xml then
		canvas:insert( xml, canvas.frame )

		xmlUnloadFile( xml )
	end

	local mapRoot = canvas:getFrame( "CanvasMap", true )
	xrMap.mapRoot = mapRoot
	xrMap.canvas = canvas

	mapRoot:getFrame( "SetsBtn", true ):addHandler( xrMap.onTabBtnPressed, xrDonate )
	--mapRoot:getFrame( "OptionsBtn", true ):addHandler( xrMap.onTabBtnPressed )

	mapRoot:getFrame( "CenterBtn", true ):addHandler( xrMap.onCenterBtnPressed )
	mapRoot:getFrame( "RadioImportant", true ):addHandler( xrMap.onMapRadioPressed, 4 )
	mapRoot:getFrame( "RadioQuests", true ):addHandler( xrMap.onMapRadioPressed, 3 )
	mapRoot:getFrame( "RadioLocations", true ):addHandler( xrMap.onMapRadioPressed, 2 )
	mapRoot:getFrame( "RadioContainers", true ):addHandler( xrMap.onMapRadioPressed, 1 )
	mapRoot:getFrame( "CurrentQuestsBtn", true ):addHandler( xrMap.onQuestsListToggle )

	xrMap.arrowDownBtn = mapRoot:getFrame( "ArrowDownBtn", true )
	xrMap.arrowUpBtn = mapRoot:getFrame( "ArrowUpBtn", true )
	xrMap.arrowRightBtn = mapRoot:getFrame( "ArrowRightBtn", true )
	xrMap.arrowLeftBtn = mapRoot:getFrame( "ArrowLeftBtn", true )
	xrMap.zoomInBtn = mapRoot:getFrame( "ZoomInBtn", true )
	xrMap.zoomOutBtn = mapRoot:getFrame( "ZoomOutBtn", true )
	xrMap.mapRt = mapRoot:getFrame( "MapRT", true )
	xrMap.mapMask = mapRoot:getFrame( "MapMask", true )
	xrMap.questsList = mapRoot:getFrame( "QuestPaneList", true )
	xrMap.questsWnd = mapRoot:getFrame( "MapQuestsList", true )
	xrMap.timeLbl = mapRoot:getFrame( "TimeLbl", true )

	do
		xrMap.mapCanvas = xrCreateUICanvas( 0, 0, ORIGIN_TEX_WIDTH, ORIGIN_TEX_HEIGHT )
		
		local xml = xmlLoadFile( "Map.xml", true )
		if xml then
			xrMap.mapCanvas:load( xml )

			xmlUnloadFile( xml )
		end

		xrMap.mapCanvas:update()

		xrMap.mapRt:setTargetCanvas( xrMap.mapCanvas )
	end

	do		
		local xml = xmlLoadFile( "QuestRow.xml", true )
		if xml then
			local frame = canvas:insert( xml, xrMap.questsList )
			frame:getFrame( "QuestEntyText" ):setText( "Тестировать игровой режим" )

			xmlUnloadFile( xml )
		end
	end

	mapRoot:setVisible( false )
end

function xrMap:open()	
	if xrMap.isEnabled then
		return
	end	

	-- Заполняем карту
	self:fillMap()	

	xrMap.mapRoot:setVisible( true )

	xrMap.isEnabled = true
end

function xrMap:close()
	if xrMap.isEnabled then
		-- Удаляем с карты все метки
		xrMap.mapFrame:destroyChildren()

		self.players = {
			-- Очищаем список игроков
		}
		self.zones = {
			-- Очищаем список зон
		}

		xrMap.mapRoot:setVisible( false )

		xrMap.isEnabled = false
	end
end

function xrMap.onTabBtnPressed( class )
	xrMain.onTabClicked( class )
end

function xrMap:fillMap()
	--[[
		Заполняем карту
	]]
	xrMap.mapFrame = xrMap.mapCanvas:getFrame( "Map", true )

	self.players = {
		-- [player] = frame
	}
	self.zones = {
		-- [zone] = zone
	}
	
	local questsRadioFrame = xrMap.mapRoot:getFrame( "RadioQuests", true )
	for i, zone in ipairs( getElementsByType( "zone" ) ) do
		local class = zone:getData( "type", false )		
		if class == EHashes.ZoneSector then
			local frame = xrMap.mapFrame:createChild( "image", "Zone" )
			frame:setVisible( questsRadioFrame.stateIdx == UIBTN_CLICKED )
			frame:setColor( 255, 255, 255, 120 )	
			frame:setTexture( "ui_common" )
			frame:setTextureSection( "ui_icons_newPDA_Crclbig_h" )		
			
			local rx, ry = getElementMapPosition( zone )
			frame:applyTransform( rx * xrMap.mapFrame.originWidth - 50, ry * xrMap.mapFrame.originHeight - 50, 100, 100, true )

			local ownerTeam = zone:getData( "zowner", false )
			local teamSection = xrSettingsGetSection( ownerTeam )

			do
				local logoFrame = frame:createChild( "image", "ZoneLogo" )
				logoFrame:setColor( 255, 255, 255, 100 )	
				logoFrame:applyTransform( 50-30, 50-30, 60, 60, true )
				logoFrame:setTexture( "ui_logos" )
				
				if teamSection then					
					logoFrame:setTextureSection( teamSection.logo )
				else
					logoFrame:setVisible( false )
				end
			end

			do
				local textFrame = frame:createChild( "text", "ZoneText" )
				textFrame:setColor( 255, 255, 255, 100 )	
				textFrame:setAlign( "center", "center" )
				textFrame:applyTransform( 50-30, 50-30, 60, 60, true )
				textFrame:setFont( "default" )
				textFrame:setScale( 1.2 )

				local timestamp = getRealTime().timestamp
				local zoneTimestamp = getElementData( zone, "occupy_ts", false )
				if teamSection and zoneTimestamp then
					local elapsed = timestamp - zoneTimestamp
					local left = math.max( ZONE_OCCUPY_PERIOD_SECS - elapsed, 0 )
					local hoursLeft = math.ceil( left / 60 )

					textFrame:setText( hoursLeft .. " минут" )
				else
					textFrame:setVisible( false )
				end
			end

			self.zones[ zone ] = frame
		end
	end

	local ourTeam = getPlayerTeam( localPlayer )
    local ourTeamName = ourTeam and getTeamName( ourTeam ) or EMPTY_STR

	for i, player in ipairs( getElementsByType( "player" ) ) do
		-- Локальный игрок имеет собственную иконку
		local isOurTeam = getPlayerTeam( player ) == ourTeam
		local isWanted = xrIsPlayerWanted( player, ourTeam )

		if player ~= localPlayer and ( isOurTeam or isWanted ) then
			local frame = xrMap.mapFrame:createChild( "image", "Player" )

			local rx, ry = getElementMapPosition( player )

			frame:setTexture( "ui_common" )
			if isWanted then
				frame:applyTransform( rx * xrMap.mapFrame.originWidth - DESTROY_ICON_SIZE/2, ry * xrMap.mapFrame.originHeight - DESTROY_ICON_SIZE/2, DESTROY_ICON_SIZE, DESTROY_ICON_SIZE, false )
				frame:setTexture( "ui_common" )
				frame:setTextureSection( "ui_mapQuest_stalker_destroy" )
			else
				frame:applyTransform( rx * xrMap.mapFrame.originWidth - PLAYER_POINT_SIZE/2, ry * xrMap.mapFrame.originHeight - PLAYER_POINT_SIZE/2, PLAYER_POINT_SIZE, PLAYER_POINT_SIZE, false )
				frame:setTexture( "ui_common" )
				frame:setTextureSection( "ui_minimap_point" )
			end
			
			self.players[ player ] = frame
		end
	end

	do
		local frame = xrMap.mapFrame:createChild( "image", "LocalPlayer" )

		local rx, ry = getElementMapPosition( localPlayer )
		frame:applyTransform( rx * xrMap.mapFrame.originWidth - PLAYER_ICON_SIZE/2, ry * xrMap.mapFrame.originHeight - PLAYER_ICON_SIZE/2, PLAYER_ICON_SIZE, PLAYER_ICON_SIZE, true )

		frame:setTexture( "ui_common" )
		frame:setTextureSection( "ui_icons_newPDA_man" )			

		xrMap.playerFrame = frame
	end

	do
		local frame = xrMap.mapFrame:createChild( "image", "LocalPlayerArrow" )

		local rx, ry = getElementMapPosition( localPlayer )

		local arrowScale = 1.884615
		local arrowSize = PLAYER_ICON_SIZE * arrowScale
		frame:applyTransform( rx * xrMap.mapFrame.originWidth - arrowSize/2, ry * xrMap.mapFrame.originHeight - arrowSize/2, arrowSize, arrowSize, true )

		frame:setTexture( "ui_common" )
		frame:setTextureSection( "ui_icons_newPDA_manArrow" )			

		xrMap.playerArrowFrame = frame
	end

	for i, ped in ipairs( getElementsByType( "ped" ) ) do
		if getElementData( ped, "leader", false ) then
			local pedTeamName = getElementData( ped, "team", false )
			if not pedTeamName or pedTeamName == ourTeamName then
				local frame = xrMap.mapFrame:createChild( "image", "Ped" )
	
				local rx, ry = getElementMapPosition( ped )
				frame:applyTransform( rx * xrMap.mapFrame.originWidth - PLAYER_POINT_SIZE/2, ry * xrMap.mapFrame.originHeight - PLAYER_POINT_SIZE/2, PLAYER_POINT_SIZE, PLAYER_POINT_SIZE, false )

				frame:setTexture( "ui_common" )
				frame:setTextureSection( "ui_minimap_squad_leader" )			
			end
		end
	end

	for i, blip in ipairs( getElementsByType( "xrblip" ) ) do
		local frame = xrMap.mapFrame:createChild( "image", "Blip" )

		local rx, ry = getElementMapPosition( blip )
		local texName = getElementData( blip, "tex" )
		local sectionName = getElementData( blip, "sect" )
		local size = getElementData( blip, "size" )

		frame:applyTransform( rx * xrMap.mapFrame.originWidth - size/2, ry * xrMap.mapFrame.originHeight - size/2, size, size, true )
		frame:setTexture( texName )
		frame:setTextureSection( sectionName )
	end

	xrMap.mapCanvas:update()
end

function xrMap.onCenterBtnPressed()
	local tw = ORIGIN_TEX_WIDTH * 2
	local th = tw / ORIGIN_TEX_ASPECT
	local rx, ry = getElementMapPosition( localPlayer )
	local tx, ty = xrMap.mapRt.tw / 2 - rx * tw, xrMap.mapRt.th / 2 - ry * th

	xrMap.centering = {
		sx = xrMap.mapCanvas.screenX,
		sy = xrMap.mapCanvas.screenY,
		tx = tx,
		ty = ty,
		sw = xrMap.mapCanvas.screenWidth,
		tw = tw,
		startTime = getTickCount()
	}
end

function xrMap.onMapRadioPressed( radioIndex )
	if radioIndex == 3 then
		for _, frame in pairs( xrMap.zones ) do
			frame:setVisible( source.stateIdx == UIBTN_CLICKED )
		end
	end
end

function xrMap.onQuestsListToggle()
	xrMap.questsWnd:setVisible( not xrMap.questsWnd.visible )		
end

function xrMap:scaleAt( cx, cy, scale )
	local rx = ( cx - xrMap.mapCanvas.screenX ) / xrMap.mapCanvas.screenWidth
	local ry = ( cy - xrMap.mapCanvas.screenY ) / xrMap.mapCanvas.screenHeight

	local width = xrMap.mapCanvas.screenWidth + xrMap.mapCanvas.screenWidth * scale
	local height = xrMap.mapCanvas.screenHeight + xrMap.mapCanvas.screenHeight * scale
	width = math.clamp( ORIGIN_TEX_WIDTH*MAP_MIN_SCALE, ORIGIN_TEX_WIDTH*MAP_MAX_SCALE, width )
	height = math.clamp( ORIGIN_TEX_HEIGHT*MAP_MIN_SCALE, ORIGIN_TEX_HEIGHT*MAP_MAX_SCALE, height )

	local x = cx - width*rx
	local y = cy - height*ry

	xrMap.mapCanvas:setSize( width, height )
	xrMap.mapCanvas:setPosition( x, y )
	xrMap.mapCanvas:update()
end

function xrMap.onRender()
	local dx, dy = 0, 0

	if xrMap.arrowUpBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 0, 1
	elseif xrMap.arrowDownBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 0, -1
	elseif xrMap.arrowRightBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = -1, 0
	elseif xrMap.arrowLeftBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 1, 0
	end

	if dx ~= 0 or dy ~= 0 then
		local x = xrMap.mapCanvas.screenX + dx*5
		local y = xrMap.mapCanvas.screenY + dy*5	

		xrMap.mapCanvas:setPosition( x, y )
		xrMap.mapCanvas:update()
	end

	local scale = 0

	if xrMap.zoomInBtn.stateIdx == UIBTN_CLICKED then
		scale = 1
	elseif xrMap.zoomOutBtn.stateIdx == UIBTN_CLICKED then
		scale = -1
	end

	if scale ~= 0 then
		local cx, cy = xrMap.mapRt.tw / 2, xrMap.mapRt.th / 2
		xrMap:scaleAt( cx, cy, scale*0.005 )
	end

	--[[
		Time
	]]
	local hours, mins = getTime()
	if hours < 10 then
		hours = "0" .. hours
	end
	if mins < 10 then
		mins = "0" .. mins
	end
	xrMap.timeLbl:setText( hours .. " : " .. mins )

	--[[
        Обновляем стробоскоп
	]]
	local secs = getTickCount() / 1000
	local flashingAlpha = ( math.sin( secs * math.pi - math.pi/2 ) + 1 ) / 2
	local flashingState = secs % 4 <= 2

	--[[
		Map
	]]

	-- Other players
	for player, frame in pairs( xrMap.players ) do
		if isElement( player ) then
			local rx, ry = getElementMapPosition( player )

			frame:applyTransform( 
				rx * xrMap.mapFrame.originWidth - frame.originWidth/2, ry * xrMap.mapFrame.originHeight - frame.originWidth/2, 
				frame.originWidth, frame.originWidth, 
				false 
			)
			frame:update()
		end
	end

	-- Local player
	local playerFrame = xrMap.playerFrame
	if playerFrame then
		local rx, ry = getElementMapPosition( localPlayer )
		local _, _, rot = getElementRotation( localPlayer )
		
		playerFrame:applyTransform( rx * xrMap.mapFrame.originWidth - PLAYER_ICON_SIZE/2, ry * xrMap.mapFrame.originHeight - PLAYER_ICON_SIZE/2, PLAYER_ICON_SIZE, PLAYER_ICON_SIZE, true )
		playerFrame:update()

		local arrowScale = 1.884615
		local arrowSize = PLAYER_ICON_SIZE * arrowScale
		xrMap.playerArrowFrame:applyTransform( rx * xrMap.mapFrame.originWidth - arrowSize/2, ry * xrMap.mapFrame.originHeight - arrowSize/2, arrowSize, arrowSize, true )
		xrMap.playerArrowFrame:setRotation( 360 - rot )
		xrMap.playerArrowFrame:update()
	end

	-- Zones
	for zone, frame in pairs( xrMap.zones ) do
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
				frame:setColor( 255, 255, 255, flashingAlpha * 130 )
			else
				frame:setColor( 255, 255, 255, 120 )
			end
		end
	end

	--[[
		Centering
	]]
	local centering = xrMap.centering
	if centering then
		local now = getTickCount()
		local t = ( now - centering.startTime ) / 1000
		if t >= 1 then
			xrMap.centering = nil
		else
			t = getEasingValue( t, "OutQuad" )
			local width = math.interpolate( centering.sw, centering.tw, t )
			local height = width / ORIGIN_TEX_ASPECT
			local x = math.interpolate( centering.sx, centering.tx, t )
			local y = math.interpolate( centering.sy, centering.ty, t )

			xrMap.mapCanvas:setSize( width, height )
			xrMap.mapCanvas:setPosition( x, y )
			xrMap.mapCanvas:update()
		end
	end
end

function xrMap.onCursorMove( _, _, ax, ay )
	local rx = ax - xrMap.mapRt.tx
	local ry = ay - xrMap.mapRt.ty

	if xrMap.mapDragDrop then		
		xrMap.mapCanvas:setPosition( rx - xrMap.mapDragDrop.bx, ry - xrMap.mapDragDrop.by )
		xrMap.mapCanvas:update()
	end
end


function xrMap.onCursorClick( btn, state, ax, ay )
	if state == "down" then
		if xrMap.canvas.focused == xrMap.mapMask then
			local rx = ax - xrMap.mapRt.tx
			local ry = ay - xrMap.mapRt.ty
			
			local bx = rx - xrMap.mapCanvas.screenX
			local by = ry - xrMap.mapCanvas.screenY

			xrMap.mapDragDrop = {
				bx = bx,
				by = by
			}
		end
	else
		xrMap.mapDragDrop = nil
	end
end

function xrMap.onKey( btn, pressed )
	local cx, cy = getCursorPosition()

	if btn == "mouse_wheel_up" then
		if xrMap.canvas.focused == xrMap.mapMask then
			local rx = cx*sw - xrMap.mapRt.tx
			local ry = cy*sh - xrMap.mapRt.ty

			xrMap:scaleAt( rx, ry, 0.05 )
		end
	elseif btn == "mouse_wheel_down" then
		if xrMap.canvas.focused == xrMap.mapMask then
			local rx = cx*sw - xrMap.mapRt.tx
			local ry = cy*sh - xrMap.mapRt.ty

			xrMap:scaleAt( rx, ry, -0.05 )
		end
	end
end