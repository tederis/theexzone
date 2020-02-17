local VEC_DOWNWARD = Vector3( 0, 0, -25 )

xrPlayers = {
    -- Пара [player] = xrPlayer
}

xrPlayerIndices = {
    -- Пара [player_id] = xrPlayer
}

xrPlayerCharacters = {
    -- Пара [player] = xrCharacter
}

xrCharacterIndices = {
    -- Пара [character_id] = xrCharacter
}

xrDirtyPlayers = {

}

xrTeamHashes = {

}

local function _obtainPlayer( arg )
    -- По элементу
    if isElement( arg ) then
        return xrPlayers[ arg ]
    end

    -- По индексу
    local index = tonumber( arg )
    return xrPlayerIndices[ index ]
end

function xrIsPlayerGuest( arg )
    local playerMeta = _obtainPlayer( arg )
    return type( playerMeta ) ~= "table"
end

--[[
    Login
]]
local function _onPlayerLogin( player, entry, characterEntries )
    -- На всякий случай сбрасываем
    xrPlayerCharacters[ player ] = nil

    local meta = {
        name = entry.name,
        id = tonumber( entry.id ),
        characters = {

        }
    }

    xrPlayers[ player ] = meta
    xrPlayerIndices[ entry.id ] = meta

    for _, data in pairs( characterEntries ) do
        -- Загружаем предметы персонажа
        exports[ "xritems" ]:xrContainerLoad( data.container_id, player )

        local info = fromJSON( tostring( data.info ) ) or {}
        info = restoreFromJSON( info )

        local quests = fromJSON( tostring( data.quests ) ) or {}
        quests = restoreFromJSON( quests )

        local character = {
            [ E_CHAR_PLAYER ] = player,
            [ E_CHAR_NAME ] = data.name,
            [ E_CHAR_ID ] = data.id,
            [ E_CHAR_SKIN ] = data.skin,
            [ E_CHAR_HEALTH ] = data.health,
            [ E_CHAR_ARMOR ] = data.armor,
            [ E_CHAR_MONEY ] = data.money,
            [ E_CHAR_RANK ] = data.rank,
            [ E_CHAR_REP ] = data.reputation,
            [ E_CHAR_CONT_ID ] = data.container_id,
            [ E_CHAR_PLAYER_ID ] = data.player_id,
            [ E_CHAR_FACTION ] = data.faction,
            [ E_CHAR_INFO ] = info,
            [ E_CHAR_QUESTS ] = quests,
            [ E_CHAR_WANTED ] = tonumber( data.wanted ) or 0
        }

        table.insert( meta.characters, character )

        xrCharacterIndices[ data.id ] = character
    end

    outputDebugString( "Игрок " .. entry.name .. " авторизован под ID " .. entry.id )
end

addEvent( "onPlayerLoginResult", false )
local function _onLoginProcess( qh, stage, player, playerSerial, arg )
    --[[
        МТА повторно использует идентификаторы игроков,
        значит, во время обработки запроса игрок мог измениться.
        Мы должны всегда валидировать игрока по сериалу
    ]]
    if getPlayerSerial( player ) ~= playerSerial then
        triggerEvent( "onPlayerLoginResult", player, LEC_FATAL )
        return
    end

    -- Если за период ожидания игрок успел авторизоваться
    if not xrIsPlayerGuest( player ) then
        triggerEvent( "onPlayerLoginResult", player, LEC_AUTHORIZED )
        return
    end

    local result = dbPoll( qh, 0 )

    if stage == 1 then
        if not result or #result == 0 then
            triggerEvent( "onPlayerLoginResult", player, LEC_UNREGISTERED )
            return
        end        

        local firstEntry = result[ 1 ]
        -- Если аккаунт с таким id уже в игре
        if xrPlayerIndices[ firstEntry.id ] then
            triggerEvent( "onPlayerLoginResult", player, LEC_AUTHORIZED )
            return
        end

        passwordVerify( arg, firstEntry.password, {}, 
            function( result )
                if getPlayerSerial( player ) ~= playerSerial then
                    return
                end
 
                if result then
                    -- Если за период ожидания игрок не успел авторизоваться
                    if xrIsPlayerGuest( player ) and not xrPlayerIndices[ firstEntry.id ] then
                        local db = exports[ "xrcore" ]:xrCoreGetDB()
                        dbQuery( _onLoginProcess, { 2, player, playerSerial, firstEntry }, db, "SELECT * FROM characters WHERE player_id = ?", firstEntry.id )

                        return
                    end
                end
                
                triggerEvent( "onPlayerLoginResult", player, LEC_UNREGISTERED )
            end
        )
    elseif stage == 2 then
        if not result then
            triggerEvent( "onPlayerLoginResult", player, LEC_FATAL )
            return
        end

        -- Если аккаунт с таким id уже в игре
        if xrPlayerIndices[ arg.id ] then
            triggerEvent( "onPlayerLoginResult", player, LEC_AUTHORIZED )
            return
        end

        _onPlayerLogin( player, arg, result )
        triggerEvent( "onPlayerLoginResult", player, 0 )
    end
