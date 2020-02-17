PI_2 = math.pi * 2

DOMAIN_NEW = 1
DOMAIN_DESTROY = 2
DOMAIN_INIT = 3
DOMAIN_PURGE = 4
DOMAIN_AGENT_NEW = 5
DOMAIN_AGENT_REMOVE = 6
DOMAIN_AGENT_START_SYNC = 7
DOMAIN_AGENT_STOP_SYNC = 8

-- Будет инициализировано ниже
xrDomains = nil

function xrCreateDomain( domainType, x, y, z, radius, maxAgentNum )
    local domain = DogDomain:create( domainType, Vector3( x, y, z ), radius, maxAgentNum )
    if domain then
        local id = xrDomains:allocate()

        domain.id = id
        xrDomains[ id ] = domain

        triggerClientEvent( 
            EClientEvents.onClientDomainEvent, resourceRoot, 
            DOMAIN_NEW, 
            domain:writeBeginPacket()
        )
    end
end

function xrDestroyDomain( id )
    local domain = xrDomains[ id ]
    if domain then
        domain:destroy()
        xrDomains[ id ] = nil

        triggerClientEvent( EClientEvents.onClientDomainEvent, resourceRoot, DOMAIN_DESTROY, id )
    end
end

local function onAgentRemoteEvent( actionHash )
    if not RemoteActions[ actionHash ] then
        outputDebugString( "Принят неопознанный тип действия", 2 )
        return
    end

    local agent = xrPedAgents[ source ]
    if agent then
        agent:onRemoteAction( actionHash )

        triggerClientEvent( EClientEvents.onClientAgentRemoteEvent, source, actionHash )
    else
        outputDebugString( "Агента для данного педа не существует!", 2 )
    end
end

local function onPlayerEnterLevel()
    local packets = {}
    for _, domain in pairs( xrDomains ) do
        table.insert( packets, domain:writeBeginPacket() )
    end

    triggerClientEvent( source, EClientEvents.onClientDomainEvent, resourceRoot, DOMAIN_INIT, packets )
end

local function onPlayerLeaveLevel()        
    triggerClientEvent( source, EClientEvents.onClientDomainEvent, resourceRoot, DOMAIN_PURGE )
end

local function onElementStartSync( player )
    if not exports.sp_gamemode:xrIsPlayerJoined( player ) then
        return
    end
    
    local domain = xrPedDomains[ source ]
    if domain then
        domain:onStartSync( source, player )
    end
end

local function onElementStopSync( player )
    local domain = xrPedDomains[ source ]
    if domain then
        domain:onStopSync( source, player )
    end

    --[[
        Оцениваем количество возможных синхронизаторов 
        и оповещаем клиентских агентов если рядом нет кандидатов на эту роль
    ]]
    do
        local pedSyncerDistance = getServerConfigSetting( "ped_syncer_distance" )
        local syncerCandidates = getElementsWithinRange( source.position, pedSyncerDistance, "player" )
        for _, candidate in ipairs( syncerCandidates ) do
            if candidate ~= player then
                return
            end
        end

        triggerClientEvent( EClientEvents.onClientAgentLostSyncer, source )
    end
end

function _onPedWastedPoll( ped )
    --[[
        Если игрок копается в инвентаре педа или рядом есть игроки -
        ждем еще одну порцию времени
    ]]
    if exports.sp_inventory:xrGetElementRefsNum( ped ) > 0 or #getElementsWithinRange( ped.position, 100, "player" ) > 0 then
        setTimer( _onPedWastedPoll, 5000, 1, ped )

    -- В противном случае удаляем педа
    else
        local domain = xrPedDomains[ ped ]
        local agent = xrPedAgents[ ped ]
        if domain and agent then
            domain:remove( agent )
        end
    end
end
local function onPedWasted( totalAmmo, killer, killerWeapon, bodypart, stealth )
    local domain = xrPedDomains[ source ]
    local agent = xrPedAgents[ source ]
    if domain and agent then
        domain:onAgentWasted( agent, killer, killerWeapon, bodypart )

        -- Запускаем таймер на удаление
        setTimer( _onPedWastedPoll, 5000, 1, source )
    end
