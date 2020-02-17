local sw, sh = guiGetScreenSize ( )

local radiationNames = {
	"ui_inGame2_circle_radiation_yellow", "ui_inGame2_circle_radiation_orange", "ui_inGame2_circle_radiation_red"
}
local radiationFieldNames = {
	"ui_inGame2_triangle_Radiation_yellow", "ui_inGame2_triangle_Radiation_orange", "ui_inGame2_triangle_Radiation_red"
}
local bleedingNames = {
	"ui_inGame2_circle_bloodloose_yellow", "ui_inGame2_circle_bloodloose_orange", "ui_inGame2_circle_bloodloose_red"
}
local wpnBrokenNames = {
	"ui_inGame2_circle_Gunbroken_yellow", "ui_inGame2_circle_Gunbroken_orange", "ui_inGame2_circle_Gunbroken_red"
}
local overweightNames = {
	"ui_inGame2_circle_Overweight_yellow", "ui_inGame2_circle_Overweight_orange", "ui_inGame2_circle_Overweight_red"
}

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

PLAYER_ICON_SIZE = 8

local function getElementMapPosition( element )
	local x, y = getElementPosition( element )
	local rx, ry = ( x - MAP_LEFT + MAP_BIAS_X ) / MAP_WIDTH, -( y - MAP_BOTTOM + MAP_BIAS_Y ) / MAP_HEIGHT

	return rx, ry
end

xrMain = {
	isEnabled = false,
	boosters = {}
}

local _frameLookup = setmetatable( {}, { __mode = "kv" } )
local _boosterLookup = setmetatable( {}, { __mode = "kv" } )
local _boosterFrameNames = setmetatable( {}, { __mode = "kv" } )

local hudDataNames = {
	"ammo", 
	"_waic",
	"_wta",
	"radiation",
	"bleeding",
	"_wcn",
	"damageProof",
	"power"
}

function xrMain:init()
	self.canvas = xrCreateUICanvas( 0, 0, sw, sh )

	local xml = xmlLoadFile( "config/Hud.xml", true )
	if xml then
		self.canvas:load( xml )				

		-- Патроны
		do
			local frame = self.canvas:getFrame( "AmmoFrame", true ):setVisible( false )

			_frameLookup.wpnAmmoFrame = frame
			_frameLookup.wpnFireMode = frame:getFrame( "FireMode", true )
			_frameLookup.wpnGranadeType = frame:getFrame( "GranadeType", true )
			_frameLookup.wpnAmmoInClip = frame:getFrame( "AmmoInClip", true )
			_frameLookup.wpnAmmoTotal = frame:getFrame( "AmmoTotal", true )
			_frameLookup.wpnTotalAPAmmo = frame:getFrame( "TotalAPAmmo", true )
			_frameLookup.wpnAmmoIcon = frame:getFrame( "AmmoIcon", true )
			_frameLookup.health = self.canvas:getFrame( "HealthProgress", true )
			_frameLookup.stamina = self.canvas:getFrame( "StaminaProgress", true )
		end

		-- Индикаторы состояния
		do
			local frame = self.canvas:getFrame( "Indicators", true )

			_frameLookup.indicHunger = frame:getFrame( "IndicHunger", true ):setVisible( false )
			_frameLookup.indicHelmet = frame:getFrame( "IndicHelmet", true ):setVisible( false )
			_frameLookup.indicOutfit = frame:getFrame( "IndicOutfit", true ):setVisible( false )
			_frameLookup.indicWeapBroke = frame:getFrame( "IndicWeapBroke", true ):setVisible( false )
			_frameLookup.indicOverweight = frame:getFrame( "IndicOverweight", true ):setVisible( false )
			_frameLookup.indicRad = frame:getFrame( "IndicRad", true ):setVisible( false )
			_frameLookup.indicBleeding = frame:getFrame( "IndicBleeding", true ):setVisible( false )
		end		

		-- Индикаторы опасности
		do
			local frame = self.canvas:getFrame( "IndicatorsDanger", true )

			_frameLookup.dangerRadio = frame:getFrame( "DangerRadio", true ):setVisible( false )
			_frameLookup.dangerFire = frame:getFrame( "DangerFire", true ):setVisible( false )
			_frameLookup.dangerPsy = frame:getFrame( "DangerPsy", true ):setVisible( false )
			_frameLookup.dangerAcid = frame:getFrame( "DangerAcid", true ):setVisible( false )

			_frameLookup.greenZone = self.canvas:getFrame( "GreenZoneLbl", true ):setVisible( getElementData( localPlayer, "damageProof", false ) == true )
		end		

		-- Индикаторы бустеров
		do
			local frame = self.canvas:getFrame( "IndicatorsBoosters", true )

			_boosterFrameNames = {
				[ b_telepat_i ] = frame:getFrame( "BoosterPsy", true ):setVisible( false ),
				[ b_radiation_r ] = frame:getFrame( "BoosterRad", true ):setVisible( false ),
				[ b_chemburn_p ] = frame:getFrame( "BoosterBio", true ):setVisible( false ),
				[ b_bleeding_r ] = frame:getFrame( "BoosterBlood", true ):setVisible( false ),
				[ b_max_weight ] = frame:getFrame( "BoosterForce", true ):setVisible( false ),
				[ b_health_r ] = frame:getFrame( "BoosterHealth", true ):setVisible( false ),
				[ b_power_r ] = frame:getFrame( "BoosterStamina", true ):setVisible( false ),
				[ b_radiation_p ] = frame:getFrame( "BoosterRadCleanup", true ):setVisible( false )
			}
		end

		xmlUnloadFile( xml )
	end

	xrLabels:setup()
	xrRankbar:setup( rank )
	xrHelpWindow:setup()
	xrHitMark:setup()
	xrRadar:setup( self.canvas )
	xrNewsWindow:setup( self.canvas )

	self.canvas:update()
