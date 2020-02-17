local sw, sh = guiGetScreenSize ( )

local xrPackageShaders = { }
local xrPackageTextures = { }
xrShaders = { }

local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3
local ENV_SUNDIR = 4

local LIGHT_DISTANCE_SQR = 80*80

local xrShadowFlags = { 0x0001, 0x0002, 0x0004, 0x0008, 0x0010, 0x0020 }

local g_TreeLODRefs = 0
--[[
	Разбирает флаг освещения на список лайтмапов
]]
function extractLightmaps ( flagsStr )
	local lmaps = { }
	for i = 1, 6 do
		if bitAnd ( flagsStr, xrShadowFlags [ i ] ) > 0 then
			table.insert ( lmaps, i )
		end
	end
	
	return lmaps
end

function getElementRoot ( element )
	local parent = getElementParent ( element )
	repeat
		parent = getElementParent ( parent )
	until parent ~= false
	return parent
end

function findOrCreateTexture ( texIndex, pkgName )
	local textures = xrPackageTextures [ pkgName ]
	if textures then
		local texture = textures [ texIndex ]
		if texture then
			texture.refs = texture.refs + 1
		else
			texture = { 
				refs = 1, 
				[ 1 ] = dxCreateTexture ( ":" .. pkgName .. "/maps/lmap_" .. texIndex .. "_2.dds", "dxt5" ) 
			}
			textures [ texIndex ] = texture
		end
		return texture [ 1 ]
	else
		local texture = dxCreateTexture ( ":" .. pkgName .. "/maps/lmap_" .. texIndex .. "_2.dds", "dxt5" )
		xrPackageTextures [ pkgName ] = {
			[ texIndex ] = { refs = 1, texture }
		}
		return texture
	end
end

function unlinkTexture ( texIndex, pkgName )
	local textures = xrPackageTextures [ pkgName ]
	if textures then
		local texture = textures [ texIndex ]
		if texture then
			texture.refs = texture.refs - 1
			if texture.refs <= 0 then
				outputDebugString ( "    Destroyed texture lmap_" .. texIndex )

				destroyElement ( texture [ 1 ] )
				textures [ texIndex ] = nil
			end
		end
	end
end

function createTypedShader ( flagsStr, pkgName )
	local shader = dxCreateShader ( "shaders/default.fx", 0, 0, false, "object" )

	local lmaps = extractLightmaps ( flagsStr )
	for _, lmapIndex in ipairs ( lmaps ) do
		local texture = findOrCreateTexture ( lmapIndex, pkgName )
		dxSetShaderValue ( shader, "TexHemi" .. lmapIndex, texture )
	end
	
	return shader
end

function unlinkTypedShader ( flagsStr, pkgName )
	local lmaps = extractLightmaps ( flagsStr )
	for _, lmapIndex in ipairs ( lmaps ) do
		unlinkTexture ( lmapIndex, pkgName )
	end
end

--[[
	xrLightManager
]]
xrLightManager = {
	spotLights = { },
	pointLights = { },

	shaders = { }
}

local lightRotMatrix = Matrix( Vector3( 0, 0.2, 0.018 ), Vector3( -30, 0, 0 ) )
local playerLights = {

}

function _onPreRender()
	local mat = Matrix()

	for player, light in pairs( playerLights ) do
		if isElement( player ) then
			local v0 = player:getBonePosition( 6 )
			local v1 = player:getBonePosition( 7 )
			local v2 = player:getBonePosition( 8 )
			
			local v02 = v0 - v2
			local v12 = v1 - v2

			local forward = v02:cross( v12 )
			forward:normalize()
			local up = v02
			up:normalize()
			local right = forward:cross( up )
			right:normalize()		
			
			mat:setPosition( v0 )
			mat:setRight( right )
			mat:setForward( forward )
			mat:setUp( up )

			mat = lightRotMatrix * mat
			local pos = mat:getPosition()
			local dir = mat:getForward()

			light:setPosition( pos:getX(), pos:getY(), pos:getZ() )
			light:setDirection( dir:getX(), dir:getY(), dir:getZ() )
		end
	end

	local ambr, ambg, ambb = exports.sp_pipeline:getEnvValue ( ENV_AMBIENT )
	local hemir, hemig, hemib, hemia = exports.sp_pipeline:getEnvValue ( ENV_HEMI )
	local sunr, sung, sunb = exports.sp_pipeline:getEnvValue ( ENV_SUNCOLOR )
	local sunx, suny, sunz = exports.sp_pipeline:getEnvValue ( ENV_SUNDIR )
	
	for _, shader in pairs ( xrShaders ) do
		dxSetShaderValue ( shader, "L_ambient", ambr * 1.1, ambg * 1.1, ambb * 1.1 )
		dxSetShaderValue ( shader, "L_hemi_color", hemir * 1.2, hemig * 1.2, hemib * 1.2, hemia * 1.21 )
		dxSetShaderValue ( shader, "L_sun_color", sunr*0.65, sung*0.5, sunb*0.5 )
		dxSetShaderValue ( shader, "L_sun_dir_w", sunx, suny, sunz )
	end		

	xrLightManager:render()	
