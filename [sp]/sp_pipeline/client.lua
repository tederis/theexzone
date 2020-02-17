local g_Obj
local g_Shader

DEBUG = true
DAY_LENGTH = 86400

--[[
	xrEnvironment
]]
xrEnvironment = { 
	weatherCycles = { } -- Временные циклы для каждой погоды
}

function xrEnvironment.new( )
	xrEnvironment.currentEnv = xrEnvDescriptor.new ( ) -- Миксер
	
	local txd = engineLoadTXD ( "models/skybox.txd" )
	local col = engineLoadCOL ( "models/skybox.col" )
	local dff = engineLoadDFF ( "models/skybox.dff", 0 )
		
	engineImportTXD ( txd, 3001 )
	engineReplaceCOL ( col, 3001 )
	engineReplaceModel ( dff, 3001, true )
	
	local x, y, z = getCameraMatrix ( )
	xrEnvironment.skyObj = createObject ( 3001, x, y, z )
	setElementDoubleSided ( xrEnvironment.skyObj, true )
	setObjectScale ( xrEnvironment.skyObj, 299 )

	xrEnvironment.skyShader = dxCreateShader ( "shaders/default.fx" )
		
	engineApplyShaderToWorldTexture ( xrEnvironment.skyShader, "_Textur2_", xrEnvironment.skyObj )
end

function xrEnvironment.isTimeWithinRange( t, t0, t1 )
	if t1 > t0 then
		if t >= t0 and t < t1 then
			return true
		end
	else
		if ( t >= 0 and t < t1 ) or ( t < DAY_LENGTH and t >= t0 ) then
			return true
		end
	end

	return false
end

function xrEnvironment.timeDiff( prev, cur )
	if prev > cur then 
		return ( DAY_LENGTH - prev ) + cur
	else
		return	cur - prev
	end
end

function xrEnvironment.timeWeight( val, min_t, max_t )
	local weight = 0
	local length = xrEnvironment.timeDiff( min_t, max_t )
	if length > 0 then
		if min_t > max_t then
			if val >= min_t or val <= max_t then weight = xrEnvironment.timeDiff( min_t, val ) / length end
		else
			if val >= min_t and val <= max_t then weight = xrEnvironment.timeDiff( min_t, val ) / length end
		end
		weight = math.clamp ( 0, 1, weight )
	end
	return weight
end

function xrEnvironment.load( weatherName )
	local filepath = ":xrcore/config/environment/" .. weatherName .. ".ltx"
	local settings = xrSettings.new()
	
	local file = fileOpen ( filepath, true )
	if file then
		settings:load ( file, filepath )
		fileClose ( file )	
	else
		outputDebugString( "Ошибка загрузки погоды. Погоды " .. tostring( weatherName ) .. " не существует", 1 )
		return	
	end

	local cycles = xrEnvironment.weatherCycles
	cycles[ weatherName ] = {
		name = weatherName
	}

	for _, section in pairs( settings.sections ) do
		local timeStr = section._name
		local hours = tonumber( gettok( timeStr, 1, ':' ) )
		local mins = tonumber( gettok( timeStr, 2, ':' ) )
		local secs = tonumber( gettok( timeStr, 3, ':' ) )

		local time = hours * 3600 + mins * 60 + secs

		local envDesc = xrEnvDescriptor.new()
		envDesc:load( timeStr, section )
		table.insert( cycles[ weatherName ], envDesc )
	end

	local _sortFn = function ( a, b )
		return a.execTimeLoaded < b.execTimeLoaded
	end
	table.sort( cycles[ weatherName ], _sortFn )
end

function xrEnvironment.save( weatherName )
	local cycle = xrEnvironment.weatherCycles[ weatherName ]
	if not cycle then
		outputDebugString( "Такого цикла не существует!", 2 )
		return
	end

	local file = fileCreate( "saved/" .. weatherName .. ".ltx" )
	if file then
		for _, env in ipairs( cycle ) do
			env:save( file )
		end

		fileClose( file )
	else
		outputDebugString( "Ошибка создания файла", 2 )
	end
end