end

function xrMain:open()	
	if xrMain.isEnabled ~= true then
		local rank = getElementData( localPlayer, "rank", false )
		xrRankbar:setRank( rank )

		--[[
			Форсируем обновление данных
		]]
		for _, name in ipairs( hudDataNames ) do
			local value = getElementData( localPlayer, name, false )
			xrMain.onPlayerDataChange( name, false, value )
		end

		addEventHandler( "onClientRender", root, xrMain.onRender, false )

		xrMain.pulseTimer = setTimer( xrMain.onPulse, 150, 0 )
		xrMain.timer = setTimer( xrMain.onTimer, 50, 0 )
		xrMain.updatePhase = 1

		xrMain.isEnabled = true
		xrMain.lastFrameTime = getTickCount()
	end
end

function xrMain:close()
	if xrMain.isEnabled then
		removeEventHandler ( "onClientRender", root, xrMain.onRender )

		if isTimer( xrMain.pulseTimer ) then
			killTimer( xrMain.pulseTimer )
		end
		if isTimer( xrMain.timer ) then
			killTimer( xrMain.timer )
		end

		xrMain.isEnabled = false
		xrMain.lastFrameTime = nil
	end
end

local function updateDiscreteIndicator( frame, value, textureNames )
	if value > 0.001 then	
		local textureDesc = textureNames[ 1 ]
		if value > 0.75 then
			textureDesc = textureNames[ 3 ]
		elseif value > 0.3 then
			textureDesc = textureNames[ 2 ]
		end

		frame:setTextureSection( textureDesc )
		frame:setVisible( true )
	else
		frame:setVisible( false )
	end
end

function xrMain.onRender()
	local now = getTickCount()
	local dt = now - xrMain.lastFrameTime

	do
		local boosters = xrMain.boosters

		for i, _ in ipairs( BoostTypes ) do
			local endTime = boosters[ i ]
			if endTime and now >= endTime then
				boosters[ i ] = nil

				-- Скрываем фрейм бустера
				local frame = _boosterFrameNames[ i ]
				if frame then
					frame:setVisible( false )
				end
			end
		end
	end	

	xrLabels:draw( dt )

	xrRadar:draw( dt )

	xrRankbar:draw( dt )

	xrHelpWindow:draw( dt )

	xrHitMark:draw( dt )

	xrNewsWindow:draw( dt )

	xrMain.canvas:draw()

	xrMain.lastFrameTime = now
end

function xrMain.onTimer()
	if xrMain.updatePhase == 1 then
		xrLabels:update()
	elseif xrMain.updatePhase == 2 then
		xrRadar:update()
	elseif xrMain.updatePhase == 3 then
		xrRankbar:update()
	elseif xrMain.updatePhase == 4 then
		xrHelpWindow:update()
	elseif xrMain.updatePhase == 5 then
		xrHitMark:update()
	elseif xrMain.updatePhase == 6 then
		xrNewsWindow:update()
	end

	if xrMain.updatePhase < 6 then
		xrMain.updatePhase = xrMain.updatePhase + 1
	else
		xrMain.updatePhase = 1
	end
end

function xrMain.onPulse()
	updateDiscreteIndicator( _frameLookup.dangerRadio, exports.anomaly:xrGetPlayerZoneInfluence( EHashes.ZoneRadiation ), radiationFieldNames )

	local weight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
	local overweight = math.max( weight - PLAYER_OVERWEIGHT_START, 0 )
	updateDiscreteIndicator( _frameLookup.indicOverweight, math.clamp( 0, 1, overweight / MAX_PLAYER_WEIGHT - 0.3 ), overweightNames )

	local health = getElementHealth( localPlayer ) / 100
	_frameLookup.health:setProgress( health )
end

function xrMain.onBoosterApplied( index, time )
	xrMain.boosters[ index ] = getTickCount() + ( time * 1000 )

	-- Показываем фрейм бустера
	local frame = _boosterFrameNames[ index ]
	if frame then
		frame:setVisible( true )
	end
end

function xrMain.onAddRank( delta )
    xrRankbar:promote( delta )
end