end

function xrPlayerLogIn( player, name, password )
    -- Если мы уже авторизованы - выходим
    if not xrIsPlayerGuest( player ) then
        triggerEvent( "onPlayerLoginResult", player, LEC_AUTHORIZED )
        return false
    end

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbQuery( _onLoginProcess, { 1, player, getPlayerSerial( player ), password }, db, "SELECT * FROM players WHERE name = ?", name )
    
    return true
end

function xrPlayerLogOut( player )
    local itemExportFns = exports.xritems

    local meta = xrPlayers[ player ]
    if meta then
        for _, character in ipairs( meta.characters ) do
            itemExportFns:xrDestroyContainer( character[ E_CHAR_CONT_ID ] )

            xrCharacterIndices[ character[ E_CHAR_ID ] ] = nil
        end

        xrPlayers[ player ] = nil
        xrPlayerIndices[ meta.id ] = nil
    end

    local character = xrPlayerCharacters[ player ]
    if character then
        xrPlayerCharacters[ player ] = nil
    end

    collectgarbage( "collect" )
end

--[[
    Register
]]
local function _onPlayerRegister( player, id, name )
    local meta = {
        name = name,
        id = id,
        characters = {
            
        }
    }

    outputDebugString( "Новый игрок " .. name .. " зарегистрирован под ID " .. id )

    xrPlayers[ player ] = meta
    xrPlayers[ id ] = meta
end

addEvent( "onPlayerRegisterResult", false )
local function _onRegisterProcess( qh, stage, player, playerSerial, name, password )
    --[[
        МТА повторно использует идентификаторы игроков,
        значит, во время обработки запроса игрок мог измениться.
        Мы должны всегда валидировать игрока по сериалу
    ]]
    if getPlayerSerial( player ) ~= playerSerial then
        triggerEvent( "onPlayerRegisterResult", player, REC_FATAL )
        return
    end

    -- Если за период ожидания игрок успел авторизоваться
    if not xrIsPlayerGuest( player ) then
        triggerEvent( "onPlayerRegisterResult", player, REC_AUTHORIZED )
        return false
    end

    if stage == 1 then
        local result = dbPoll( qh, 0 )

        -- Аккаунт уже есть?
        if result and #result > 0 then
            triggerEvent( "onPlayerRegisterResult", player, REC_REGISTERED )
            return
        end

        -- Хэшируем пароль
        passwordHash( password, "bcrypt", {}, 
            function( result )
                if result and getPlayerSerial( player ) == playerSerial then
                    -- Если за период ожидания игрок не успел авторизоваться
                    if xrIsPlayerGuest( player ) then
                        local db = exports[ "xrcore" ]:xrCoreGetDB()
                        dbQuery( _onRegisterProcess, { 2, player, playerSerial, name, password }, db, "INSERT INTO players (name, password) VALUES (?, ?)", name, result )

                        return
                    end
                end

                triggerEvent( "onPlayerRegisterResult", player, REC_FATAL )
            end
        )
    elseif stage == 2 then
        local result, affecterRows, lastId = dbPoll( qh, 0 )
        if result and affecterRows > 0 then
            -- На всякий случай проверяем id
            if xrPlayerIndices[ lastId ] then
                triggerEvent( "onPlayerRegisterResult", player, REC_AUTHORIZED )
                return
            end

            _onPlayerRegister( player, lastId, name )
            triggerEvent( "onPlayerRegisterResult", player, 0 )
        end
    end
