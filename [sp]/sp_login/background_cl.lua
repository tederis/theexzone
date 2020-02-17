local sw, sh = guiGetScreenSize()

xrBackground = {
    enabled = false
}

function xrBackground:startRandomThunder()
	local rand = math.random ( 1, 3 )
	local sound = playSound ( "sounds/new_thunder" .. rand .. ".ogg", false )
	local soundLen = getSoundLength ( sound ) * 1000
	xrBackground.timer = setTimer ( xrBackground.startRandomThunder, math.random ( soundLen * 2, soundLen * 5 ), 1 )
end

function xrBackground:new()
    if self.enabled then
        return
    end

	self.backTexture2 = dxCreateTexture ( "textures/ui_actor_staff_background.dds" )
	self.backTexture = dxCreateTexture ( "textures/ui_ingame2_back_01.dds" )
	self.rainTexture = dxCreateTexture ( "textures/raintexture.png" )
	self.backShader = dxCreateShader ( "shader.fx" )
	dxSetShaderValue ( self.backShader, "Tex0", self.backTexture2 )
	dxSetShaderValue ( self.backShader, "Tex1", self.backTexture )
	dxSetShaderValue ( self.backShader, "Tex2", self.rainTexture )
	
	self.rainSnd = playSound ( "sounds/new_rain1.ogg", true )
	self.dropsSnd = playSound ( "sounds/waterdrops2.ogg", true )
	setSoundVolume ( self.dropsSnd, 0.25 )
	self:startRandomThunder()

    self.enabled = true
end

function xrBackground:destroy()
    if not self.enabled then
        return
    end

	destroyElement( self.backTexture2 )
	destroyElement( self.backTexture )
	destroyElement( self.rainTexture )
	destroyElement( self.backShader )

	if isTimer( self.timer ) then
		killTimer( self.timer )
	end

	if isElement( self.rainSnd ) then
		stopSound( self.rainSnd )
	end
	if isElement( self.dropsSnd ) then
		stopSound( self.dropsSnd )
    end
    
    self.enabled = false
end

function xrBackground:render()
    if self.enabled then
        dxDrawImage( 0, 0, sw, sh, self.backShader, 0, 0, 0, tocolor( 255, 255, 255, 255 ) )
    end
end