end

local function onPlayerGamodeJoin()
    for _, ped in ipairs( getElementsByType( "ped", resourceRoot ) ) do
        if getElementSyncer( ped ) == source then
            local domain = xrPedDomains[ ped ]
            if domain then
                domain:onStartSync( ped, source )
            end
        end
    end
end

local function onPlayerGamodeLeave()    
end

local function onUpdateLoop()
    for _, domain in pairs( xrDomains ) do
        domain:onPulse()
    end
end

local function onAgentAttack( target )
    local agent = xrPedAgents[ source ]
    if agent then
        agent:onAttack( target )
    end
end

--addEventHandler( "onResourceStart", resourceRoot,
addEvent( "onCoreStarted", false )
addEventHandler( "onCoreStarted", root,
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

        defineRemoteActions()

        xrDomains = xrMakeIDTable()

        addEvent( EServerEvents.onPlayerEnterLevel, false )
        addEventHandler( EServerEvents.onPlayerEnterLevel, root, onPlayerEnterLevel )
        addEvent( EServerEvents.onPlayerLeaveLevel, false )
        addEventHandler( EServerEvents.onPlayerLeaveLevel, root, onPlayerLeaveLevel )
        addEvent( EServerEvents.onPlayerGamodeJoin, false )
        addEventHandler( EServerEvents.onPlayerGamodeJoin, root, onPlayerGamodeJoin )
        addEvent( EServerEvents.onPlayerGamodeLeave, false )
        addEventHandler( EServerEvents.onPlayerGamodeLeave, root, onPlayerGamodeLeave )
        addEventHandler( "onElementStartSync", resourceRoot, onElementStartSync )
        addEventHandler( "onElementStopSync", resourceRoot, onElementStopSync )
        addEventHandler( "onPedWasted", resourceRoot, onPedWasted )
        addEvent( EServerEvents.onAgentAttack, true )
        addEventHandler( EServerEvents.onAgentAttack, resourceRoot, onAgentAttack )
        addEvent( EServerEvents.onAgentRemoteEvent, true )
        addEventHandler( EServerEvents.onAgentRemoteEvent, resourceRoot, onAgentRemoteEvent )

        setTimer( onUpdateLoop, 10000, 0 )

        -- Test only
        xrCreateDomain( EHashes.AIDomainSimple, -170, -65, 123, 40, 5 )
        xrCreateDomain( EHashes.AIDomainSimple, -85.503463745117, 38.542514801025, 120.02011871338, 20, 3 )
        xrCreateDomain( EHashes.AIDomainSimple, 32.696449279785, 379.35818481445, 128.09274291992, 18, 3 )
        xrCreateDomain( EHashes.AIDomainSimple, 91.395446777344, 540.31365966797, 127.70182800293, 22, 4 )
        xrCreateDomain( EHashes.AIDomainSimple, 224.84497070313, 302.30673217773, 128.31170654297, 40, 8 )
        xrCreateDomain( EHashes.AIDomainSimple, 302.65374755859, 113.41241455078, 129.46298217773, 40, 8 )
        xrCreateDomain( EHashes.AIDomainSimple, 281.94927978516, 22.276033401489, 140.75663757324, 15, 2 )
        xrCreateDomain( EHashes.AIDomainSimple, -71.055160522461, -221.77813720703, 105.12105560303, 18, 3 )

        
        xrCreateDomain( EHashes.AIDomainStrong, -75.768836975098, 113.47201538086, 124.49179840088, 10, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, 267.41494750977, 316.82211303711, 129.21485900879, 20, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, 315.52359008789, -1.8138076066971, 141.55006408691, 15, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, -87.918334960938, -307.95581054688, 93.018508911133, 20, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, 15.796907424927, 719.90679931641, 147.69743347168, 15, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, -163.22288513184, 175.96266174316, 160.22189331055, 30, 1 )
        xrCreateDomain( EHashes.AIDomainStrong, -216.75735473633, -451.94781494141, 102.22603607178, 20, 2 )
    end
, false )