DOMAIN_NEW = 1
DOMAIN_DESTROY = 2
DOMAIN_INIT = 3
DOMAIN_PURGE = 4
DOMAIN_AGENT_NEW = 5
DOMAIN_AGENT_REMOVE = 6
DOMAIN_AGENT_START_SYNC = 7
DOMAIN_AGENT_STOP_SYNC = 8

TIMER_RES_100 = 0.1
TIMER_RES_500 = 0.5
TIMER_RES_1000 = 1
TIMER_RES_3000 = 3
TIMER_RES_5000 = 5
TIMER_RES_10000 = 10
TIMER_RES_60000 = 60

TIMER_RESOLUTIONS = {
    0.1, 0.5, 1, 3, 5, 10, 60
}

xrDomains = {

}

xrPedAgents = {

}

xrPedDomains = {

}

xrSyncablePeds = {

}

--[[
    Engine
]]
local function onUpdate( dt )
    dt = dt / 1000  
    
    for _, domain in pairs( xrDomains ) do
        domain:update( dt )
    end
end

local function onTimer( res )
    for _, ped in ipairs( xrSyncablePeds ) do
        local agent = xrPedAgents[ ped ]
        if agent and agent.simulating then
            agent:onTimer( res )
        end
    end
end

function xrNetCreateAgent( domain, packet )
    local agentType = packet[ 1 ]
    local ped = packet[ 2 ]
    local powerExpense = packet[ 3 ]
    local relaxationSpeed = packet[ 4 ]
    local remoteAction = packet[ 5 ]

    local agent = DogBrain:create( agentType, ped, domain )
    if agent then
        agent.powerExpense = powerExpense
        agent.relaxationSpeed = relaxationSpeed        

        domain:insert( ped, agent )

        xrPedAgents[ ped ] = agent
        xrPedDomains[ ped ] = domain

        if remoteAction then
            agent:setRemoteEvent( remoteAction )
        end

        outputDebugString( "Client: Агент создан" )
    else
        outputDebugString( "Client: При создании агента произошла ошибка" )
    end
end

function xrNetDestroyAgent( domain, ped )
    domain:remove( ped )

    xrPedAgents[ ped ] = nil
    xrPedDomains[ ped ] = nil
    table.removeValue( xrSyncablePeds, ped )

    outputDebugString( "Client: Агент удален" )
end

function xrNetStartSync( domain, ped, packet )
    domain:startSync( ped, packet )
    table.insert( xrSyncablePeds, ped )
end

function xrNetStopSync( domain, ped )
    domain:stopSync( ped )
    table.removeValue( xrSyncablePeds, ped )
end

function xrNetCreateDomain( packet )
    local domainType = packet[ 1 ]
    local id = packet[ 2 ]
    local x, y, z = packet[ 3 ], packet[ 4 ], packet[ 5 ]
    local radius = packet[ 6 ]

    -- Возможно зона была создана прежде
    if xrDomains[ id ] then
        return
    end

    local domain = DogDomain:create( domainType, Vector3( x, y, z ), radius )
    if domain then
        domain.id = id

        for _, agentPacket in ipairs( packet[ 7 ] ) do
            xrNetCreateAgent( domain, agentPacket )
        end

        xrDomains[ id ] = domain

        outputDebugString( "Client: Зона " .. id .. " создана" )
    else
        outputDebugString( "Client: При создании зоны " .. tostring( id ) .. " произошла ошибка" )
    end
end

function xrNetDestroyDomain( id )
    local domain = xrDomains[ id ]
    if domain then
        for ped, _ in pairs( domain.agents ) do
            xrNetDestroyAgent( domain, ped )
        end

        domain:destroy()
        xrDomains[ id ] = nil

        outputDebugString( "Client: Зона " .. id .. " удалена" )
    end
end

local function onDomainEvent( packetType, arg, arg2 )
    if packetType == DOMAIN_NEW then
        xrNetCreateDomain( arg )
    elseif packetType == DOMAIN_DESTROY then
        xrNetDestroyDomain( arg )
    elseif packetType == DOMAIN_INIT then
        for _, domainPacket in ipairs( arg ) do
            xrNetCreateDomain( domainPacket )
        end
    elseif packetType == DOMAIN_PURGE then
        for id, domain in pairs( xrDomains ) do
            xrNetDestroyDomain( id )
        end
    elseif packetType == DOMAIN_AGENT_NEW then
        local domain = xrDomains[ arg ]
        if domain then
            xrNetCreateAgent( domain, arg2 )
        else
            --outputDebugString( "Зоны с таким ID не существует! (" .. tostring( arg ) .. ")", 2 )
        end
    elseif packetType == DOMAIN_AGENT_REMOVE then
        local domain = xrDomains[ arg ]
        if domain then
            xrNetDestroyAgent( domain, source )
        else
            --outputDebugString( "Зоны с таким ID не существует! (" .. tostring( arg ) .. ")", 2 )
        end
    elseif packetType == DOMAIN_AGENT_START_SYNC then
        local domain = xrDomains[ arg ]
        if domain then
            xrNetStartSync( domain, source, arg2 )
        else
            --outputDebugString( "Зоны с таким ID не существует! (" .. tostring( arg ) .. ")", 2 )
        end
    elseif packetType == DOMAIN_AGENT_STOP_SYNC then
        local domain = xrDomains[ arg ]
        if domain then
            xrNetStopSync( domain, source )
        else
            --outputDebugString( "Зоны с таким ID не существует! (" .. tostring( arg ) .. ")", 2 )
        end
    end
end

