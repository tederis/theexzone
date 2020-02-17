function xrGiveElementMoney( element, amount, testOnly )
    local typeStr = getElementType( element )
    if typeStr == "player" then
        return exports.sp_player:xrGivePlayerMoney( element, amount, testOnly )
    elseif typeStr == "ped" then
        return exports.sp_gamemode:xrGiveNPCMoney( element, amount, testOnly )
    end
end

function xrGetElementMoney( element )
	local typeStr = getElementType( element )
    if typeStr == "player" then

    elseif typeStr == "ped" then

    end
end

function xrGetPlayerFromCharacterName( name )
    for _, player in ipairs( getElementsByType( "player" ) ) do
        if getElementData( player, "name", false ) == name then
            return player
        end
    end

    return false
end

function xrGetPlayerByTraits( traits )
    local player

    local traitsNumerical = tonumber( traits )
    if traitsNumerical then
        player = exports.sp_player:xrGetPlayerFromCharacterId( traitsNumerical )
    elseif type( traits ) == "string" then
        player = xrGetPlayerFromCharacterName( traits )
    end

    if isElement( player ) then
        return player
    end

    return false
end

function xrIsPlayerWanted( player, team )
    local wanted = getElementData( player, "wanted", false )
    if type( wanted ) == "table" then
        return wanted[ team ] == true
    end
    
    return false
end