end

local function _onTimer()
	local function testPlayer( player )
		if getElementData( player, "lstate", false ) then
			local cx, cy = getCameraMatrix()
			local px, py = getElementPosition( player )
			local distSqr = ( px - cx )^2 + ( py - cy )^2
			if distSqr <= LIGHT_DISTANCE_SQR then
				return true
			end
		end

		return false
	end

	for _, player in ipairs( getElementsByType( "player", root, true ) ) do
		local light = playerLights[ player ]
		local result = testPlayer( player )

		if light ~= nil and not result then
			xrLightManager:removeLight( light )
			playerLights[ player ] = nil
		elseif light == nil and result then
			local x, y, z = getElementPosition( player )
			local light = xrLightManager:createSpotLight( x, y, z, 0, 1, 0, false )
			playerLights[ player ] = light
		end
	end

	xrLightManager:update()
end

local function onPlayerLeaveLevel()
	xrLightManager:clearAllLights()
end

function xrLightManager:init( )
	self.streamer = xrStreamer_new( 60, 1 )
	self.lights = xrMakeIDTable()

	self.coneShader = dxCreateShader ( "shaders/shader_conetransform.fx" )
	self.coneTex = dxCreateTexture ( "textures/lights_cone2.dds" )
	dxSetShaderValue( self.coneShader, "Tex", self.coneTex )	
	
	addEventHandler( "onClientPreRender", root, _onPreRender, false )
	self.timer = setTimer( _onTimer, 100, 0 )
	addEvent( EClientEvents.onClientPlayerLeaveLevel, true )
	addEventHandler( EClientEvents.onClientPlayerLeaveLevel, localPlayer, onPlayerLeaveLevel, false )
end

function xrLightManager:insertShader( shader )
	table.insert ( self.shaders, shader )
end

function xrLightManager:removeShader( shader )
	table.removeValue( self.shaders, shader )
end

function xrLightManager:streamInLight( light )
	if not light.streamedIn or not light.enabled then
		return
	end

	if light.type == 1 then
		table.insertIfNotExists( self.spotLights, light )
	elseif light.type == 2 then
		table.insertIfNotExists( self.pointLights, light )
	end
end

function xrLightManager:streamOutLight( light )
	if light.streamedIn and light.enabled then
		return
	end

	if light.type == 1 then
		table.removeValue( self.spotLights, light )
	elseif light.type == 2 then
		table.removeValue( self.pointLights, light )
	end
end

function xrLightManager:createSpotLight( x, y, z, lx, ly, lz, streamable )
	streamable = streamable == nil or streamable == true

	local spot = xrSpotLight_new( x, y, z, lx, ly, lz )
	spot.streamable = streamable
	spot.id = self.lights:push( spot )

	if streamable then
		self.streamer:pushItem( spot, x, y, z )
	else
		spot.streamedIn = true
		table.insert( self.spotLights, spot )
	end
	
	return spot, spot.id
end

function xrLightManager:createPointLight( x, y, z, radius, time, streamable )
	streamable = streamable == nil or streamable == true

	local point = xrPointLight_new( x, y, z, radius )
	if type( time ) == "number" and time > 0 then
		point.endTime = getTickCount() + time*1000
	end
	point.streamable = streamable
	point.id = self.lights:push( point )	

	if streamable then
		self.streamer:pushItem( point, x, y, z )
	else
		point.streamedIn = true
		table.insert( self.pointLights, point )
	end
	
	return point, point.id
