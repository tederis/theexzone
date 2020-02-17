INPUT_GLOBAL = 1
INPUT_FACTION = 2
INPUT_GROUP = 3
INPUT_ADMIN = 4

VOLUME_NORMAL = 1
VOLUME_WHISPER = 2
VOLUME_LOUD = 3
VOLUME_FIRST = 4
VOLUME_THIRD = 5
VOLUME_TRY = 6
-- Temp
VOLUME_ALL = 7

local NORMAL_RADIUS_SQR = 55*45
local WHISPER_RADIUS_SQR = 6*6
local LOUD_RADIUS_SQR = 100*100

local staffACLs = {
    aclGetGroup( "Admin" ),
    aclGetGroup( "Moderator" ),
    aclGetGroup( "SuperModerator" ),
}

function doStaffTest( p )
    local acc = getPlayerAccount( p )
    if not acc or isGuestAccount( acc ) then
        return false 
    end

    local objName = getAccountName( acc )

    for _, group in ipairs( staffACLs ) do
        if isObjectInACLGroup( "user." .. objName, group ) then
            return true
        end
    end

    return false
end

local function doVolumeTest( dstPlayer, srcPlayer, volume )
    if volume == VOLUME_ALL then
        return true
    end

    local srcX, srcY = getElementPosition( srcPlayer )
    local dstX, dstY = getElementPosition( dstPlayer )
    local distSqr = ( srcX - dstX )^2 + ( srcY - dstY )^2

    if volume > VOLUME_LOUD then
        return distSqr <= NORMAL_RADIUS_SQR
    else
        if volume == VOLUME_NORMAL then
            return distSqr <= NORMAL_RADIUS_SQR
        elseif volume == VOLUME_WHISPER then
            return distSqr <= WHISPER_RADIUS_SQR
        elseif volume == VOLUME_LOUD then
            return distSqr <= LOUD_RADIUS_SQR
        end
    end

    return dstPlayer == srcPlayer
end

local function doBroadcastGlobalMessage( msg, srcPlayer, msgVolume )
    local msgState = nil
    if msgVolume == VOLUME_TRY then
        msgState = math.random() > 0.5
    end

    for _, player in ipairs( getElementsByType( "player" ) ) do
        if doVolumeTest( player, srcPlayer, msgVolume ) then
            triggerClientEvent( player, "onClientCustomMessage", resourceRoot, msg, srcPlayer, INPUT_GLOBAL, msgVolume, msgState )
        end
    end
end

local function doBroadcastFactionMessage( msg, srcPlayer, dstTeam )
    for _, player in ipairs( getPlayersInTeam( dstTeam ) ) do
        triggerClientEvent( player, "onClientCustomMessage", resourceRoot, msg, srcPlayer, INPUT_FACTION, msgVolume )
    end
end

local function doBroadcastAdminMessage( msg, srcPlayer )
    for _, player in ipairs( getElementsByType( "player" ) ) do
        if doStaffTest( player ) then
            triggerClientEvent( player, "onClientCustomMessage", resourceRoot, msg, srcPlayer, INPUT_ADMIN, msgVolume )
        end
    end
end

local function onChatboxMessage( msg, msgType, msgVolume )
    if msgType == INPUT_GLOBAL then
        doBroadcastGlobalMessage( msg, client, msgVolume )
    elseif msgType == INPUT_FACTION then
        local team = getPlayerTeam( client )
        if team then
            doBroadcastFactionMessage( msg, client, team )
        end
    elseif msgType == INPUT_GROUP then
        -- TODO
    elseif msgType == INPUT_ADMIN then
        doBroadcastAdminMessage( msg, client )
    end
end

addEventHandler( "onCoreStarted", root,
--addEventHandler( "onResourceStart", resourceRoot,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )	
        
        addEvent( "onCustomMessage", true )
        addEventHandler( "onCustomMessage", resourceRoot, onChatboxMessage, false )
    end
)