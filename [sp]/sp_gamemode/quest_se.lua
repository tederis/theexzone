xrPlayerQuests = {

}

xrQuests = {

}

--[[
    PlayerQuest
]]
PQS_NONE = -1

PlayerQuest = {

}
PlayerQuestMT = {
    __index = PlayerQuest
}

function PlayerQuest:load( state, vars )
    self.state = tonumber( state ) or PQS_NONE

    if type( vars ) == "table" then
        self.variables = vars
    end

    return true
end

function PlayerQuest:start()

end

function PlayerQuest:stop()

end

function PlayerQuest:setState( state )
    if state ~= self.state then
        self.state = state
        
        triggerClientEvent( self.player, EClientEvents.onClientQuestState, self.player, self.id, state )
        -- Оповещаем ресурс sp_player об изменениях в квестах игрока
        triggerEvent( "onPlayerQuestUpdated", self.player )
    end
end

function PlayerQuest:setVariable( key, value )
    local vars = self.variables

    if vars[ key ] ~= value then
        vars[ key ] = value

        triggerClientEvent( self.player, EClientEvents.onClientQuestVar, self.player, self.id, key, value )
        -- Оповещаем ресурс sp_player об изменениях в квестах игрока
        triggerEvent( "onPlayerQuestUpdated", self.player )
    end
end

function PlayerQuest:onPlayerLeave()

end

function PlayerQuest:onPlayerDead()

end

--[[
    СourierQuest
]]
local CQS_PACKAGE_GIVEN = 1

local CQV_ITEM_ID = 1

local COURIER_QUEST_PERIOD_SECS = 45 * 60

CourierQuest = {

}
CourierQuestMT = {
    __index = CourierQuest
}
setmetatable( CourierQuest, PlayerQuestMT )

