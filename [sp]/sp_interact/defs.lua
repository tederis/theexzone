xrClasses = {

}

-- Артефакты, которые игрок подбирает в аномалии
ArtefactClass = {
    onClientUse = function( self, element, player ) 
        triggerEvent( "onClientArtefactTake", element )
    end
}

-- NPC, с которыми можно поболтать и поторговаться
local lootStr = "Обыскать [E]"
local talkStr = "Говорить [E]"

CharacterClass = {
    onUse = function( self, element, player )
        --[[
            Фейковый игрок
        ]]
        --[[if getElementData( element, "fake" ) or getElementData( element, "volatile" ) then
            if exports[ "sp_inventory" ]:xrGetInventorySessionStatus( player ) then
                exports[ "sp_inventory" ]:xrStopInventorySession( player )
            else
                exports[ "sp_inventory" ]:xrStartInventorySession( player, element )
            end

            return
        end]]

        --[[
            Торговец
        ]]
        local playerTeam = getPlayerTeam( player )
        local pedTeam = getElementData( element, "team", false )
        if not pedTeam or ( isElement( playerTeam ) and pedTeam == getTeamName( playerTeam ) ) then
            exports[ "sp_dialog" ]:xrPlayerSwitchTalk( player, element )
        else
            outputChatBox( "Вы не можете говорить с этим персонажем", player, 200, 10, 10 )
        end
    end,
    getText = function( self, element )
        if getElementData( element, "fake" ) then
            return lootStr
        else
            return talkStr
        end
    end
}

-- Контейнеры, в которые можно класть и забирать вещи
ContainerClass = {
    onUse = function( self, element, player )
        if exports[ "sp_inventory" ]:xrGetInventorySessionStatus( player ) then
            exports[ "sp_inventory" ]:xrStopInventorySession( player )
        else
            exports[ "sp_inventory" ]:xrStartInventorySession( player, element )
        end
    end
}

-- Другие игроки
PlayerClass = {
    isUsableClient = function( self, element, player )
        return isPedDead( element )
    end,

    onUse = function( self, element, player )
        if isPedDead( element ) ~= true then
            return
        end

        if exports[ "sp_inventory" ]:xrGetInventorySessionStatus( player ) then
            exports[ "sp_inventory" ]:xrStopInventorySession( player )
        else
            exports[ "sp_inventory" ]:xrStartInventorySession( player, element )
        end
    end
}

DropClass = {
    onUse = function( self, element, player )
        xrUseDropElementRelated( element, player )
    end,
    getText = function( self, element )
        return "Подобрать " .. tostring( getElementData( element, "name", false ) ) .. " [E]"
    end
}

CampfireClass = {
    isUsableClient = function( self, element, player )
        return true
    end,

    onClientUse = function( self, element, player )
        xrStartGuitarSession()
    end,
    onUse = function( self, element, player )
        
    end,
    getText = function( self, element )
        return "Присесть [E]"
    end
}

local activateStr = "Активировать [E]"
local ClassMT = {
    __index = {
        onClientUse = function() end,
        onUse = function() end,
        isUsableClient = function() return true end,
        getText = function() return activateStr end
    }
}

local function xrDefineClassImpl( typeHash, tbl )
    if type( tbl ) ~= "table" then
        outputDebugString( "Класс премета в теле скрипта не был найден!", 2 )
        return
    end

    xrClasses[ typeHash ] = setmetatable( tbl, ClassMT )
end

function xrInitClasses()
    xrDefineClassImpl( _hashFn( "CharacterClass" ), CharacterClass )
    xrDefineClassImpl( _hashFn( "PlayerClass" ), PlayerClass )
    xrDefineClassImpl( _hashFn( "ContainerClass" ), ContainerClass )
    xrDefineClassImpl( _hashFn( "ArtefactClass" ), ArtefactClass )
    xrDefineClassImpl( _hashFn( "DropClass" ), DropClass )
    xrDefineClassImpl( _hashFn( "CampfireClass" ), CampfireClass )
end