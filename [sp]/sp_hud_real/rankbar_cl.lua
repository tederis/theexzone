local sw, sh = guiGetScreenSize ( )

local rankTextureLookup = {
	"ui_hud_status_blue_01",
	"ui_hud_status_blue_02",
	"ui_hud_status_blue_03",
	"ui_hud_status_blue_04"
}

xrRankbar = {

}

function xrRankbar:setup()
    if self.initialized then
        return false
    end

    self.font = dxCreateFont ( "AGLettericaExtraCompressed Roman.ttf", 18 )

    self.initialized = true

    return true
end

function xrRankbar:destroy()
    if not self.initialized then
        return
    end

    destroyElement( self.font )

    self.initialized = nil
end

function xrRankbar:setRank( rank )
	self.rank = rank
end

function xrRankbar:draw()
    if not self.initialized then
        return
    end

    local now = getTickCount()

	if self.rankShowTime then
		local aspect = 0.01
		local width = sw  * 0.4
		local height = width * aspect
		local x = sw / 2 - width / 2
		local y = sh * 0.1	
		local iconHeight = height * 6
		
		local randIndex = math.floor( self.rank / 1000 * 4 )
		if randIndex > 0 then
			local rankTexSection = xrTextureSections[ rankTextureLookup[ randIndex ] ]
			if rankTexSection then
				local iconWidth = iconHeight * ( rankTexSection.width / rankTexSection.height )
				rankTexSection:draw( xrExtraTexDict, x - iconWidth*1.5, y + height / 2 - iconHeight / 2, iconWidth, iconHeight )
			end
		end

		randIndex = math.floor( self.rank / 1000 * 4 ) + 1
		if randIndex <= 4 then
			rankTexSection = xrTextureSections[ rankTextureLookup[ randIndex ] ]
			if rankTexSection then
				local iconWidth = iconHeight * ( rankTexSection.width / rankTexSection.height )
				rankTexSection:draw( xrExtraTexDict, x + width + iconWidth*0.5, y + height / 2 - iconHeight / 2, iconWidth, iconHeight )
			end		
		end

		local level = math.floor( self.rank / 250 )
		local textHeight = dxGetFontHeight( 1.6, self.font )
		dxDrawText( math.floor( self.rank - level*250 ) .. " / 250" , x, y - textHeight, x + width, y, tocolor( 208, 211, 216 ), 1, self.font, "center", "center" )
		dxDrawRectangle( x, y, width, height, tocolor( 208, 211, 216, 100 ) )

		if self.endRank then
			local startLevel = math.floor( self.startRank / 250 )
			local relativeRank = math.max( self.startRank - startLevel*250, 0 ) / 250

			local nextLevel = math.floor( self.endRank / 250 )
			local relativeNextRank = math.max( self.endRank - nextLevel*250, 0 ) / 250
			if nextLevel > startLevel then
				relativeNextRank = 1
			end

			local progress = ( now - self.rankIncrementTime ) / 3000
			local value = math.interpolate( relativeRank, relativeNextRank, math.min( progress, 1 ) )
			
			dxDrawRectangle( x, y, width * relativeNextRank, height, tocolor( 19, 36, 66, 160 ) )
			dxDrawRectangle( x, y, width * value, height, tocolor( 40, 109, 237, 160 ) )

			if progress >= 1 then
				self.rank = self.endRank
				self.startRank = nil
				self.endRank = nil
				self.rankIncrementTime = nil
			end
		else
			local value = math.max( self.rank - level*250, 0 ) / 250
			dxDrawRectangle( x, y, width * value, height, tocolor( 19, 36, 66, 160 ) )
			dxDrawRectangle( x, y, width * value, height, tocolor( 40, 109, 237, 160 ) )
		end
		
		if now - self.rankShowTime >= 10000 then
			self.rankShowTime = nil
		end
    end    
end

function xrRankbar:update()
	
end

function xrRankbar:promote( delta )
    if not self.initialized or delta <= 0 then
        return
    end

    self.startRank = self.rank
    self.endRank = math.clamp( 0, 999, self.rank + delta )
    self.rankIncrementTime = getTickCount()
    self.rankShowTime = getTickCount()
    self.rank = math.clamp( 0, 999, self.rank + delta )

    local level = math.floor( self.rank / 250 )
    local nextLevel = math.floor( self.endRank / 250 )
    if nextLevel > level then

    end
end