function xrMain.onHelpStringRecieved( strCode )
	local strData = EHelpStrings[ strCode ]
	if strData then
		local text = strData[ 1 ]
		local priority = tonumber( strData[ 2 ] ) or 0
		local duration = tonumber( strData[ 3 ] ) or 10000
		local appearanceProbability = tonumber( strData[ 4 ] ) or 1

		if math.random() <= appearanceProbability then
			xrHelpWindow:print( text, priority, duration )
		end
	elseif strCode == HSC_NONE then
		xrHelpWindow:hideAll()
	end
end

function xrMain.onNewsRecieved( text, textureSectionName )
	xrNewsWindow:print( text, textureSectionName )
end

function xrMain.onPlayerDataChange( key, oldValue, newValue )
	if key == "ammo" then 
		local itemSection = xrSettingsGetSection( newValue )
		if itemSection then
			local frame = _frameLookup.wpnAmmoIcon

			frame:setUV( 
				itemSection.inv_grid_x * 50, itemSection.inv_grid_y * 50, 
				itemSection.inv_grid_width * 50, itemSection.inv_grid_height * 50
			)

			local centerX, centerY = 222 + 29 / 2, 106 + 36 / 2
			local size = math.min( 29 * 3, 36 * 3 )
			local aspect = ( itemSection.inv_grid_height * 50 ) / ( itemSection.inv_grid_width * 50 )
			local scale = 1
			
			frame:setPosition( centerX - size*scale*0.5, centerY - size*scale*aspect*0.5 )
			frame:setSize( size*scale, size*scale*aspect )
			frame:update()

			_frameLookup.wpnAmmoFrame:setVisible( true )
		else
			_frameLookup.wpnAmmoFrame:setVisible( false )
		end
	elseif key == "_waic" then
		_frameLookup.wpnAmmoInClip:setText( tonumber( newValue ) or 0 )
	elseif key == "_wta" then
		_frameLookup.wpnAmmoTotal:setText( tonumber( newValue ) or 0 )
	elseif key == "radiation" then
		updateDiscreteIndicator( _frameLookup.indicRad, tonumber( newValue ) or 0, radiationNames )
	elseif key == "bleeding" then
		updateDiscreteIndicator( _frameLookup.indicBleeding, tonumber( newValue ) or 0, bleedingNames )
	elseif key == "_wcn" then
		updateDiscreteIndicator( _frameLookup.indicWeapBroke, tonumber( newValue ) or 0, wpnBrokenNames )
	elseif key == "damageProof" then
		_frameLookup.greenZone:setVisible( newValue == true )
	elseif key == "power" then
		_frameLookup.stamina:setProgress( tonumber( newValue ) or 0 )
	end
end

function xrMain.onElementDestroy()

end

function xrMain.onPlayerJoin()
	
end

function xrMain.onPlayerLeave()
	
end

function xrMain.onZoneCreated()
	
end

--[[
	Export
]]
function xrSendPlayerHelpString( player, strCode )
	if player ~= localPlayer then
		return false
	end

	xrMain.onHelpStringRecieved( strCode )
	return true
end

function xrPrintNews( text, textureSectionName )
	xrMain.onNewsRecieved( text, textureSectionName )
end

--[[
	Init
]]
addEvent( "onClientCoreStarted", false )
--addEventHandler( "onClientResourceStart", resourceRoot,
addEventHandler( "onClientCoreStarted", root,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		xrIncludeModule( "player.lua" )
		xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            return
		end

		if not xrSettingsInclude( "teams.ltx" ) then
            return
        end

		xrLoadAllUIFileDescriptors()

		xrMain:init()

		addEvent( EClientEvents.onClientBoosterApplied, false )
		addEventHandler( EClientEvents.onClientBoosterApplied, localPlayer, xrMain.onBoosterApplied, false )
		addEvent( EClientEvents.onClientAddRank, true )
		addEventHandler( EClientEvents.onClientAddRank, localPlayer, xrMain.onAddRank, false )	
		addEvent( EClientEvents.onClientHelpString, true )
		addEventHandler( EClientEvents.onClientHelpString, localPlayer, xrMain.onHelpStringRecieved, false )
		addEvent( EClientEvents.onClientNewsMessage, true )
		addEventHandler( EClientEvents.onClientNewsMessage, resourceRoot, xrMain.onNewsRecieved, false )
		addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeJoin, root, xrMain.onPlayerJoin )
        addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeLeave, root, xrMain.onPlayerLeave )    
		addEventHandler( "onClientElementDataChange", localPlayer, xrMain.onPlayerDataChange, false )
		addEventHandler( "onClientElementDestroy", root, xrMain.onElementDestroy )
		addEvent( "onClientZoneCreated", false )
		addEventHandler( "onClientZoneCreated", root, xrMain.onZoneCreated )

		--xrHUDSetEnabled( true )
    end
)

function xrHUDSetEnabled( enabled )
	if enabled then
		xrMain:open()
	else
		xrMain:close()
	end
end