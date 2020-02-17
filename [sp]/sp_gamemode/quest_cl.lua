xrPlayerQuests = {

}

--[[
    PlayerQuest
]]
PlayerQuest = {

}
PlayerQuestMT = {
    __index = PlayerQuest
}

function PlayerQuest:setState( state )
    if state ~= self.state then
        self.state = state
    end
end

function PlayerQuest_create( questHash )
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

    local quest = {    
        section = questSection
    }

    setmetatable( quest, classMetaTbl )
    quest:init()

    return quest
end

local function onQuestStateChanged( questIndex, state )
    local quest = xrPlayerQuests[ questIndex ]
    if quest then
        quest:setState( state )
    end
end

local function onQuestVarChanged( questIndex, key, value )
    local quest = xrPlayerQuests[ questIndex ]
    if quest then
        quest:setVariable( key, value )
    end
end

local function onQuestCreated( questIndex, questHash )
    xrPlayerQuests[ questIndex ] = PlayerQuest_create( questHash )
end

function initQuests()
    addEvent( EClientEvents.onClientQuestState, true )
    --addEventHandler( EClientEvents.onClientQuestState, localPlayer, onQuestStateChanged, false )
    addEvent( EClientEvents.onClientQuestVar, true )
    --addEventHandler( EClientEvents.onClientQuestVar, localPlayer, onQuestVarChanged, false )
    addEvent( EClientEvents.onClientQuestCreate, true )
    --addEventHandler( EClientEvents.onClientQuestCreate, localPlayer, onQuestCreated, false )
end