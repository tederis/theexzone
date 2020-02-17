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

local function getElementMapPosition( element )
	local x, y = getElementPosition( element )
	local rx, ry = ( x - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, -( y - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT

	return rx, ry
end

xrExtraTexDict = {

}

xrMain = {
	isEnabled = false
}

local questBlips = {

}

function xrMain.init()
	local aspect = 1024 / 768
	local height = sh
	local width = height * aspect
	
	xrMain.canvas = xrCreateUICanvas( sw / 2 - width / 2, sh / 2 - height / 2, width, height )

	local xml = xmlLoadFile( "Name.xml", true )
	if xml then
		xrMain.canvas:load( xml )

		xmlUnloadFile( xml )
	end

	xrMain.canvas:getFrame( "CenterBtn", true ):addHandler( xrMain.onCenterBtnPressed )
	xrMain.canvas:getFrame( "RadioImportant", true ):addHandler( xrMain.onMapRadioPressed, 4 )
	xrMain.canvas:getFrame( "RadioQuests", true ):addHandler( xrMain.onMapRadioPressed, 3 )
	xrMain.canvas:getFrame( "RadioLocations", true ):addHandler( xrMain.onMapRadioPressed, 2 )
	xrMain.canvas:getFrame( "RadioContainers", true ):addHandler( xrMain.onMapRadioPressed, 1 )
	xrMain.canvas:getFrame( "CurrentQuestsBtn", true ):addHandler( xrMain.onQuestsListToggle )

	xrMain.arrowDownBtn = xrMain.canvas:getFrame( "ArrowDownBtn", true )
	xrMain.arrowUpBtn = xrMain.canvas:getFrame( "ArrowUpBtn", true )
	xrMain.arrowRightBtn = xrMain.canvas:getFrame( "ArrowRightBtn", true )
	xrMain.arrowLeftBtn = xrMain.canvas:getFrame( "ArrowLeftBtn", true )
	xrMain.zoomInBtn = xrMain.canvas:getFrame( "ZoomInBtn", true )
	xrMain.zoomOutBtn = xrMain.canvas:getFrame( "ZoomOutBtn", true )
	xrMain.mapRt = xrMain.canvas:getFrame( "MapRT", true )
	xrMain.mapMask = xrMain.canvas:getFrame( "MapMask", true )
	xrMain.questsList = xrMain.canvas:getFrame( "QuestPaneList", true )
	xrMain.questsWnd = xrMain.canvas:getFrame( "MapQuestsList", true )
	xrMain.timeLbl = xrMain.canvas:getFrame( "TimeLbl", true )

	do
		xrMain.mapCanvas = xrCreateUICanvas( 0, 0, ORIGIN_TEX_WIDTH, ORIGIN_TEX_HEIGHT )
		
		local xml = xmlLoadFile( "Map.xml", true )
		if xml then
			xrMain.mapCanvas:load( xml )

			xmlUnloadFile( xml )
		end

		xrMain.mapCanvas:update()

		local texture = exports.sp_assets:xrLoadAsset( "ui\\ui_actor_pda" )
		if texture then
			xrMain.mapCanvas:addTexture( texture, "ui\\ui_actor_pda" )
		end

		xrMain.mapRt:setTargetCanvas( xrMain.mapCanvas )
	end

	do		
		local xml = xmlLoadFile( "QuestRow.xml", true )
		if xml then
			local frame = xrMain.canvas:insert( xml, xrMain.questsList )
			frame:getFrame( "QuestEntyText" ):setText( "Забрать информацию у разведчика" )

			frame = xrMain.canvas:insert( xml, xrMain.questsList )
			frame:getFrame( "QuestEntyText" ):setText( "Убить стрелка" )
			
			frame = xrMain.canvas:insert( xml, xrMain.questsList )
			frame:getFrame( "QuestEntyText" ):setText( "Заехать в McDonald's" )

			xmlUnloadFile( xml )
		end
	end

	xrMain.canvas:update()

	local texture = exports.sp_assets:xrLoadAsset( "ui\\ui_actor_pda" )
	if texture then
		xrMain.canvas:addTexture( texture, "ui\\ui_actor_pda" )
	end

	--[[
		Заполняем карту
	]]
	xrMain.mapFrame = xrMain.mapCanvas:getFrame( "Map", true )

	do
		local frame = xrMain.mapFrame:createChild( "image", "Player" )

		local rx, ry = getElementMapPosition( localPlayer )
		frame:applyTransform( rx * xrMain.mapFrame.originWidth - PLAYER_ICON_SIZE/2, ry * xrMain.mapFrame.originHeight - PLAYER_ICON_SIZE/2, PLAYER_ICON_SIZE, PLAYER_ICON_SIZE, true )

		frame:setTexture( "ui_common" )
		frame:setTextureSection( "ui_icons_newPDA_man" )			

		xrMain.playerFrame = frame
	end

	do
		local frame = xrMain.mapFrame:createChild( "image", "PlayerArrow" )

		local rx, ry = getElementMapPosition( localPlayer )

		local arrowScale = 1.884615
		local arrowSize = PLAYER_ICON_SIZE * arrowScale
		frame:applyTransform( rx * xrMain.mapFrame.originWidth - arrowSize/2, ry * xrMain.mapFrame.originHeight - arrowSize/2, arrowSize, arrowSize, true )

		frame:setTexture( "ui_common" )
		frame:setTextureSection( "ui_icons_newPDA_manArrow" )			

		xrMain.playerArrowFrame = frame
	end

	local questsRadioFrame = xrMain.canvas:getFrame( "RadioQuests", true )
	for i, zone in ipairs( getElementsByType( "zone" ) ) do
		local class = zone:getData( "cl", false )		
		if class == EHashes.ZoneSector then
			local frame = xrMain.mapFrame:createChild( "image", "Blip " .. i )
			frame:setVisible( questsRadioFrame.stateIdx == UIBTN_CLICKED )

			local rx, ry = getElementMapPosition( zone )
			frame:applyTransform( rx * xrMain.mapFrame.originWidth - 50, ry * xrMain.mapFrame.originHeight - 50, 100, 100, true )

			frame:setTexture( "ui_common" )
			frame:setTextureSection( "ui_icons_newPDA_Crclbig_h" )

			table.insert( questBlips, frame )
		end
	end

	local ourTeam = getPlayerTeam( localPlayer )
    local ourTeamName = ourTeam and getTeamName( ourTeam ) or EMPTY_STR

	for i, ped in ipairs( getElementsByType( "ped" ) ) do
		if getElementData( ped, "leader", false ) then
			local pedTeamName = getElementData( ped, "team", false )
			if not pedTeamName or pedTeamName == ourTeamName then
				local frame = xrMain.mapFrame:createChild( "image", "Ped " .. i )
	
				local rx, ry = getElementMapPosition( ped )
				frame:applyTransform( rx * xrMain.mapFrame.originWidth - 5, ry * xrMain.mapFrame.originHeight - 5, 10, 10, true )

				frame:setTexture( "ui_actor_hint_wnd" )
				frame:setTextureSection( "ui_inGame2_PDA_icon_Stalker_Trader" )			
			end
		end
	end

	xrMain.mapCanvas:update()
end

function xrMain.open()	
	if xrMain.isEnabled then
		return
	end	

	addEventHandler( "onClientRender", root, xrMain.onRender, false )
	addEventHandler( "onClientCursorMove", root, xrMain.onCursorMove, false )
	addEventHandler( "onClientClick", root, xrMain.onCursorClick, false )
	addEventHandler( "onClientKey", root, xrMain.onKey, false )
	
	showCursor( true )
	guiSetInputEnabled( true )

	xrMain.isEnabled = true
end

function xrMain.close()
	if xrMain.isEnabled then
		removeEventHandler( "onClientRender", root, xrMain.onRender )
		removeEventHandler( "onClientCursorMove", root, xrMain.onCursorMove )
		removeEventHandler( "onClientClick", root, xrMain.onCursorClick )
		removeEventHandler( "onClientKey", root, xrMain.onKey, false )

		showCursor( false )
		guiSetInputEnabled( false )

		xrMain.isEnabled = false
	end
end

function xrMain.onCenterBtnPressed()
	local tw = ORIGIN_TEX_WIDTH * 2
	local th = tw / ORIGIN_TEX_ASPECT
	local rx, ry = getElementMapPosition( localPlayer )
	local tx, ty = xrMain.mapRt.tw / 2 - rx * tw, xrMain.mapRt.th / 2 - ry * th

	xrMain.centering = {
		sx = xrMain.mapCanvas.screenX,
		sy = xrMain.mapCanvas.screenY,
		tx = tx,
		ty = ty,
		sw = xrMain.mapCanvas.screenWidth,
		tw = tw,
		startTime = getTickCount()
	}
end

function xrMain.onMapRadioPressed( radioIndex )
	if radioIndex == 3 then
		for _, frame in ipairs( questBlips ) do
			frame:setVisible( source.stateIdx == UIBTN_CLICKED )
		end
	end
end

function xrMain.onQuestsListToggle()
	xrMain.questsWnd:setVisible( not xrMain.questsWnd.visible )
		
end

function xrMain:scaleAt( cx, cy, scale )
	local rx = ( cx - xrMain.mapCanvas.screenX ) / xrMain.mapCanvas.screenWidth
	local ry = ( cy - xrMain.mapCanvas.screenY ) / xrMain.mapCanvas.screenHeight

	local width = xrMain.mapCanvas.screenWidth + xrMain.mapCanvas.screenWidth * scale
	local height = xrMain.mapCanvas.screenHeight + xrMain.mapCanvas.screenHeight * scale
	width = math.clamp( ORIGIN_TEX_WIDTH*MAP_MIN_SCALE, ORIGIN_TEX_WIDTH*MAP_MAX_SCALE, width )
	height = math.clamp( ORIGIN_TEX_HEIGHT*MAP_MIN_SCALE, ORIGIN_TEX_HEIGHT*MAP_MAX_SCALE, height )

	local x = cx - width*rx
	local y = cy - height*ry

	xrMain.mapCanvas:setSize( width, height )
	xrMain.mapCanvas:setPosition( x, y )
	xrMain.mapCanvas:update()
end

function xrMain.onRender()
	local dx, dy = 0, 0

	if xrMain.arrowUpBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 0, 1
	elseif xrMain.arrowDownBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 0, -1
	elseif xrMain.arrowRightBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = -1, 0
	elseif xrMain.arrowLeftBtn.stateIdx == UIBTN_CLICKED then
		dx, dy = 1, 0
	end

	if dx ~= 0 or dy ~= 0 then
		local x = xrMain.mapCanvas.screenX + dx*5
		local y = xrMain.mapCanvas.screenY + dy*5	

		xrMain.mapCanvas:setPosition( x, y )
		xrMain.mapCanvas:update()
	end

	local scale = 0

	if xrMain.zoomInBtn.stateIdx == UIBTN_CLICKED then
		scale = 1
	elseif xrMain.zoomOutBtn.stateIdx == UIBTN_CLICKED then
		scale = -1
	end

	if scale ~= 0 then
		local cx, cy = xrMain.mapRt.tw / 2, xrMain.mapRt.th / 2
		xrMain:scaleAt( cx, cy, scale*0.005 )
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
	xrMain.timeLbl:setText( hours .. " : " .. mins )

	--[[
		Map
	]]

	-- Player
	local rx, ry = getElementMapPosition( localPlayer )
	local _, _, rot = getElementRotation( localPlayer )

	xrMain.playerFrame:applyTransform( rx * xrMain.mapFrame.originWidth - PLAYER_ICON_SIZE/2, ry * xrMain.mapFrame.originHeight - PLAYER_ICON_SIZE/2, PLAYER_ICON_SIZE, PLAYER_ICON_SIZE, true )
	xrMain.playerFrame:update()

	local arrowScale = 1.884615
	local arrowSize = PLAYER_ICON_SIZE * arrowScale
	xrMain.playerArrowFrame:applyTransform( rx * xrMain.mapFrame.originWidth - arrowSize/2, ry * xrMain.mapFrame.originHeight - arrowSize/2, arrowSize, arrowSize, true )
	xrMain.playerArrowFrame:setRotation( 360 - rot )
	xrMain.playerArrowFrame:update()

	--[[
		Centering
	]]
	local centering = xrMain.centering
	if centering then
		local now = getTickCount()
		local t = ( now - centering.startTime ) / 1000
		if t >= 1 then
			xrMain.centering = nil
		else
			t = getEasingValue( t, "OutQuad" )
			local width = math.interpolate( centering.sw, centering.tw, t )
			local height = width / ORIGIN_TEX_ASPECT
			local x = math.interpolate( centering.sx, centering.tx, t )
			local y = math.interpolate( centering.sy, centering.ty, t )

			xrMain.mapCanvas:setSize( width, height )
			xrMain.mapCanvas:setPosition( x, y )
			xrMain.mapCanvas:update()
		end
	end

	xrMain.canvas:draw()
end

function xrMain.onCursorMove( _, _, ax, ay )
	xrMain.canvas:onCursorMove( ax, ay )

	local rx = ax - xrMain.mapRt.tx
	local ry = ay - xrMain.mapRt.ty

	if xrMain.mapDragDrop then
		xrMain.mapCanvas:setPosition( rx - xrMain.mapDragDrop.bx, ry - xrMain.mapDragDrop.by )
		xrMain.mapCanvas:update()
	end
end


function xrMain.onCursorClick( btn, state, ax, ay )	
	xrMain.canvas:onCursorClick( btn, state, ax, ax )

	if state == "down" then
		if xrMain.canvas.focused == xrMain.mapMask then
			local rx = ax - xrMain.mapRt.tx
			local ry = ay - xrMain.mapRt.ty
			
			local bx = rx - xrMain.mapCanvas.screenX
			local by = ry - xrMain.mapCanvas.screenY

			xrMain.mapDragDrop = {
				bx = bx,
				by = by
			}
		end
	else
		xrMain.mapDragDrop = nil
	end
end

function xrMain.onKey( btn, pressed )
	local cx, cy = getCursorPosition()

	if btn == "mouse_wheel_up" then
		if xrMain.canvas.focused == xrMain.mapMask then
			local rx = cx*sw - xrMain.mapRt.tx
			local ry = cy*sh - xrMain.mapRt.ty

			xrMain:scaleAt( rx, ry, 0.05 )
		end
	elseif btn == "mouse_wheel_down" then
		if xrMain.canvas.focused == xrMain.mapMask then
			local rx = cx*sw - xrMain.mapRt.tx
			local ry = cy*sh - xrMain.mapRt.ty

			xrMain:scaleAt( rx, ry, -0.05 )
		end
	elseif btn == "i" and pressed then
		xrMain.close()
	end
end

--[[
	Init
]]
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		--xrIncludeModule( "uiconfig.lua" )
		xrIncludeModule( "global.lua" )

		xrLoadUIColorDict( "color_defs" )
		xrLoadAllUIFileDescriptors()

		xrMain.init()


		-- Test
		showCursor( false )
		guiSetInputEnabled( false )
		bindKey( "i", "down",
			function()
				if xrMain.isEnabled then
					xrMain.close()
				else
					xrMain.open()
				end
			end
		)
    end
)