function CourierQuest:start()
    local section = self.section

    if self.state == PQS_NONE then
        local itemId

        local nowTimestamp = getRealTime().timestamp
        exports.sp_player:xrSetPlayerInfo( self.player, EHashes.QuestInfoLastTime, nowTimestamp )

        -- Игрок прежде носил посылки?
        if exports.sp_player:xrGetPlayerInfo( self.player, EHashes.QuestInfoPassedCourier ) then
            local randItemHash = section.items[ math.random( 1, #section.items ) ]
            itemId = exports.sp_dialog:xrPlayerGiveItem( self.player, randItemHash, EHashes.SlotBag, 1 )
        else
            itemId = exports.sp_dialog:xrPlayerGiveItem( self.player, section.start_item, EHashes.SlotBag, 1 )
        end

        self:setVariable( CQV_ITEM_ID, itemId )
        self:setState( CQS_PACKAGE_GIVEN )
    end
end

function CourierQuest:stop()
    
end

function CourierQuest:onFinish()
    local itemId = self.variables[ CQV_ITEM_ID ]
    local itemSlotHash = exports.xritems:xrGetContainerItemData( self.player, itemId, EIA_SLOT )

    if itemSlotHash and itemSlotHash ~= EHashes.SlotTemp then
        local itemHash = exports.xritems:xrGetContainerItemData( self.player, itemId, EIA_TYPE )
        local itemSection = xrSettingsGetSection( itemHash )

        if itemSection and exports.xritems:xrDecimateContainerItem( self.player, itemId, 1, false ) then
            exports.sp_dialog:xrPlayerGiveMoney( self.player, tonumber( itemSection.value ) or 3000 )
            exports.sp_dialog:xrPlayerGiveRank( self.player, tonumber( itemSection.value_rank ) or 3 )
        end
    else
        outputDebugString( "Предмет не был найден", 2 )
    end

    exports.sp_player:xrRemovePlayerInfo( self.player, EHashes.QuestInfoHasQuestCourier )

    PlayerQuest_finish( self, true )
end

function CourierQuest:isItemExists()
    local itemId = self.variables[ CQV_ITEM_ID ]
    local itemSlotHash = exports.xritems:xrGetContainerItemData( self.player, itemId, EIA_SLOT )
    if itemSlotHash and itemSlotHash ~= EHashes.SlotTemp then
        return true
    end

    return false
end

function CourierQuest:onPlayerDead()
    local itemId = self.variables[ CQV_ITEM_ID ]
    exports.xritems:xrContainerRemoveItem( self.player, itemId )
    exports.sp_player:xrRemovePlayerInfo( self.player, EHashes.QuestInfoHasQuestCourier )

    PlayerQuest_finish( self, false )
end

function xrStartCourierQuest( player )
    if PlayerQuest_getQuest( player, EHashes.QuestCourier ) then
        outputDebugString( "Игрок уже выполняет этот квест!", 2 )

        -- Возвращаем false чтобы не закрывать диалог
        return false
    end

    local quest = PlayerQuest_create( player, EHashes.QuestCourier )
    quest:start()

    -- Возвращаем false чтобы не закрывать диалог
	return false
end

function xrFinishCourierQuest( player )
    local quest = PlayerQuest_getQuest( player, EHashes.QuestCourier )
    if quest then
        quest:onFinish()
    end

    -- Возвращаем false чтобы не закрывать диалог
	return false
end

function xrIsPlayerKeepCourierItem( player )
    local quest = PlayerQuest_getQuest( player, EHashes.QuestCourier )
    if quest then
        return quest:isItemExists()
    end

    -- Возвращаем false чтобы не закрывать диалог
	return false
end

function xrIsPlayerWasteCourierItem( player )
    local quest = PlayerQuest_getQuest( player, EHashes.QuestCourier )
    if quest then
        return quest:isItemExists() ~= true
    end

    -- Возвращаем false чтобы не закрывать диалог
	return false
end

function xrPlayerCourierTimeCondition( player )
    local lastTimestamp = exports.sp_player:xrGetPlayerInfo( player, EHashes.QuestInfoLastTime )
    if not lastTimestamp then
        return true
    end

    local nowTimestamp = getRealTime().timestamp
    local deltaTimestamp = nowTimestamp - lastTimestamp

    return deltaTimestamp > COURIER_QUEST_PERIOD_SECS
end

function xrPlayerCourierTimeConditionInv( player )
    return not xrPlayerCourierTimeCondition( player )
end

--[[
    Exports
]]
function PlayerQuest_create( player, questHash, silent )
    local questSection = xrSettingsGetSection( questHash )
    if not questSection then
        outputDebugString( "Секция для квеста не была найдена!", 2 )
        return
    end

    local questClassName = tostring( questSection.class ) or ""
    local classTbl = _G[ questClassName ]
    local classMetaTbl = _G[ questClassName .. "MT" ]
    if not classTbl or not classMetaTbl then
        outputDebugString( "Класса для данного квеста не существует!", 2 )
        return
    end

    local id = xrQuests:allocate()

    local quest = {
        player = player,   
        type = questHash,     
        section = questSection,
        variables = {},
        id = id,
        state = PQS_NONE
    }

    setmetatable( quest, classMetaTbl )

    xrQuests[ id ] = quest

    local playerQuests = xrPlayerQuests[ player ]
    if playerQuests then
        table.insert( playerQuests, quest )
    else
        xrPlayerQuests[ player ] = { quest }        
    end    

    if silent ~= true then
        triggerClientEvent( player, EClientEvents.onClientQuestCreate, player, questHash, id )

        -- Оповещаем ресурс sp_player об изменениях в квестах игрока
        triggerEvent( "onPlayerQuestUpdated", player )
    end

    return quest
end

function PlayerQuest_finish( quest, success )
    quest:stop()

    local quests = xrPlayerQuests[ quest.player ]
    if quests then
        table.removeValue( quests, quest )
    end   

    xrQuests[ quest.id ] = nil

    -- Оповещаем ресурс sp_player об изменениях в квестах игрока
    triggerEvent( "onPlayerQuestUpdated", quest.player )
end

function PlayerQuest_onGamemodeLeave( dead )
    for _, quest in ipairs( xrPlayerQuests[ source ] or EMPTY_TABLE ) do
        quest:onPlayerLeave( dead )
        quest:stop()

        xrQuests[ quest.id ] = nil
    end

    xrPlayerQuests[ source ] = nil
end

function PlayerQuest_onDead()
    for _, quest in ipairs( xrPlayerQuests[ source ] or EMPTY_TABLE ) do
        quest:onPlayerDead()
    end
end

function PlayerQuest_getQuest( player, questHash )
    for _, quest in ipairs( xrPlayerQuests[ player ] or EMPTY_TABLE ) do
        if quest.type == questHash then
            return quest
        end
    end
end

function PlayerQuest_getQuestsPack( player )
    local pack = {}
    for _, quest in ipairs( xrPlayerQuests[ player ] or EMPTY_TABLE ) do
        table.insert( pack, {
            [ QPT_TYPE ] = quest.type,
            [ QPT_STATE ] = quest.state,
            [ QPT_VARS ] = quest.variables
        } )
    end

    return pack
end

function PlayerQuest_loadQuests( player, pack )
    for _, data in ipairs( pack ) do
        local quest = PlayerQuest_create( player, data[ QPT_TYPE ], true )
        if quest and quest:load( data[ QPT_STATE ], data[ QPT_VARS ] ) then
            quest:start()
        end
    end

    -- Оповещаем ресурс sp_player об изменениях в квестах игрока
    triggerEvent( "onPlayerQuestUpdated", player )
end

--[[
    Init
]]
function initQuests()
    xrQuests = xrMakeIDTable()

    addEventHandler( EServerEvents.onPlayerGamodeLeave, root, PlayerQuest_onGamemodeLeave, true, "low" )
    --addEventHandler( EServerEvents.onPlayerDead, root, PlayerQuest_onDead, true )
end