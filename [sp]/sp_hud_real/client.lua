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

xrExtraTexDict = {

}

xrMain = {
	isEnabled = false,
	boosters = {}
}

function xrMain.init()
	xrExtraTexDict[ "ui_hud" ] = dxCreateTexture( "textures/ui/ui_hud.dds" )
	xrExtraTexDict[ "ui_common" ] = dxCreateTexture( "textures/ui_common.dds" )
	xrExtraTexDict[ "ui_logos" ] = exports.sp_assets:xrLoadAsset( "ui_logos" )

	xrMain.desc = xrCreateUICanvas( "maingame", 0, 0, 1024, 768, sw, sh )
	xrMain.desc:loadTexture( "ui_hud" )
	xrMain.desc:loadTexture( "ui_actor_hint_wnd" )
	xrMain.desc:loadTexture( "ui_icon_equipment" )
	xrMain.desc:loadFont( "graffiti32", "AG Letterica Roman Medium.ttf", 20, true )
	xrMain.desc:loadFont( "graffiti19", "AG Letterica Roman Medium.ttf", 14, true )
	xrMain.desc:loadFont( "letterica16", "AG Letterica Roman Medium.ttf", 8, true )

	local radarFrame = xrMain.desc:getFrame( "minimap_radar" )
	if xrRadar:setup( radarFrame.tw * 2, radarFrame.th * 2 ) then
		radarFrame:setTexture( xrRadar.shader )
	end

	xrLabels:setup()
	xrRankbar:setup( rank )
	xrHelpWindow:setup()
	xrHitMark:setup()
	xrNewsWindow:setup()
end

function xrMain.open()	
	if xrMain.isEnabled ~= true then
		local rank = getElementData( localPlayer, "rank", false )
		xrRankbar:setRank( rank )

		addEventHandler ( "onClientRender", root, xrMain.onRender, false )
		xrMain.timer = setTimer( xrMain.onTimer, 50, 0 )
		xrMain.updatePhase = 1

		xrMain.isEnabled = true
		xrMain.lastFrameTime = getTickCount()
	end
end

function xrMain.close()
	if xrMain.isEnabled then
		removeEventHandler ( "onClientRender", root, xrMain.onRender )
		killTimer( xrMain.timer )

		xrMain.isEnabled = false
		xrMain.lastFrameTime = nil
	end
end

local function updateBoosters()
	local boosters = xrMain.boosters
	local now = getTickCount()

	for i, _ in ipairs( BoostTypes ) do
		local endTime = boosters[ i ]
		if endTime and now >= endTime then
			boosters[ i ] = nil
		end
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
		frame.visible = true
	else
		frame.visible = false
	end
end

