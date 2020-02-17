local sw, sh = guiGetScreenSize ( )

xrHitMark = {
	
}

local function _onPlayerHit( hitType, power, bodypart, attacker )
	if isElement( attacker ) then
		xrHitMark:addMark( attacker.position )
	end
end
function xrHitMark:setup()
    if self.initialized then
        return false
    end

	self.marks = {}
	self.tex = dxCreateTexture( "textures/ui_hud_hit_mark.dds" )
	self.markSize = math.min( sw, sh ) * 0.7
	self.initialized = true
	
	addEvent( EClientEvents.onClientPlayerHit, true )
	addEventHandler( EClientEvents.onClientPlayerHit, localPlayer, _onPlayerHit, false )

    return true
end

function xrHitMark:destroy()
    if not self.initialized then
        return
	end
	
	destroyElement( self.tex )

	removeEventHandler( EClientEvents.onClientPlayerHit, localPlayer, _onPlayerHit )

    self.initialized = nil
end

function xrHitMark:addMark( point )
	local mark = {
		point = point,
		time = getTickCount()
	}

	table.insert( self.marks, mark )
end

function xrHitMark:draw()
    if not self.initialized then
        return
    end

	local now = getTickCount()

	local marks = self.marks
	local size = self.markSize
	local halfMarkSize = size / 2
	local halfScreenWidth = sw / 2
	local halfScreenHeight = sh / 2
	
	local camMatrix = Camera:getMatrix()
	local camMatrixInv = camMatrix:inverse()

	for i = #marks, 1, -1 do
		local mark = marks[ i ]

		local t = ( now - mark.time ) / 10000
		if t <= 1 then
			local camSpacePos = camMatrixInv:transformPosition( mark.point )
			local angle = 90 - math.deg( math.atan2( camSpacePos:getZ(), camSpacePos:getX() ) )
			local alpha = math.pow( 20 * math.pow( t, 3 ) + 1, -2 )

			dxDrawImage( 
				halfScreenWidth - halfMarkSize, halfScreenHeight - halfMarkSize, 
				size, size,
				self.tex,
				angle, 0, 0, 
				tocolor( 255, 255, 255, alpha * 255 ) 
			)
		else
			table.remove( marks, i )
		end
	end
end

function xrHitMark:update()

end