end

function xrPlayerRegister( player, name, password )
    -- Если мы уже авторизованы - выходим
    if not xrIsPlayerGuest( player ) then
        triggerEvent( "onPlayerRegisterResult", player, REC_AUTHORIZED )
        return false
    end

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbQuery( _onRegisterProcess, { 1, player, getPlayerSerial( player ), name, password }, db, "SELECT * FROM players WHERE name = ?", name )

    return true
end

--[[
    Characters
]]
local function _onCharacterCreated( player, id, name, factionHash, containerId )
    local playerMeta = _obtainPlayer( player )
    if not playerMeta then
        return
    end

    local factionData = xrTeamHashes[ factionHash ]
    if not factionData then
        outputDebugString( "Такой группировки не существует!", 1 )
        return
    end    

    -- Пока что статично
    local randomSkin = factionData.skin

    local character = {
        [ E_CHAR_PLAYER ] = player,
        [ E_CHAR_NAME ] = name,
        [ E_CHAR_ID ] = id,
        [ E_CHAR_SKIN ] = randomSkin,
        [ E_CHAR_HEALTH ] = 100,
        [ E_CHAR_ARMOR ] = 0,
        [ E_CHAR_MONEY ] = 0,
        [ E_CHAR_RANK ] = 0,
        [ E_CHAR_REP ] = 0,
        [ E_CHAR_CONT_ID ] = containerId,
        [ E_CHAR_PLAYER_ID ] = playerMeta.id,
        [ E_CHAR_FACTION ] = factionHash,
        [ E_CHAR_INFO ] = {},
        [ E_CHAR_QUESTS ] = {},
        [ E_CHAR_WANTED ] = 0
    }

    table.insert( playerMeta.characters, character )

    xrCharacterIndices[ id ] = character
end

function xrCreateCharacter( player, name, factionHash )
    local playerMeta = _obtainPlayer( player )
    if not playerMeta then
        return false
    end

    local factionData = xrTeamHashes[ factionHash ]
    if not factionData then
        outputDebugString( "Такой группировки не существует!", 1 )
        return false
    end

    -- Пока что статично
    local randomSkin = factionData.skin

    -- Если персонаж с таким именем уже существует
    local character = xrPlayerGetCharacter( player, name )
    if character then
        return false
    end

    -- Создаем контейнер для нового персонажа
    local containerId = exports[ "xritems" ]:xrCreateContainer( "PlayerContainer" )
    if not containerId then
        outputDebugString( "Не удалось создать контейнер!", 1 )
        return
    end

    exports[ "xritems" ]:xrSetContainerOwner( containerId, player )

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    local qh = dbQuery( db, [[INSERT INTO characters 
        (name, player_id, container_id, info, quests, faction, money, rank, reputation, skin, health, armor, wanted) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)]], name, playerMeta.id, containerId, "[[]]", "[[]]", factionHash, 0, 0, 0, randomSkin, 100, 100, 0
    )
    local result, affecterRows, lastId = dbPoll( qh, -1 )
    if result and affecterRows > 0 then
        _onCharacterCreated( player, lastId, name, factionHash, containerId )
        return true
    end

    return false
end

function xrPlayerSaveCharacter( player, character )
    local infoStr = toJSON( character[ E_CHAR_INFO ], true )
    if not infoStr then
        outputDebugString( "Ошибка при построении JSON строки", 1 )
        return
    end

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbExec( db, 
        "UPDATE `characters` SET `info` = ?, `money` = ?, `rank` = ?, `reputation` = ?, `health` = ?, `armor` = ?, `skin` = ?, `wanted` = ? WHERE `id` = ?", 
        infoStr,
        character[ E_CHAR_MONEY ],
        character[ E_CHAR_RANK ],
        character[ E_CHAR_REP ],
        character[ E_CHAR_HEALTH ],
        character[ E_CHAR_ARMOR ],
        character[ E_CHAR_SKIN ],
        character[ E_CHAR_WANTED ],
        character[ E_CHAR_ID ]        
    )

    outputDebugString( "Персонаж " .. character[ E_CHAR_NAME ] .. " игрока " .. getPlayerName( player ) .. " сохранен" )
