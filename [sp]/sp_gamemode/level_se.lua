xrLevels = {

}

xrPlayerLevels = {

}

--[[
    xrLevel
]]
xrLevel = {

}
xrLevelMT = { 
    __index = xrLevel 
}

function xrLevel:addPlayer( player )
    if table.insertIfNotExists( self.players, player ) then
        triggerClientEvent( EClientEvents.onClientPlayerEnterLevel, player )
        triggerEvent( EServerEvents.onPlayerEnterLevel, player )
    end
end

function xrLevel:removePlayer( player )
    if table.removeValue( self.players, player ) then
        triggerClientEvent( EClientEvents.onClientPlayerLeaveLevel, player )
        triggerEvent( EServerEvents.onPlayerLeaveLevel, player )
    end
end

function xrLevel:getRandomSpawnpoint( factionHash, specialName )
    local spawnpoints = {

    }

    for _, spawnpoint in ipairs( self.spawnpoints ) do
        if spawnpoint.faction == factionHash and spawnpoint.special == specialName then
            table.insert( spawnpoints, spawnpoint )
        end
    end

    if #spawnpoints > 0 then
        return spawnpoints[ math.random( 1, #spawnpoints ) ]
    end

    return false
end

function xrLevel:spawnPlayer( player )
    local factionHash = getElementData( player, "faction", false )
    local special = "normal"
    if getElementData( player, "offender", false ) or xrGetPlayerMaxWantedLevel( player ) >= 2 then
        special = "penalty"
    end

    local spawnpoint = self:getRandomSpawnpoint( factionHash, special )
    if not spawnpoint then
        outputDebugString( "Не можем найти подходящую точку спавна!", 1 )
        return false
    end

    local skin = getElementData( player, "skin", false )
    if not skin then
        return false
    end

    -- Если к игроку не привязаны данные персонажа
    if not getElementData( player, "charId", false ) then
        outputDebugString( "К игроку должен быть привязан персонаж!", 1 )
        return false
    end

    local factionHash = getElementData( player, "faction", false )
    xrSetPlayerTeam( player, factionHash )

    local x = spawnpoint.x + math.random( -2, 2 )
    local y = spawnpoint.y + math.random( -2, 2 )
    local z = spawnpoint.z

    exports.sp_player:xrPlayerSpawn( player, x, y, z, skin )    

    -- Сообщаем игроку о причинах спавна вне лагеря
    if special == "penalty" then
        exports.sp_hud_real_new:xrSendPlayerHelpString( player, HSC_KILLER_PENALTY )
    end
end

function xrLevel:doPlayerJoin( player )
    if self.joined[ player ] then
        return
    end  
    
    self.joined[ player ] = true

    triggerEvent( EServerEvents.onPlayerGamodeJoin, player )
    triggerClientEvent( EClientEvents.onClientPlayerGamodeJoin, player )

    self:spawnPlayer( player )
end

function xrLevel:doPlayerLeave( player, dead )
    if self.joined[ player ] ~= true then
        return
    end    

    triggerEvent( EServerEvents.onPlayerGamodeLeave, player, dead )
    triggerClientEvent( EClientEvents.onClientPlayerGamodeLeave, player, dead )

    xrSetPlayerTeam( player, nil )

    self.joined[ player ] = nil
end

function xrLevel:isPlayerJoined( player )
    return self.joined[ player ] == true
end

--[[
    Exports
]]
function xrCreateLevel()
    local level = {
        players = {},
        joined = {},
        spawnpoints = {}
    }

    return setmetatable( level, xrLevelMT )
end

function xrCreateSpawnpoint( levelHash, factionHash, x, y, z, special )
    local level = xrLevels[ levelHash ]
    if level then
        local spawnpoint = {
            faction = factionHash,
            x = x,
            y = y,
            z = z            
        }

        if type( special ) == "string" then
            spawnpoint.special = special
        end

        table.insert( level.spawnpoints, spawnpoint )
    end
end

--[[
    Init
]]
function xrInitLevels()
    xrLevels[ 1 ] = xrCreateLevel()
end