end

function xrLightManager:removeLight( light )
	if type( light ) == "number" then
		light = self.lights[ light ]
	end

	if light then
		if light.streamable then
			--streamer:removeItem через callback'и удалит свет из таблиц spotLights и pointLights
			self.streamer:removeItem( light )
		else
			-- В противном случае удаляем напрямую
			if light.type == 1 then
				table.removeValue( self.spotLights, light )
			elseif light.type == 2 then
				table.removeValue( self.pointLights, light )
			end
		end

		self.lights[ light.id ] = nil
	end
end

function xrLightManager:clearAllLights( lightType )
	local streamer = self.streamer
	local lights = self.lights

	for id, light in pairs( lights ) do
		if not lightType or light.type == lightType then
			self:removeLight( light )
		end
	end
end

function xrLightManager:update()
	local now = getTickCount()

	for _, light in ipairs( self.pointLights ) do
		if light.endTime and now > light.endTime then
			xrLightManager:removeLight( light )
			break
		end
	end

	local x, y, z = getElementPosition( localPlayer )
	self.streamer:update( x, y, z )
	xrLightManager:sort( x, y, z )
end

function xrLightManager:render( )
	local self = xrLightManager
	
	local lights = self.spotLights
	local lightsP = self.pointLights
	
	local spotPosition = { }
	local spotDirection = { }

	for i = 1, 5 do
		local spotLight = lights[ i ]
		if spotLight then
			local num = #spotPosition
			spotPosition [ num + 1 ] = spotLight.x
			spotPosition [ num + 2 ] = spotLight.y
			spotPosition [ num + 3 ] = spotLight.z

			num = #spotDirection
			spotDirection [ num + 1 ] = spotLight.lx
			spotDirection [ num + 2 ] = spotLight.ly
			spotDirection [ num + 3 ] = spotLight.lz
			
			-- render cone
			dxDrawMaterialLine3D ( 
				spotLight.x, spotLight.y, spotLight.z, 
				spotLight.x + spotLight.lx*4, spotLight.y + spotLight.ly*4, spotLight.z + spotLight.lz*4,
				self.coneShader, 1
			)
		else
			local num = #spotPosition
			spotPosition [ num + 1 ] = 0
			spotPosition [ num + 2 ] = 0
			spotPosition [ num + 3 ] = 0

			num = #spotDirection
			spotDirection [ num + 1 ] = 0
			spotDirection [ num + 2 ] = 0
			spotDirection [ num + 3 ] = -1
		end
	end
	
	local pointPosition = { }
	local pointColor = { }
	local pointRadius = { }
	
	for i = 1, 5 do
		local pointLight = lightsP[ i ]
		if pointLight then
			local num = #pointPosition
			pointPosition [ num + 1 ] = pointLight.x
			pointPosition [ num + 2 ] = pointLight.y
			pointPosition [ num + 3 ] = pointLight.z
			
			num = #pointColor
			pointColor [ num + 1 ] = pointLight.r / 255
			pointColor [ num + 2 ] = pointLight.g / 255
			pointColor [ num + 3 ] = pointLight.b / 255

			num = #pointRadius
			pointRadius [ num + 1 ] = pointLight.radius
		else
			local num = #pointPosition
			pointPosition [ num + 1 ] = 0
			pointPosition [ num + 2 ] = 0
			pointPosition [ num + 3 ] = 0
			
			num = #pointColor
			pointColor [ num + 1 ] = 0
			pointColor [ num + 2 ] = 0
			pointColor [ num + 3 ] = 0

			num = #pointRadius
			pointRadius [ num + 1 ] = 1
		end
	end
	
	for _, shader in ipairs ( self.shaders ) do
		dxSetShaderValue( shader, "SpotLightPosition", spotPosition )
		dxSetShaderValue( shader, "SpotLightDirection", spotDirection )		
		dxSetShaderValue( shader, "PointLightPosition", pointPosition )
		dxSetShaderValue( shader, "PointLightColor", pointColor )
		dxSetShaderValue( shader, "PointLightRadius", pointRadius )
	end
end