end

function xrPlayerSaveCharacterQuests( player, character )
    local questsTbl = exports.sp_gamemode:PlayerQuest_getQuestsPack( player ) or {}
    local questsStr = toJSON( questsTbl, true )
    if not questsStr then
        outputDebugString( "Ошибка при построении JSON строки", 1 )
        return
    end

    character[ E_CHAR_QUESTS ] = questsTbl

    local db = exports[ "xrcore" ]:xrCoreGetDB()
    dbExec( db, 
        "UPDATE `characters` SET `quests` = ? WHERE `id` = ?", 
        questsStr,
        character[ E_CHAR_ID ]
    )

    outputDebugString( "Квесты персонажа " .. character[ E_CHAR_NAME ] .. " игрока " .. getPlayerName( player ) .. " сохранены" )
end

function xrPlayerApplyCharacter( player, characterName )
    local character = xrPlayerGetCharacter( player, characterName )
    if not character then
        outputDebugString( "Игрок не обладает данным персонажем!", 1 )
        return
    end    

    setElementData( player, "name", character[ E_CHAR_NAME ] )
    setElementData( player, "skin", character[ E_CHAR_SKIN ] )
    setElementData( player, "faction", character[ E_CHAR_FACTION ] )
    setElementData( player, "rep", character[ E_CHAR_REP ] )
    setElementData( player, "rank", character[ E_CHAR_RANK ] )
    setElementData( player, "charId", character[ E_CHAR_ID ] )
    setElementData( player, "contId", character[ E_CHAR_CONT_ID ] )
    setElementData( player, "money", character[ E_CHAR_MONEY ] )

    xrPlayerCharacters[ player ] = character
end

function xrPlayerGetCharacter( player, name )
    local playerMeta = _obtainPlayer( player )
    if not playerMeta then
        return
    end

    for _, character in ipairs( playerMeta.characters ) do
        if character[ E_CHAR_NAME ] == name then
            return character
        end
    end
end

function xrPlayerGetCharacters( player )
    local playerMeta = _obtainPlayer( player )
    if not playerMeta then
        return
    end

    return playerMeta.characters
end

function xrPlayerSpawn( player, x, y, z, skin )
    local character = xrPlayerCharacters[ player ]
    if character then
        local isDead = character[ E_CHAR_HEALTH ] < 1
        if isDead then
            character[ E_CHAR_HEALTH ] = 100
            character[ E_CHAR_ARMOR ] = 0
        end

        setElementData( player, "cl", EHashes.CharacterPlayer )

        spawnPlayer( player, x, y, z, 0, skin, 0, 0 )
        setElementModel( player, skin - 1 )
        setElementModel( player, skin )

        setElementFrozen( player, false )

        setElementAlpha( player, 255 )
        setElementHealth( player, character[ E_CHAR_HEALTH ] )
        setPedArmor( player, character[ E_CHAR_ARMOR ] )        

        setCameraTarget( player )
        fadeCamera( player, true, 2 )

        -- Скрываем SAшные элементы худа
        setPlayerNametagShowing( player, false )
        setPlayerHudComponentVisible( player, "crosshair", true )

        removeElementData( player, "uib" )
        setElementData( player, "lstate", false )

        triggerClientEvent( player, "onClientSpawned", player )
        triggerEvent( EServerEvents.onPlayerSpawn, player )

        -- Выполняем заполнение слотов сразу после спавна
        exports.xritems:xrRearrangeContainerSlots( player )

        -- Загружаем квесты
        exports.sp_gamemode:PlayerQuest_loadQuests( player, character[ E_CHAR_QUESTS ] or EMPTY_TABLE )
    end
end

