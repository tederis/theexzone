local sw, sh = guiGetScreenSize ( )

xrMain = {
	isEnabled = false
}

function xrMain:init()
	self.shader = dxCreateShader( "shader.fx" )

	self.tex0 = dxCreateTexture( "textures/detector.png" )
	self.tex1 = dxCreateTexture( "textures/detector_light.png" )
	dxSetShaderValue( self.shader, "Tex0", self.tex0 )
	dxSetShaderValue( self.shader, "Tex1", self.tex1 )

	addEventHandler( "onClientRender", root, xrMain.onRender, false )
end

startTime = getTickCount()
freq = 2
function xrMain.onRender()
	local size = sh * 0.7

	local x = sw - size
	local y = sh - size

	local t = ( getTickCount() - startTime ) / 1000
	local value = math.abs( math.sin( freq * math.pi * t ) )
	dxSetShaderValue( xrMain.shader, "BlendValue", value )

	local progress = math.min( t / 1, 1 )
	y = math.interpolate( sh + size, y, progress )

	dxSetShaderTransform( xrMain.shader, 0, math.interpolate( 160, -10, progress ), 0 )

	dxDrawImage( x, y, size, size, xrMain.shader )
end

addCommandHandler("freq",
	function( _, val)
		freq = tonumber(val)
	end
)

--[[
	Init
]]
--addEventHandler( "onClientCoreStarted", root,
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
		xrIncludeModule( "global.lua" )

		xrMain:init()
    end
)