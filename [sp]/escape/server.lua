local posX = -684.473022
local posY = -3802.066895
local posZ = 120.439982

local blendX = -170.012
local blendY = -132.495
local blendZ = -16.9717

local resX = posX - blendX
local resY = posY - blendY
local resZ = posZ - blendZ

addEventHandler ( "onResourceStart", resourceRoot,
	function ( )
		for _, object in ipairs ( getElementsByType ( "object", resourceRoot ) ) do
			local x, y, z = getElementPosition ( object )
			local nx = x
			local ny = y
			local nz = z
			if ( getElementModel( object ) < 3975 or y < -2000 ) and getElementModel( object ) ~= 1271 then
				nx = x - resX
				ny = y - resY
				nz = z - resZ + 150

				setElementPosition( object, nx, ny, nz )
			end

			nz = nz - 25
			setElementPosition( object, nx, ny, nz )

			local lodModel = getElementData ( object, "lod", false )
			if lodModel then
				local rx, ry, rz = getElementRotation ( object )
				local lodObj = createObject ( tonumber ( lodModel ), nx, ny, nz + 0.02, rx, ry, rz, true )
				setLowLODElement( object, lodObj )
			end
        end       
	end
, false )

local typeParser = {
	[ "spawnpoint" ] = function( xmlnode )
		local factionHash = _hashFn( xmlNodeGetAttribute( xmlnode, "faction" ) )
		local special = xmlNodeGetAttribute( xmlnode, "special" )
		local posX = tonumber( xmlNodeGetAttribute( xmlnode, "posX" ) )
		local posY = tonumber( xmlNodeGetAttribute( xmlnode, "posY" ) )
		local posZ = tonumber( xmlNodeGetAttribute( xmlnode, "posZ" ) )

		exports.sp_gamemode:xrCreateSpawnpoint( 1, factionHash, posX, posY, posZ - 25, special )
	end,
	[ "zone" ] = function( xmlnode )
		local typeHash = _hashFn( xmlNodeGetAttribute( xmlnode, "type" ) )
		local posX = tonumber( xmlNodeGetAttribute( xmlnode, "posX" ) )
		local posY = tonumber( xmlNodeGetAttribute( xmlnode, "posY" ) )
		local posZ = tonumber( xmlNodeGetAttribute( xmlnode, "posZ" ) )
		local radius = tonumber( xmlNodeGetAttribute( xmlnode, "radius" ) )
		local strength = tonumber( xmlNodeGetAttribute( xmlnode, "strength" ) )


		exports.anomaly:Zone_create( typeHash, posX, posY, posZ - 25, radius, strength )
	end,
	[ "ped" ] = function( xmlnode )
		local typeHash = _hashFn( xmlNodeGetAttribute( xmlnode, "type" ) )
		local model = tonumber( xmlNodeGetAttribute( xmlnode, "model" ) )
		local rank = tonumber( xmlNodeGetAttribute( xmlnode, "rank" ) )
		local posX = tonumber( xmlNodeGetAttribute( xmlnode, "posX" ) )
		local posY = tonumber( xmlNodeGetAttribute( xmlnode, "posY" ) )
		local posZ = tonumber( xmlNodeGetAttribute( xmlnode, "posZ" ) )
		local rotZ = tonumber( xmlNodeGetAttribute( xmlnode, "rotZ" ) ) or 0
		local name = xmlNodeGetAttribute( xmlnode, "name" )
		local teamName = xmlNodeGetAttribute( xmlnode, "team" )

		local ped = createPed( model, posX, posY, posZ - 25, rotZ, false )
		if ped then
			setElementFrozen( ped, true )
			setElementData( ped, "cl", typeHash )
			setElementData( ped, "int", EHashes.CharacterClass )
			setElementData( ped, "rank", rank )
			setElementData( ped, "name", name )
			setElementData( ped, "leader", true )
			if teamName then
				setElementData( ped, "team", teamName )
			end
		end
	end,
}

local function loadEntities( xml )
	for _, node in ipairs( xmlNodeGetChildren( xml ) ) do
		local parseFn = typeParser[ xmlNodeGetName( node ) ]
		if parseFn then
			parseFn( node )
		end
	end
end

--[[
    Initialization
]]
addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
        triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addEventHandler( "onCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

		local xml = xmlLoadFile( "entities.xml", true )
		if xml then
			loadEntities( xml )
			xmlUnloadFile( xml )
		end

		for i=550,20000 do
            removeWorldModel(i,10000,0,0,0)
        end
        setOcclusionsEnabled(false)  -- Also disable occlusions when removing certain models
        setWaterLevel(-5000)         -- Also hide the default water as it will be full of holes
    end
, true, "low" )