function xrSetPlayerSkin( player, skinID )
    local character = xrPlayerCharacters[ player ]
    if character then
        if setElementModel( player, skinID ) then
            character[ E_CHAR_SKIN ] = skinID

            setElementData( player, "skin", skinID )

            xrMarkPlayerDirty( player, EDirtyFlags.States )
        end
    else
        outputDebugString( "У игрока нет персонажа", 2 )
    end
end

function xrGivePlayerMoney( player, amount, testOnly )
    local character = xrPlayerCharacters[ player ]
    if character then
        local money = character[ E_CHAR_MONEY ] + amount
        if testOnly then
            return money >= 0
        end

        if money >= 0 then
            if triggerEvent( "onPlayerMoneyChange", player, character[ E_CHAR_MONEY ], money ) and not wasEventCancelled() then
                character[ E_CHAR_MONEY ] = money

                -- Вспомогательная информация для удобного доступа
                setElementData( player, "money", money )

                xrMarkPlayerDirty( player, EDirtyFlags.States )            

                return true
            end
        end
    else
        outputDebugString( "У игрока нет персонажа", 2 )
    end

    return false
end

function xrSetPlayerInfo( player, fieldHash, value )
    local character = xrPlayerCharacters[ player ]
    if character and character[ E_CHAR_INFO ][ fieldHash ] ~= value then
        character[ E_CHAR_INFO ][ fieldHash ] = value

        xrMarkPlayerDirty( player, EDirtyFlags.Info )
    end
end

function xrRemovePlayerInfo( player, fieldHash )
    local character = xrPlayerCharacters[ player ]
    if character and character[ E_CHAR_INFO ][ fieldHash ] ~= nil then
        character[ E_CHAR_INFO ][ fieldHash ] = nil

        xrMarkPlayerDirty( player, EDirtyFlags.Info )
    end
end

function xrGetPlayerInfo( player, fieldHash )
    local character = xrPlayerCharacters[ player ]
    if character then
        return character[ E_CHAR_INFO ][ fieldHash ]
    end
end

function xrAddPlayerRank( player, delta )
    local character = xrPlayerCharacters[ player ]
    if character then
        local prevRank = character[ E_CHAR_RANK ]
        local newRank = math.clamp( 0, 999, prevRank + delta )
        
        local prevRankIndex = math.floor( ( prevRank / 1000 ) * 4 )
        local newRankIndex = math.floor( ( newRank / 1000 ) * 4 )
        if newRankIndex ~= prevRankIndex then
            local teamSection = xrTeamHashes[ character[ E_CHAR_FACTION ] ] or EMPTY_TABLE
            local nominal = teamSection.nominal or "бродяга"

            exports.sp_hud_real_new:xrPrintNews( 
                "Теперь игрок " .. character[ E_CHAR_NAME ] .. " " .. ERankNames[ newRankIndex ] .. "-" .. nominal, 
                "ui_inGame2_PD_Lider" 
            )
        end

        character[ E_CHAR_RANK ] = newRank
        -- Вспомогательная информация для удобного доступа
        setElementData( player, "rank", newRank )

        xrMarkPlayerDirty( player, EDirtyFlags.States )

        triggerClientEvent( player, EClientEvents.onClientAddRank, player, delta )
    end
end

function xrGetPlayerElementFromId( id )
    local playerMeta = xrPlayerIndices[ id ]

    if not playerMeta then
        return false
    end

    for element, elementMeta in pairs( xrPlayers ) do
        if elementMeta == playerMeta then
            return element
        end
    end

    return false
end

