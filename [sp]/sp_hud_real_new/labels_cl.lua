local DRAW_RADIUS_SQR = 40*40
local DRAW_THRESHOLD_RADIUS_SQR = 30*30


local headMarks = {
	"ui_icons_newPDA_markSrtef_e",
	"ui_mapQuest_stalker_destroy"
}

local rankTextureLookup = {
	"ui_hud_status_blue_01",
	"ui_hud_status_blue_02",
	"ui_hud_status_blue_03",
	"ui_hud_status_blue_04"
}

xrLabels = {

}

local xrIsAdminMode = false

function xrLabels:setup()
    if self.initialized then
        return false
	end
	
	self.tex = exports.sp_assets:xrLoadAsset( "ui_hud" )
	self.texCommon = exports.sp_assets:xrLoadAsset( "ui_common" )

	self.players = {}
	self.peds = {}
    self.initialized = true

    return true
end

function xrLabels:destroy()
    if not self.initialized then
        return
    end    

    self.initialized = nil
end

function xrLabels:drawElement( player, distSqr, cr, cg, cb, isOurTeam, isWanted )
	local hx, hy, hz = getPedBonePosition( player, 6 )
	local x, y = getScreenFromWorldPosition( hx, hy, hz + 0.25 )
	if x then
		local factor = 1 - math.min( distSqr / DRAW_RADIUS_SQR, 1 )
		local alpha = 255 * factor*factor

		local textSize = factor * 1.7
		local name = player:getData( "name", false ) or ""
		if xrIsAdminMode then
			name = name .. "(" .. player:getData( "charId", false ) .. ")"
		end

		local textWidth = dxGetTextWidth( name, textSize, "default" )
		local textHeight = dxGetFontHeight( textSize, "default" )		
		
		--[[
			Rank icon
		]]
		local rank = math.clamp( 0, 1000, tonumber( player:getData( "rank", false ) ) or 0 )			
		local randIndex = math.floor( ( rank / 1000 ) * 4 )
		if randIndex > 0 then
			local rankTexSection = xrTextureSections[ rankTextureLookup[ randIndex ] ]
			if rankTexSection then
				local iconScale = factor * 0.5
				local width = rankTexSection.width * iconScale
				local height = rankTexSection.height * iconScale

				local gapWidth = 4
				local rowWidth = width + textWidth + gapWidth

				rankTexSection:draw( self.tex, x - rowWidth/2, y - height/2, width, height, 0, 0, 0, tocolor( 255, 255, 255, alpha ) )
				dxDrawText( name, x - rowWidth/2 + width + gapWidth, y - textHeight/2, sw, y + textHeight/2, tocolor( cr, cg, cb, alpha ), textSize, "default" )
			end
		else
			dxDrawText( name, x - textWidth/2, y - textHeight/2, x + textWidth/2, y + textHeight/2, tocolor( cr, cg, cb, alpha ), textSize, "default" )
		end			
		
		if isWanted then
			local texSection = xrTextureSections[ headMarks[ 2 ] ]
			local iconScale = factor * 1.4
			local width = texSection.width * iconScale
			local height = texSection.height * iconScale

			texSection:draw( self.texCommon, x - width/2, ( y - textHeight - height ), width, height, 0, 0, 0, tocolor( 255, 255, 255, alpha ) )

		elseif getElementData( player, "chat", false ) then
			local iconScale = factor * 0.8
			local width = 100 * iconScale
			local height = 100 * iconScale

			local gapHeight = 6
			local ix = x - width/2
			local iy = y - textHeight/2 - gapHeight - height
			dxDrawImage( ix, iy, width, height, "textures/chat.png", 0, 0, 0, tocolor( 255, 255, 255, alpha ) )
		end
	end
end

function xrLabels:draw()
    if not self.initialized then
        return
    end

	local team = getPlayerTeam( localPlayer )
	local target = getPedTarget( localPlayer )
	local camPosX, camPosY, camPosZ = getElementPosition( getCamera() )

	for _, element in ipairs( self.players ) do
		if isElement( element ) then
			local playerPosX, playerPosY, playerPosZ = getElementPosition( element )
			local distSqr = ( camPosX - playerPosX )^2 + ( camPosY - playerPosY )^2
			local isOurTeam = getPlayerTeam( element ) == team
			local isWanted = xrIsPlayerWanted( element, team )

			if isOurTeam or ( ( target == element and distSqr <= 64 ) or isWanted ) then
				if isOurTeam then
					self:drawElement( element, distSqr, 230, 230, 230, isOurTeam, isWanted )
				else
					self:drawElement( element, distSqr, 230, 10, 10, isOurTeam, isWanted )
				end
			end
		end
	end

	for _, element in ipairs( self.peds ) do
		if isElement( element ) then
			local playerPosX, playerPosY, playerPosZ = getElementPosition( element )
			local distSqr = ( camPosX - playerPosX )^2 + ( camPosY - playerPosY )^2

			self:drawElement( element, distSqr, 230, 230, 10, true )
		end
	end	
end

function xrLabels:update()
	self.players = {
		-- Очищаем очередь
	}
	self.peds = {
		-- Очищаем очередь
	}
	
	local team = getPlayerTeam( localPlayer )
	local teamName = team and getTeamName( team ) or EMPTY_STR
	local camPosX, camPosY, camPosZ = getElementPosition( getCamera() )
	
	for _, player in ipairs( getElementsByType( "player", root, true ) ) do
		if player ~= localPlayer then
			local playerPosX, playerPosY, playerPosZ = getElementPosition( player )
			local distSqr = ( camPosX - playerPosX )^2 + ( camPosY - playerPosY )^2

			if distSqr <= DRAW_THRESHOLD_RADIUS_SQR and isLineOfSightClear( camPosX, camPosY, camPosZ, playerPosX, playerPosY, playerPosZ, true, true, false, true, true, false, false, player ) then 
				table.insert( self.players, player )
			end
		end
	end

	for _, ped in ipairs( getElementsByType( "ped", root, true ) ) do
		local pedTeamName = getElementData( ped, "team", false )
		if not pedTeamName or pedTeamName == teamName then
			local playerPosX, playerPosY, playerPosZ = getElementPosition( ped )
			local distSqr = ( camPosX - playerPosX )^2 + ( camPosY - playerPosY )^2

			if distSqr <= DRAW_THRESHOLD_RADIUS_SQR and isLineOfSightClear( camPosX, camPosY, camPosZ, playerPosX, playerPosY, playerPosZ, true, true, false, true, true, false, false, ped ) then 
				table.insert( self.peds, ped )
			end
		end
	end
	
	local target = getPedTarget( localPlayer )
	if isElement( target ) and getElementType( target ) == "player" and target ~= localPlayer then
		table.insert( self.players, target )
	end

	xrIsAdminMode = getElementData( localPlayer, "adminmode", false ) == true
end