local function _drawBoosters()
	local uiDesc = xrMain.desc
	local boosters = xrMain.boosters

	updateBoosters()
	uiDesc:setFrameEnabled( "indicator_booster_psy", boosters[ b_telepat_i ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_radia", boosters[ b_radiation_r ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_chem", boosters[ b_chemburn_p ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_wound", boosters[ b_bleeding_r ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_weight", boosters[ b_max_weight ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_health", boosters[ b_health_r ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_power", boosters[ b_power_r ] ~= nil )
	uiDesc:setFrameEnabled( "indicator_booster_rad", boosters[ b_radiation_p ] ~= nil )

	local radFrame = uiDesc:getFrame( "indicator_radiation" )
	updateDiscreteIndicator( radFrame, getElementData( localPlayer, "radiation", false ) or 0, radiationNames )

	local bleedingFrame = uiDesc:getFrame( "indicator_bleeding" )
	updateDiscreteIndicator( bleedingFrame, getElementData( localPlayer, "bleeding", false ) or 0, bleedingNames )

	local radIndicFrame = uiDesc:getFrame( "indik_rad" )
	updateDiscreteIndicator( radIndicFrame, exports.anomaly:xrGetPlayerZoneInfluence( EHashes.ZoneRadiation ), radiationFieldNames )

	local wpnBrokenFrame = uiDesc:getFrame( "indicator_weapon_broken" )
	updateDiscreteIndicator( wpnBrokenFrame, getElementData( localPlayer, "_wcn", false ) or 0, wpnBrokenNames )

	local overweightFrame = uiDesc:getFrame( "indicator_overweight" )
	local weight = exports.xritems:xrGetContainerWeight( localPlayer ) or 0
	local overweight = math.max( weight - PLAYER_OVERWEIGHT_START, 0 )
	updateDiscreteIndicator( overweightFrame, math.clamp( 0, 1, overweight / MAX_PLAYER_WEIGHT - 0.3 ), overweightNames )
end

local function _drawWeapon()
	local uiDesc = xrMain.desc

	local ammoIconFrame = uiDesc:getFrame( "static_wpn_icon" )
	local curAmmoFrame = uiDesc:getFrame( "static_cur_ammo" )
	local totalAmmoFrame = uiDesc:getFrame( "static_fmj_ammo" )
	local granadeFrame = uiDesc:getFrame( "static_grenade" )
	local fireModeFrame = uiDesc:getFrame( "static_fire_mode" )
	local ammoModeFrame = uiDesc:getFrame( "static_ap_ammo" )

	--[[
		Weapon's ammo info
	]]
	local itemHash = getElementData( localPlayer, "ammo", false )
    local itemSection = xrSettingsGetSection( itemHash )
	if itemSection then
		ammoIconFrame:setUV( 
			itemSection.inv_grid_x * 50, itemSection.inv_grid_y * 50, 
			itemSection.inv_grid_width * 50, itemSection.inv_grid_height * 50
		)
		local aspect = ( itemSection.inv_grid_height * 50 ) / ( itemSection.inv_grid_width * 50 )
		local scale = ( sw / 1920 ) * 0.9
		ammoIconFrame:setSize( 135 * scale, 135 * scale * aspect )

		ammoIconFrame.visible = true
		curAmmoFrame.visible = true	
		totalAmmoFrame.visible = true	
		granadeFrame.visible = true
		fireModeFrame.visible = true
		ammoModeFrame.visible = true
	else
		ammoIconFrame.visible = false
		curAmmoFrame.visible = false
		totalAmmoFrame.visible = false	
		granadeFrame.visible = false
		fireModeFrame.visible = false
		ammoModeFrame.visible = false
	end
	
	--[[
		Ammo
	]]
	local ammo = getElementData( localPlayer, "_waic", false ) or 0
	local totalAmmo = getElementData( localPlayer, "_wta", false ) or 0
	curAmmoFrame.text = ammo
	totalAmmoFrame.text = totalAmmo
	granadeFrame.text = "0"
	fireModeFrame.text = "A"
	ammoModeFrame.text = "0"

	--[[
		Update progress bars
	]]
	local health = getElementHealth( localPlayer )
	uiDesc:getFrame( "progress_bar_health" ):setPosition( health )

	local stamina = getElementData( localPlayer, "power", false ) or 1
	uiDesc:getFrame( "progress_bar_stamina" ):setPosition( stamina * 100 )
end

function xrMain.onRender()
	local uiDesc = xrMain.desc
	local now = getTickCount()
	local dt = now - xrMain.lastFrameTime

	_drawBoosters()

	_drawWeapon()	

	local areaNameSection = uiDesc:getFrame( "area_name_text" )
	if areaNameSection then
		areaNameSection.visible = getElementData( localPlayer, "damageProof", false )
	end

	xrLabels:draw( dt )

	xrRadar:draw( dt )

	xrRankbar:draw( dt )

	xrHelpWindow:draw( dt )

	xrHitMark:draw( dt )

	xrNewsWindow:draw( dt )

	xrMain.desc:draw()

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

function xrMain.onBoosterApplied( index, time )
	xrMain.boosters[ index ] = getTickCount() + ( time * 1000 )
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

--[[
	Init
]]
addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientResourceStart", resourceRoot,
--addEventHandler( "onClientCoreStarted", root,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		xrIncludeModule( "player.lua" )
		xrIncludeModule( "uiconfig.lua" )
		xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            return
		end

		if not xrSettingsInclude( "teams.ltx" ) then
            return
        end		

		xrLoadUIColorDict( "color_defs" )
		xrLoadAllUIFileDescriptors()

		xrMain.init()

		addEvent( EClientEvents.onClientBoosterApplied, false )
		addEventHandler( EClientEvents.onClientBoosterApplied, localPlayer, xrMain.onBoosterApplied, false )
		addEvent( EClientEvents.onClientAddRank, true )
		addEventHandler( EClientEvents.onClientAddRank, localPlayer, xrMain.onAddRank, false )	
		addEvent( EClientEvents.onClientHelpString, true )
		addEventHandler( EClientEvents.onClientHelpString, localPlayer, xrMain.onHelpStringRecieved, false )

		xrHUDSetEnabled( true )
    end
)

function xrHUDSetEnabled( enabled )
	if enabled then
		xrMain.open()
	else
		xrMain.close()
	end
end