local function onPedDamage( attacker, weapon, bodypart, loss )
    if isElementStreamedIn( source ) then
        local agent = xrPedAgents[ source ]

        -- Если мы симулируем поведение агента - говорим ему об уроне
        if agent and agent.simulating then
            if not agent:onDamage( attacker, weapon, bodypart, loss ) then
                cancelEvent()
            end

        -- Если мы не синхронизируем педа - всегда отменяем урон
        elseif not isElementSyncer( source ) and ( getElementHealth( source ) - loss ) > 5 then
            cancelEvent()
        end
    end
end

local function onPlayerWeaponFire( weapon, ammo, ammoInClip, hitX, hitY, hitZ )
    if weapon <= 9 then
        return
    end    

    local hitPos = Vector3( hitX, hitY, hitZ )

    -- Если мы симулируем поведение агента - говорим ему о выстреле игрока
    for _, ped in ipairs( xrSyncablePeds ) do
        local agent = xrPedAgents[ ped ]
        if agent and agent.simulating then
            agent:onPerception( hitPos )
        end
    end
end

--[[local function onPedWasted( killer, killerWeapon, bodypart, stealth )
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onWasted( killer, killerWeapon, bodypart )
    end
end]]

local function onElementStreamIn()
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onStreamIn()
    end
end

local function onElementStreamOut()
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onLostSyncer()
    end
end

local function onAgentLostSyncer()
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onLostSyncer()
    end
end

local function onAgentRemoteEvent( actionHash )
    local agent = xrPedAgents[ source ]
    if agent then
        agent:setRemoteEvent( actionHash )
    end
end

local function onAgentWasted( killer, killerWeapon, bodypart )
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onWasted( killer, killerWeapon, bodypart )
    end
end

--[[
    Debug
]]
if G_DEBUG then
    addEventHandler( "onClientKey", root,
        function( button, pressed )
            if button ~= "z" then
                return
            end

            showCursor( pressed )
        end
    , false )

    addEventHandler( "onClientClick", root,
        function( button, state, ax, ay )
            if not isCursorShowing() then
                return
            end

            local ox, oy, oz = getWorldFromScreenPosition( ax, ay, 1 )
            local ex, ey, ez = getWorldFromScreenPosition( ax, ay, 100 )

            local hit, hx, hy, hz, hitElement = processLineOfSight( ox, oy, oz, ex, ey, ez, false, false, true, false )
            if hit and hitElement then
                local targetAgent = xrPedAgents[ hitElement ]
                if targetAgent then
                    setDebugTargetAgent( targetAgent )
                end
            end
        end
    , false )
end

--[[
    Только на период закрытых тестов
]]
function testReplace()
    local txd = engineLoadTXD ( "models/army.txd", true )
	local dff = engineLoadDFF ( "models/army.dff" )
	
	if txd and dff then
		engineImportTXD ( txd, 55 )
		engineReplaceModel ( dff, 55, false )
	else
		outputDebugString( "Ошибка загрузки скина 55", 2 )
    end
    
    local ifp = engineLoadIFP( "models/dog.ifp", "dog" )
    if not ifp then
        outputDebugString( "Ошибка загрузки анимации dog", 2 )
    end

    --[[
        Dog strong
    ]]
    txd = engineLoadTXD ( "models/wmoice.txd", true )
	dff = engineLoadDFF ( "models/wmoice.dff" )
	
	if txd and dff then
		engineImportTXD ( txd, 56 )
		engineReplaceModel ( dff, 56, false )
	else
		outputDebugString( "Ошибка загрузки скина 56", 2 )
    end
    
    ifp = engineLoadIFP( "models/dog2.ifp", "dog2" )
    if not ifp then
        outputDebugString( "Ошибка загрузки анимации dog2", 2 )
    end
end

--[[
    Init
]]
--addEventHandler( "onClientResourceStart", resourceRoot,
addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
    function()
		loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )

        if not xrSettingsInclude( "characters/stalkers.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end

        if not xrSettingsInclude( "ai/domains.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end

        if not xrSettingsInclude( "ai/agents.ltx" ) then
			outputDebugString( "Ошибка загрузки конфигурации!", 2 )
			return
        end
       
        defineAnimations()
        defineSounds()
        defineRemoteActions()

        for _, res in ipairs( TIMER_RESOLUTIONS ) do
            setTimer( onTimer, res * 1000, 0, res )
        end

        testReplace()

        addEvent( EClientEvents.onClientDomainEvent, true )
        addEventHandler( EClientEvents.onClientDomainEvent, resourceRoot, onDomainEvent )          
        addEventHandler( "onClientPreRender", root, onUpdate, false )
        addEventHandler( "onClientPlayerWeaponFire", root, onPlayerWeaponFire )
        addEventHandler( "onClientPedDamage", resourceRoot, onPedDamage )
        --addEventHandler( "onClientPedWasted", resourceRoot, onPedWasted )
        addEventHandler( "onClientElementStreamIn", resourceRoot, onElementStreamIn )
        addEventHandler( "onClientElementStreamOut", resourceRoot, onElementStreamOut )
        addEvent( EClientEvents.onClientAgentLostSyncer, true )
        addEventHandler( EClientEvents.onClientAgentLostSyncer, resourceRoot, onAgentLostSyncer )
        addEvent( EClientEvents.onClientAgentRemoteEvent, true )
        addEventHandler( EClientEvents.onClientAgentRemoteEvent, resourceRoot, onAgentRemoteEvent )
        addEvent( EClientEvents.onClientAgentWasted, true )
        addEventHandler( EClientEvents.onClientAgentWasted, resourceRoot, onAgentWasted )
    end
, false )