function xrLightManager:sort ( cx, cy, cz )
	local self = xrLightManager
	local _dist3d = getDistanceBetweenPoints3D

	local tbl = self.spotLights
	local temp
	for i = 1, #tbl - 1 do
		for j = i, #tbl do
			local x, y, z = tbl [ i ].x, tbl [ i ].y, tbl [ i ].z
			local x2, y2, z2 = tbl [ j ].x, tbl [ j ].y, tbl [ j ].z
				
			if _dist3d ( cx, cy, cz, x, y, z ) > _dist3d ( cx, cy, cz, x2, y2, z2 ) then
				temp = tbl [ i ]
				tbl [ i ] = tbl [ j ]
				tbl [ j ] = temp
			end
		end
	end

	tbl = self.pointLights
	temp = nil
	for i = 1, #tbl - 1 do
		for j = i, #tbl do
			local x, y, z = tbl [ i ].x, tbl [ i ].y, tbl [ i ].z
			local x2, y2, z2 = tbl [ j ].x, tbl [ j ].y, tbl [ j ].z
				
			if _dist3d ( cx, cy, cz, x, y, z ) > _dist3d ( cx, cy, cz, x2, y2, z2 ) then
				temp = tbl [ i ]
				tbl [ i ] = tbl [ j ]
				tbl [ j ] = temp
			end
		end
	end
end

--[[
	xrLight
]]
xrLight = {

}
xrLightMT = {
	__index = xrLight
}

function xrLight:setPosition( x, y, z )
	self.x = x
	self.y = y
	self.z = z

	if self.streamable then
		xrLightManager.streamer:updateItem( self, x, y, z )
	end
end

function xrLight:setColor ( r, g, b )
	self.r = r
	self.g = g
	self.b = b
end

function xrLight:onStreamedIn()
	xrLightManager:streamInLight( self )
end

function xrLight:onStreamedOut()
	xrLightManager:streamOutLight( self )
end

function xrLight:setEnabled( enabled )
	if self.enabled ~= enabled then
		self.enabled = enabled

		if enabled then
			xrLightManager:streamInLight( self )
		else
			xrLightManager:streamOutLight( self )
		end		
	end
end

--[[
	xrSpotLight
]]
xrSpotLight = { 

}
xrSpotLightMT = {
	__index = xrSpotLight
}
setmetatable( xrSpotLight, xrLightMT )

function xrSpotLight_new( x, y, z, lx, ly, lz )
	local spot = {
		x = x, y = y, z = z,
		lx = lx, ly = ly, lz = lz,
		type = 1,
		enabled = true
	}
	
	return setmetatable ( spot, xrSpotLightMT )
end

function xrSpotLight:setDirection ( x, y, z )
	self.lx = x
	self.ly = y
	self.lz = z
end

--[[
	xrPointLight
]]
xrPointLight = { 

}
xrPointLightMT = {
	__index = xrPointLight
}
setmetatable( xrPointLight, xrLightMT )

function xrPointLight_new ( x, y, z, radius )
	local point = {
		x = x, y = y, z = z,
		r = 0, g = 0, b = 0,
		radius = tonumber( radius ) or 1,
		type = 2,
		enabled = true
	}
	
	return setmetatable ( point, xrPointLightMT )
end

--[[
	EXPORTS
]]
function xrCreatePointLight( x, y, z, r, g, b, radius, time, streamable )
	local point, id = xrLightManager:createPointLight( x, y, z, radius, time, streamable )
	point:setColor( r, g, b )

	return id
end

function xrCreateSpotLight( x, y, z, lx, ly, lz, streamable )
	local spot, id = xrLightManager:createSpotLight( x, y, z, lx, ly, lz, streamable )

	return id
end

function xrLightDestroy( id )
	if not id then
		return
	end

	local light = xrLightManager.lights[ id ]
	if light then
		xrLightManager:removeLight( light )
	end
end

function xrLightExists( id )
	if id then
		return xrLightManager.lights[ id ] ~= nil
	end
	return false
end

function xrClearAllLights( lightType )
	xrLightManager:clearAllLights( lightType )
end

function xrLightInsertShader( shader )
	xrLightManager:insertShader( shader )
	xrShaders[ "weapon" ] = shader
end