function xrEnvironment.setWeather ( weatherName )
	local weather = xrEnvironment.weatherCycles[ weatherName ]
	if weather then
		xrEnvironment.currentWeather = weather
		outputDebugString ( "Установлена погода " .. weatherName )
	else
		outputDebugString ( "Погода с именем " .. weatherName .. " не была найдена", 2 )
	end
end

local function getTimeStr( num )
	local hours = math.floor( num / 3600 )
	local mins = math.floor( ( num - hours*3600 ) / 60 )
	local secs = math.floor( num - hours*3600 - mins*60 )

	return hours .. ":" .. mins .. ":" .. secs
end

function xrEnvironment.setWeatherEffect( effectName, forceTime, blendTime, originTime )
	if type( originTime ) ~= "number" then
		originTime = xrEnvironment.gameTime
	end

	if not effectName then
		if xrEnvironment.currentWeather then
			xrEnvironment.currentWeather.effect = nil
		end

		outputDebugString( "Погодный эффект сброшен" )

		return
	end

	local function proceedTime( t )
		if t < 0 then
			return DAY_LENGTH - t
		end

		if t > DAY_LENGTH then
			return t - DAY_LENGTH
		end

		return t
	end

	local effect = xrEnvironment.weatherCycles[ effectName ]
	if effect then
		if xrEnvironment.currentWeather then
			local effectEntry = table.copy( effect, true )

			do
				local forceEndTime = proceedTime( originTime + forceTime )
				local beginTime = proceedTime( forceEndTime + blendTime )
				local effectLength = effectEntry[ #effectEntry ].execTime - effectEntry[ 1 ].execTime
				local endTime = proceedTime( beginTime + effectLength + blendTime )

				-- Проматываем время эффекта к началу выброса
				for _, env in ipairs( effectEntry ) do
					env.execTime = proceedTime( beginTime + env.execTime )
				end

				-- Вставляем текущий кадр в начало
				local startEnv = table.copy( xrEnvironment.envStart, true )
				table.insert( effectEntry, 1, startEnv )

				-- Укорачиваем время сл. кадра и вставляем следом
				local endEnv = table.copy( xrEnvironment.envEnd, true )
				endEnv.execTime = forceEndTime
				table.insert( effectEntry, 2, endEnv )
				
				local firstEnv, lastEnv = xrEnvironment.findEnvs( xrEnvironment.currentWeather, endTime )

				-- Подставляем предпоследний кадр для плавной смены
				local endEnv = table.copy( firstEnv, true )
				endEnv.execTime = endTime
				table.insert( effectEntry, endEnv )

				-- И финальный кадр, которым эффект завершится
				table.insert( effectEntry, lastEnv )
			end

			xrEnvironment.currentWeather.effect = effectEntry

			outputDebugString ( "Установлен погодный эффект " .. effectName )
		end		
	else
		outputDebugString ( "Погода с именем " .. weatherName .. " не была найдена", 2 )
	end
end

function xrEnvironment.setGameTime ( time )
	xrEnvironment.gameTime = time
end

function xrEnvironment.findEnvs( weather, gt )
	for i = 1, #weather do
		local env = weather[ i ]
		local nextEnv = weather[ i + 1 ] or weather[ 1 ]

		if xrEnvironment.isTimeWithinRange( gt, env.execTime, nextEnv.execTime ) then
			return env, nextEnv
		end
	end

	return false
end

function xrEnvironment.selectEnvs( gt )
	local weather = xrEnvironment.currentWeather	
	if weather.effect then
		local firstEffectEnv = weather.effect[ 1 ]
		local lastEffectEnv = weather.effect[ #weather.effect ]

		if xrEnvironment.isTimeWithinRange( gt, firstEffectEnv.execTime, lastEffectEnv.execTime ) then
			weather = weather.effect
		end
	end	

	local firstEnv, lastEnv = xrEnvironment.findEnvs( weather, gt )
	if firstEnv then
		xrEnvironment.envStart = firstEnv
		xrEnvironment.envEnd = lastEnv
	end
end

local rot = 0
function xrEnvironment.update ( )
	setSunColor ( 0, 0, 0, 0, 0, 0 )
	setMoonSize ( 0 )
	setHeatHaze ( 0 )
	setSunSize ( 0 )
	setCloudsEnabled ( false )
	setBirdsEnabled ( false )

	-- Идеальные параметры
	setFarClipDistance( 800 )	
	
	
	local x, y, z = getCameraMatrix ( )
	setElementPosition ( xrEnvironment.skyObj, x, y, z, false )

	xrEnvironment.selectEnvs ( xrEnvironment.gameTime )
	
	local weight = xrEnvironment.timeWeight ( xrEnvironment.gameTime, xrEnvironment.envStart.execTime, xrEnvironment.envEnd.execTime )
	
	xrEnvironment.currentEnv:lerp ( xrEnvironment.envStart, xrEnvironment.envEnd, weight )
	
	if xrEnvironment.envStart.skyTexture then
		dxSetShaderValue ( xrEnvironment.skyShader, "tSkyTex0", xrEnvironment.envStart.skyTexture )
	end
	if xrEnvironment.envEnd.skyTexture then
		dxSetShaderValue ( xrEnvironment.skyShader, "tSkyTex1", xrEnvironment.envEnd.skyTexture )
	end
	dxSetShaderValue ( xrEnvironment.skyShader, "vecColor", xrEnvironment.currentEnv.skyColor.x, xrEnvironment.currentEnv.skyColor.y, xrEnvironment.currentEnv.skyColor.z )
	dxSetShaderValue ( xrEnvironment.skyShader, "fFactor", weight )
	
	setSkyGradient( xrEnvironment.skyGradient, xrEnvironment.skyGradient, xrEnvironment.skyGradient, xrEnvironment.skyGradient, xrEnvironment.skyGradient, xrEnvironment.skyGradient )
	--dxDrawText( inspect(xrEnvironment.currentEnv.skyColor), 500, 500 )
	--setTime( math.clamp( 0, 23, xrEnvironment.currentEnv.gtaTime ), math.floor( 59 * weight ) )
	setFogDistance( xrEnvironment.currentEnv.fogDistance )
	
	setElementRotation ( xrEnvironment.skyObj, 0, 0, math.deg ( xrEnvironment.currentEnv.skyRotation ) + rot )
	rot = rot + 0.01

	local boltDuration = xrEnvironment.currentEnv.boltDuration * 60
	local boltPeriod = xrEnvironment.currentEnv.boltPeriod * 60
	local bolts = weight < 0.5 and xrEnvironment.envStart.bolts or xrEnvironment.envEnd.bolts
	if bolts and #bolts > 0 then
		if not xrEnvironment.lastBoltTime or  xrEnvironment.timeDiff( xrEnvironment.lastBoltTime, xrEnvironment.gameTime ) >= boltPeriod then
			xrSurge:onBolt( bolts )

			xrEnvironment.lastBoltTime = xrEnvironment.gameTime
		end
	end

	--dxDrawText( xrEnvironment.envStart.execTime .. " - " .. xrEnvironment.envEnd.execTime, 600, 600 )
end

--[[
	xrEnvDescriptor
]]
xrEnvDescriptor = { }
xrEnvDescriptorMT = { __index = xrEnvDescriptor }

function xrEnvDescriptor.new ( )
	local desc = { 
		execTime 			= 0,
		execTimeLoaded 		= 0,
	
		cloudsColor 		= Vector4 ( 1, 1, 1, 1 ),
		skyColor 			= Vector3 ( 1, 1, 1 ),
		skyRotation 		= 0,

		farPlane 			= 400,

		fogColor 			= Vector3 ( 1, 1, 1 ),
		fogDensity 			= 0,
		fogDistance 		= 400,

		rainDensity 		= 0,
		rainColor 			= Vector3 ( 0, 0, 0 ),

		boltPeriod 			= 0,
		boltDuration		= 0,

		windVelocity 		= 0,
		windDirection		= 0,
    
		ambient 			= Vector3 ( 0, 0, 0 ),
		hemiColor 			= Vector4 ( 1, 1, 1, 1 ),
		sunColor 			= Vector3 ( 1, 1, 1 ),
		sunDir				= Vector3 ( 0, -1, 0 ),

		lensFlareId			= -1,
		tbId				= -1,

		gtaTime             = 12,
		skyGradient         = 100
	}
	
	return setmetatable ( desc, xrEnvDescriptorMT )
end

function xrEnvDescriptor:load ( timeStr, section )
	if section == nil then
		outputChatBox(timeStr)
	end

	local tx = gettok ( timeStr, 1, ":" )
	local ty = gettok ( timeStr, 2, ":" )
	local tz = gettok ( timeStr, 3, ":" )
	local time = Vector3 ( tonumber ( tx ), tonumber ( ty ), tonumber ( tz ) )
	if time.x < 0 or time.x >= 24 or time.y < 0 or time.y >= 60 or time.z < 0 or time.z >= 60 then
		outputDebugString ( "Некорректное погодное время: " .. execTime, 1 )
		return
	end
	
	self.gtaTime = tonumber( section.gta_time ) or 12
	self.skyGradient = tonumber( section.gta_sky ) or 100
	self.execTime = time.x*3600 + time.y*60 + time.z
	self.timeStr = timeStr
	self.execTimeLoaded = self.execTime
	self.skyTextureName = section.sky_texture
	self.skyTextureEnvName = self.skyTextureName .. "+small"
	self.cloudsTextureName = section.clouds_texture
	self.cloudsColor = section.clouds_color
	local multiplier = 0
	local wsave = self.cloudsColor.w; self.cloudsColor = self.cloudsColor * ( 0.5 * multiplier ); self.cloudsColor.w = wsave
	self.skyColor = section.sky_color * 3
	if section.sky_rotation ~= nil then
		self.skyRotation = math.rad ( section.sky_rotation )
	else
		self.skyRotation = 0
	end
	self.farPlane = section.far_plane
	self.fogColor = section.fog_color
	self.fogDensity = section.fog_density
	self.fogDistance = section.fog_distance
	self.rainDensity = math.clamp ( 0, 1, section.rain_density )
	self.rainColor = section.rain_color
	self.windVelocity = section.wind_velocity
	self.windDirection = math.rad ( section.wind_direction )
	self.ambient = section.ambient_color
	self.hemiColor = section.hemisphere_color
	self.sunColor = section.sun_color

	self.sun_altitude = section.sun_altitude
	self.sun_longitude = section.sun_longitude

	local sunDir = Vector2( section.sun_longitude, section.sun_altitude )
	setVector3HP( self.sunDir, math.rad ( sunDir.y ), math.rad ( sunDir.x ) )

	if self.sunDir.y >= 0 then
		outputDebugString ( "Некорректное направление солнца", 2 )
	end

	if fileExists( self.skyTextureName .. ".dds" ) then
		self.skyTexture = dxCreateTexture( self.skyTextureName .. ".dds" )
	else
		outputDebugString( "Текстуры " .. self.skyTextureName .. " нет" )
	end	

	if section.thunderbolt_collection then
		self.bolts = {

		}

		local collection = xrSettingsGetSection( section.thunderbolt_collection )

		for _, boltName in ipairs( collection ) do
			local boltSection = xrSettingsGetSection( boltName )
			if boltSection then
				table.insert( self.bolts, 
					{
						anim = boltSection.color_anim,
						sound = boltSection.sound
					} 
				)
			end
		end

		self.boltDuration = tonumber( section.thunderbolt_duration ) or 0
		self.boltPeriod = tonumber( section.thunderbolt_period ) or 0
		self.boltCollectionStr = section.thunderbolt_collection
	end
end

local function writeVector3( file, name, value )
	fileWrite( file, "        " .. name .. " = " .. tostring( value:getX() ) .. ", " ..  tostring( value:getY() ) .. ", " .. tostring( value:getZ() ) .. "\n" )
end

local function writeVector4( file, name, value )
	fileWrite( file, "        " .. name .. " = " .. tostring( value:getX() ) .. ", " ..  tostring( value:getY() ) .. ", " .. tostring( value:getZ() ) .. ", " .. tostring( value:getW() ) .. "\n" )
end

local function writeFloat( file, name, value )
	fileWrite( file, "        " .. name .. " = " .. tostring( value ) .. "\n" )
end

local function writeString( file, name, value )
	fileWrite( file, "        " .. name .. " = " .. value .. "\n" )
end

--[[
        ambient_color                    = 0.020000, 0.020000, 0.020000
        clouds_color                     = 0.000000, 0.000000, 0.000000, 0.000000
        clouds_texture                   = sky\sky_oblaka
        far_plane                        = 350.000000
        fog_color                        = 0.229000, 0.225078, 0.236843
        fog_density                      = 0.900000
        fog_distance                     = 350.000000
        hemisphere_color                 = 0.264765, 0.170647, 0.107902, 1.000000
        rain_color                       = 0.680000, 0.640000, 0.600000
        rain_density                     = 0.000000
        sky_color                        = 0.630001, 0.630001, 0.630001
        sky_rotation                     = 0.000000
        sky_texture                      = sky\sky_18_cube
        sun                              = sun_rise
        sun_altitude                     = -68.999985
        sun_color                        = 0.988235, 0.545098, 0.380392
        sun_longitude                    = -6.000000
        sun_shafts_intensity             = 0.000000
        thunderbolt_collection           =
        thunderbolt_duration             = 0.000000
        thunderbolt_period               = 0.000000
        water_intensity                  = 1.000000
        wind_direction                   = 0.000000
        wind_velocity                    = 0.000000
]]

function xrEnvDescriptor:save( file )
	fileWrite( file, "[" .. self.timeStr .. "]\n" )

	writeFloat( file, "gta_time", self.gtaTime )
	writeFloat( file, "gta_sky", self.skyGradient )
	writeVector3( file, "ambient_color", self.ambient )
	writeVector4( file, "clouds_color", self.cloudsColor )
	writeString( file, "clouds_texture", self.cloudsTextureName )
	writeFloat( file, "far_plane", self.farPlane )
	writeVector3( file, "fog_color", self.fogColor )
	writeFloat( file, "fog_density", self.fogDensity )
	writeFloat( file, "fog_distance", self.fogDistance )
	writeVector4( file, "hemisphere_color", self.hemiColor )
	writeVector3( file, "rain_color", self.rainColor )
	writeFloat( file, "rain_density", self.rainDensity )
	writeVector3( file, "sky_color", self.skyColor )
	writeFloat( file, "sky_rotation", math.deg( self.skyRotation ) )
	writeString( file, "sky_texture", self.skyTextureName )
	writeFloat( file, "sun_altitude", self.sun_altitude )
	writeFloat( file, "sun_longitude", self.sun_longitude )
	writeVector3( file, "sun_color", self.sunColor )
	writeFloat( file, "wind_direction", math.deg( self.windDirection ) )
	writeFloat( file, "wind_velocity", self.windVelocity )
	if self.boltCollectionStr then
		writeString( file, "thunderbolt_collection", self.boltCollectionStr )
		writeFloat( file, "thunderbolt_duration", self.boltDuration )
		writeFloat( file, "thunderbolt_period", self.boltPeriod )
	end


	fileWrite( file, "\n" )
end

function xrEnvDescriptor:lerp ( envA, envB, f )
	local fi = 1 - f

	self.gtaTime = fi*envA.gtaTime + f*envB.gtaTime
	self.skyGradient = fi*envA.skyGradient + f*envB.skyGradient

	self.cloudsColor:lerp ( envA.cloudsColor, envB.cloudsColor, f )
	self.skyRotation = fi*envA.skyRotation + f*envB.skyRotation
	self.farPlane = ( fi*envA.farPlane + f*envB.farPlane + 0 )*2*1
	self.fogColor:lerp ( envA.fogColor, envB.fogColor, f )
	self.fogDensity = (fi*envA.fogDensity + f*envB.fogDensity + 0)*1
	self.fogDistance = fi*envA.fogDistance + f*envB.fogDistance
	self.rainDensity = fi*envA.rainDensity + f*envB.rainDensity
	self.rainColor:lerp ( envA.rainColor, envB.rainColor, f )
	self.boltPeriod = fi*envA.boltPeriod + f*envB.boltPeriod
	self.boltDuration = fi*envA.boltDuration + f*envB.boltDuration
	
	self.windVelocity = fi*envA.windVelocity + f*envB.windVelocity
	self.windDirection = fi*envA.windDirection + f*envB.windDirection
	
	self.skyColor:lerp ( envA.skyColor, envB.skyColor, f )
	self.ambient:lerp ( envA.ambient, envB.ambient, f )
	self.hemiColor:lerp ( envA.hemiColor, envB.hemiColor, f )
	self.sunColor:lerp ( envA.sunColor, envB.sunColor, f )
	self.sunDir:lerp ( envA.sunDir, envB.sunDir, f )
	if self.sunDir.y > 0 then
		outputDebugString ( "Некорректное направление солнца", 2 )
	end
end

function onRender( timeSlice )
	local hours, minutes = getTime()
	local time = hours * 3600 + minutes * 60
	local now = getTickCount()

	if time ~= g_LastTime then
		g_LastTime = time
		g_Time = time
		g_TimeSpeed = G_TIME_DURATION / 1000
		g_LastTicks = now
	end

	local ticksDiff = now - g_LastTicks
	local secDuration = G_TIME_DURATION
	local timeDiff = ( ticksDiff / secDuration ) * 60

	g_Time = g_Time + timeDiff
	g_LastTicks = now

	--[[local time = getEnvironmentGameDayTimeSec( 100 )
	if freezeValue ~= nil then
		time = freezeValue
	end]]
	--time = 43200
	xrEnvironment.setGameTime ( g_Time )
	xrEnvironment.update ( )
	
	--dxDrawText ( getTimeStr( g_Time ), 500, 400, 100, 100, tocolor ( 255, 255, 255 ), 3 )

	--[[dxDrawText ( time, 500, 400, 100, 100, tocolor ( 255, 255, 255 ), 3 )
	if xrEnvironment.envStart then
		dxDrawText ( xrEnvironment.envStart.timeStr .. "(" ..xrEnvironment.envStart.execTime .. ") >> " .. xrEnvironment.envEnd.timeStr .. "(" .. xrEnvironment.envEnd.execTime .. ")", 500, 500, 100, 100, tocolor ( 255, 255, 255 ), 3 )
	end]]
	
	--local sw = guiGetScreenSize ( )
	--dxDrawText ( math.floor ( time / 3600 ) .. " hours", sw / 2 - 50, 0, 100, 100, tocolor ( 255, 255, 255 ), 3 )

	xrSurge:update( timeSlice )	
end

function xrStartSkybox()
	local hours, minutes = getTime()
	g_LastTime = hours * 3600 + minutes * 60
	g_Time = hours * 3600 + minutes * 60
	g_TimeSpeed = G_TIME_DURATION / 1000
	g_LastTicks = getTickCount()

	xrEnvironment.new()	

	xrEnvironment.load( "weathers/[default]" )	
	xrEnvironment.load( "weather_effects/fx_surge_day_3" )	
	xrEnvironment.setWeather( "weathers/[default]" )	

	addEventHandler( "onClientPreRender", root, onRender, false )
end

--[[
	TEMP EXPORT
]]
local ENV_AMBIENT = 1
local ENV_HEMI = 2
local ENV_SUNCOLOR = 3
local ENV_SUNDIR = 4

function getEnvValue ( type )
	if xrEnvironment.currentEnv then
		if type == ENV_AMBIENT then
			return xrEnvironment.currentEnv.ambient.x, xrEnvironment.currentEnv.ambient.y, xrEnvironment.currentEnv.ambient.z
		elseif type == ENV_HEMI then
			return xrEnvironment.currentEnv.hemiColor.x, xrEnvironment.currentEnv.hemiColor.y, xrEnvironment.currentEnv.hemiColor.z, xrEnvironment.currentEnv.hemiColor.w
		elseif type == ENV_SUNCOLOR then
			return xrEnvironment.currentEnv.sunColor.x, xrEnvironment.currentEnv.sunColor.y, xrEnvironment.currentEnv.sunColor.z
		elseif type == ENV_SUNDIR then
			return xrEnvironment.currentEnv.sunDir.x, xrEnvironment.currentEnv.sunDir.y, xrEnvironment.currentEnv.sunDir.z
		end
	end
end

--[[addEventHandler( "onClientResourceStart", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )

		xrStartSkybox()
    end
)]]

--addEventHandler( "onClientResourceStart", root,
addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "global.lua" )
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )

		if not xrSettingsInclude( "environment/thunderbolts.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
		end
        if not xrSettingsInclude( "environment/thunderbolt_collections.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
		end    		

		xrStartSkybox()
		xrInitSurge()
    end
)