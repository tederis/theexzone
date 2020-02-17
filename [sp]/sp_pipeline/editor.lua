local xrEditor = {

}
local controls = {

}
local xrCurrentCycleName
local lastEnv
local lastY = 30

local wndWidth = 500
local wndHeight = 600


function createVector3Edit( name, value )
	local control = {}

	control.lbl = guiCreateLabel( 10, lastY, wndWidth, 25, name, false, xrEditor.wnd )

	local fieldWidth = ( wndWidth - 20 ) / 3
	control.xedit = guiCreateEdit( 10, lastY + 30, fieldWidth, 60 - 30, value.x, false, xrEditor.wnd )
	control.yedit = guiCreateEdit( 10 + fieldWidth, lastY + 30, fieldWidth, 60 - 30, value.y, false, xrEditor.wnd )
	control.zedit = guiCreateEdit( 10 + fieldWidth + fieldWidth, lastY + 30, fieldWidth, 60 - 30, value.z, false, xrEditor.wnd )

	lastY = lastY + 60 + 10

	control.set = function( self, value )
		guiSetText( self.xedit, value.x )
		guiSetText( self.yedit, value.y )
		guiSetText( self.zedit, value.z )
	end

	control.get = function( self )
		local xpos = tonumber( guiGetText( self.xedit ) )
		local ypos = tonumber( guiGetText( self.yedit ) )
		local zpos = tonumber( guiGetText( self.zedit ) )

		if xpos and ypos and zpos then
			return Vector3( xpos, ypos, zpos )
		end
	end

	controls[ name ] = control
end

function createNumberEdit( name, value )
	local control = {}

	control.lbl = guiCreateLabel( 10, lastY, wndWidth, 25, name, false, xrEditor.wnd )
	control.edit = guiCreateEdit( 10, lastY + 30, wndWidth - 20, 60 - 30, value, false, xrEditor.wnd )

	lastY = lastY + 60 + 10

	control.set = function( self, value )
		guiSetText( self.edit, value )
	end

	control.get = function( self )
		local val = tonumber( guiGetText( self.edit ) )

		return val
	end

	controls[ name ] = control
end

function xrDestroyEditor()
	destroyElement( xrEditor.timeScroll )
	destroyElement( xrEditor.wnd )

	freezeValue = nil

	showCursor( false )
end

function xrCreateEditor()
	local sw, sh = guiGetScreenSize()

	lastEnv = nil
	lastY = 30

	xrEditor.timeScroll = guiCreateScrollBar( 50, sh - 100, sw - 100, 50, true, false )
	addEventHandler( "onClientGUIScroll", xrEditor.timeScroll,
		function()
			local value = guiScrollBarGetScrollPosition( source ) / 100	
			local hour = math.floor( value * 24 )			
			local minutes = math.floor( ( value * 24 - hour ) * 60 )
			if hour > 23 then
				hour = 0
			end
			if minutes > 59 then
				minutes = 0
			end

			outputDebugString( hour .. ":" .. minutes )
			setTime( hour, minutes )

			-- Форсируем обновление
			--xrEnvironment.setGameTime( freezeValue )
			--xrEnvironment.update ( )

			if lastEnv ~= xrEnvironment.envStart then
				xrEditorSetEnv( xrEnvironment.envStart )
				lastEnv = xrEnvironment.envStart
			end
		end
	, false )

	xrEditor.wnd = guiCreateWindow( sw / 2 - wndWidth / 2, sh / 2 - wndHeight / 2, wndWidth, wndHeight, "Editor", false )

	createVector3Edit( "ambient", Vector3(0, 0, 0) )
	createVector3Edit( "hemiColor", Vector3(0, 0, 0) )
	createNumberEdit( "skyGradient", 0 )
	createNumberEdit( "gtaTime", 0 )
	createNumberEdit( "fogDistance", 0 )

	xrEditor.applyBtn = guiCreateButton( 10, lastY, wndWidth - 20, 60, "Apply", false, xrEditor.wnd )
	lastY = lastY + 60
	addEventHandler( "onClientGUIClick", xrEditor.applyBtn,
		function()
			if xrEnvironment.envStart then
				xrEditorApplyEnv( xrEnvironment.envStart )
			end
		end
	, false )

	xrEditor.saveBtn = guiCreateButton( 10, lastY, wndWidth - 20, 60, "Save", false, xrEditor.wnd )
	addEventHandler( "onClientGUIClick", xrEditor.saveBtn,
		function()
			xrEnvironment.save( xrEnvironment.currentWeather.name )
		end
	, false )

	if xrEnvironment.envStart then
		xrEditorSetEnv( xrEnvironment.envStart )	
		lastEnv = xrEnvironment.envStart
	end

	showCursor( true )
end

function xrEditorApplyEnv( env )
	local control = controls.ambient
	local value = control:get()
	if value then
		env.ambient = value
	end

	control = controls.hemiColor
	local value = control:get()
	if value then
		env.hemiColor = Vector4( value:getX(), value:getY(), value:getZ(), 1 )
	end

	control = controls.skyGradient
	local value = control:get()
	if value then
		env.skyGradient = value
	end

	control = controls.gtaTime
	local value = control:get()
	if value then
		env.gtaTime = value
	end

	control = controls.fogDistance
	local value = control:get()
	if value then
		env.fogDistance = value
	end
end

function xrEditorSetEnv( env )	
	local control = controls.ambient
	control:set( env.ambient )

	control = controls.hemiColor
	control:set( env.hemiColor )

	control = controls.skyGradient
	control:set( env.skyGradient )

	control = controls.gtaTime
	control:set( env.gtaTime )

	control = controls.fogDistance
	control:set( env.fogDistance )
end

addCommandHandler( "pipeedit",
	function( _, weatherName )
		if xrCurrentCycleName then
			xrDestroyEditor()

			xrCurrentCycleName = nil

			return
		end

		local weather = xrEnvironment.weatherCycles[ weatherName ]
		if weather then
			xrEnvironment.currentWeather = weather
			xrCurrentCycleName = weatherName

			xrCreateEditor()
		else
			showCursor( false )
			outputDebugString ( "Погода с именем " .. weatherName .. " не была найдена", 2 )
		end
	end
)