addCommandHandler( "addrank",
    function( player, _, dstPlayerTraits, value )
        if not hasObjectPermissionTo( player, "command.addrank", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        local dstPlayer = dstPlayerTraits == "self" and player or xrGetPlayerByTraits( dstPlayerTraits )
        if not dstPlayer then
            outputChatBox( "Такого игрока не существует!", player )
            return
        end

        xrAddPlayerRank( dstPlayer, tonumber( value ) or 0 )
    end
)

function xrMarkPlayerDirty( player, flag )
    xrDirtyPlayers[ player ] = bitOr( 
        xrDirtyPlayers[ player ] or EDirtyFlags.None, 
        tonumber( flag ) or EDirtyFlags.All 
    )
end

function xrSavePlayer( player, mask )
    local playerMeta = xrPlayers[ player ]
    if not playerMeta then
        return
    end

    local character = xrPlayerCharacters[ player ]
    if not character then
        return
    end

    xrPlayerSaveCharacter( player, character )

    if bitTest( mask, EDirtyFlags.Quests ) then
        xrPlayerSaveCharacterQuests( player, character )
    end
end

function xrGetPlayerFromCharacterId( charId )
    local character = xrCharacterIndices[ charId ]
    if character and isElement( character[ E_CHAR_PLAYER ] ) then
        return character[ E_CHAR_PLAYER ]
    end
end

addEventHandler( "onPlayerQuit", root,
    function()
        -- Выполняем выход из аккаунта
        xrPlayerLogOut( source )
    end
, true, "low" )

function xrKillPlayer( player, killer, bodypart )
    local character = xrPlayerCharacters[ player ]
    if character and character[ E_CHAR_HEALTH ] > 0 then  
        --[[
            Создаем фейкового игрока-педа, который заменит только что умершего игрока на карте
        ]]
        local fakePed = xrSpawnFakePlayer( player )
        if fakePed then
            local percent = math.interpolate( 0.5, 0.08, character[ E_CHAR_RANK ] / 1000 )

            -- Перемещаем часть предметов в слот лута
            exports.xritems:xrContainerMoveRandomItems( player, percent, fakePed, EHashes.SlotBag )
        end

        -- Перемещаем предметы во временный слот
        exports.xritems:xrContainerMoveItems( player, EHashes.SlotAny, player, EHashes.SlotTemp )

        -- Базовая аммуниция после смерти
        --exports.xritems:xrContainerInsertItem( player, EItemHashes.wpn_pm, EHashes.SlotBag, 1, true )
        --exports.xritems:xrContainerInsertItem( player, EItemHashes.ammo9_18_fmj, EHashes.SlotBag, 1, true )
        --exports.xritems:xrContainerInsertItem( player, EItemHashes.bandage, EHashes.SlotBag, 2, true )
        --exports.xritems:xrContainerInsertItem( player, EItemHashes.bolt, EHashes.SlotBag, 6, true )
       
        -- Задаем условие для использования в диалоге
        xrSetPlayerInfo( player, EHashes.InfoPlayerNaked, true )
        
        character[ E_CHAR_HEALTH ] = 0
        character[ E_CHAR_ARMOR ] = 0

        setElementAlpha( player, 0 )
        takeAllWeapons( player )

        killPed( player )

        xrMarkPlayerDirty( player, EDirtyFlags.All )        

        triggerEvent( EServerEvents.onPlayerDead, player, killer, bodypart )
        triggerClientEvent( EClientEvents.onClientPlayerDead, player, killer, bodypart )

        do
            --[[
                Прячем игрока под карту чтобы он не потерял синхронизацию своих агентов
            ]]
            setElementPosition( player, player.position + VEC_DOWNWARD )
            setElementFrozen( player, true )
        end
    end
end

local function onPlayerForceDead( killer, bodypart )
    xrKillPlayer( client, killer, bodypart )
end

local function onPlayerDamage( attacker, wpn, bodypart, loss )
    local character = xrPlayerCharacters[ source ]
    if character and character[ E_CHAR_HEALTH ] > 0 then
        -- Трюк для фикса потенциальной проблемы при загрузке персонажа
        character[ E_CHAR_HEALTH ] = math.max( getElementHealth( source ), 1 )
        character[ E_CHAR_ARMOR ] = getPedArmor( source )

        xrMarkPlayerDirty( source, EDirtyFlags.States )
    end
end

local function onPlayerChat( message, messageType )
    local name = getElementData( source, "name", false )
    local team = getPlayerTeam( source )
    local cr, cg, cb = getTeamColor( team )

    if messageType == 2 then
        local teamName = getElementData( team, "text", false )
        local msg = {
            "(", teamName, ") ", RGBToHex( cr, cg, cb ), name, ": #FFFFFF", message
        }
        local msgStr = table.concat( msg )

        for _, player in ipairs( getPlayersInTeam( team ) ) do
            outputChatBox( msgStr, player, 255, 255, 255, true )
        end
        outputServerLog( msgStr ) -- TEMP
    elseif messageType == 0 then
        local msg = {
            RGBToHex( cr, cg, cb ), name, ": #FFFFFF", message
        }
        local msgStr = table.concat( msg )

        outputChatBox( msgStr, root, 255, 255, 255, true )
        outputServerLog( msgStr ) -- TEMP
    end

    cancelEvent()
end

addEvent( "onPlayerQuestUpdated", false )
local function onPlayerQuestUpdated( questHash, success )
    xrMarkPlayerDirty( source, EDirtyFlags.Quests )
end

local function onPlayerGamodeLeave()
    -- Перемещаем подальше чтобы не мешал
    setElementFrozen( source, false )
    setElementPosition( source, 3000, 3000, 0, true )

    xrSavePlayer( source, EDirtyFlags.All )
    xrDirtyPlayers[ source ] = nil
end

local function onUpdatePulse()
    local player, mask = next( xrDirtyPlayers )
    if player ~= nil then
        if isElement( player ) then
            xrSavePlayer( player, mask )
        end    
        xrDirtyPlayers[ player ] = nil
    end    
end

--[[
    Initialization
]]
local function xrInitTeams()
    local listSection = xrSettingsGetSection( _hashFn( "teams_list" ) )
    if not listSection then
        outputDebugString( "Не можем найти список группировок", 2 )
        return
    end

    for _, section in ipairs( listSection ) do
        xrTeamHashes[ section._nameHash ] = section
    end
end

addEvent( "onCoreStarted", false )
addEventHandler( "onCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        if not xrSettingsInclude( "creatures/actor.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        if not xrSettingsInclude( "teams.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации команд!", 2 )
            return
        end

        xrInitTeams()

        addEvent( EServerEvents.onPlayerForceDead, true )
        addEventHandler( EServerEvents.onPlayerForceDead, root, onPlayerForceDead, true, "low" )
        addEventHandler( "onPlayerDamage", root, onPlayerDamage )
        addEventHandler( "onPlayerChat", root, onPlayerChat )
        addEventHandler( "onPlayerQuestUpdated", root, onPlayerQuestUpdated )
        addEvent( EServerEvents.onPlayerGamodeLeave, false )
        addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave, true, "high" )

        setTimer( onUpdatePulse, 15000, 0 )
    end
)

addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
		local db = exports[ "xrcore" ]:xrCoreGetDB()
        if not db then
            outputDebugString( "Указатель на базу данных не был получен!", 1 )
            return
        end

        triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addCommandHandler( "givemoney",
    function( player, _, dstPlayerTraits, amount )
        if not hasObjectPermissionTo( player, "command.givemoney", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        local dstPlayer = dstPlayerTraits == "self" and player or xrGetPlayerByTraits( dstPlayerTraits )
        if not dstPlayer then
            outputChatBox( "Такого игрока не существует!", player )
            return
        end

        xrGivePlayerMoney( dstPlayer, tonumber( amount ) or 0 )
    end
)

addCommandHandler( "xsetskin",
    function( player, _, dstPlayerTraits, skinID )
        if not hasObjectPermissionTo( player, "command.xsetskin", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        local dstPlayer = dstPlayerTraits == "self" and player or xrGetPlayerByTraits( dstPlayerTraits )
        if not dstPlayer then
            outputChatBox( "Такого игрока не существует!", player )
            return
        end

        skinID = tonumber( skinID ) or 0
        if true then
            xrSetPlayerSkin( dstPlayer, skinID )
        else
            outputChatBox( "Указанного скина не существует!", player )
        end
    end
)

addCommandHandler( "xadminmode",
    function( player, _ )
        if not hasObjectPermissionTo( player, "command.xadminmode", false ) then
            outputChatBox( "У вас недостаточно прав для использования этой команды", player )
            return
        end

        local enabled = getElementData( player, "adminmode", false ) == true
        setElementData( player, "adminmode", not enabled, true )

        if enabled then
            outputChatBox( "Вы деактивировали админ-режим", player )
        else
            outputChatBox( "Вы активировали админ-режим", player )
        end
    end
)