--[[
    Имплементация логики для собачек
]]
xrPedAgents = {

}

xrPedDomains = {

}

--[[
    DogDomain
]]
DEFAULT_MAX_AGENT_NUM = 5

DogDomain = {
    
}
DogDomainMT = {
    __index = DogDomain
}

function DogDomain:create( domainType, position, radius, maxAgentNum )
    local domainSection = xrSettingsGetSection( domainType )
    if not domainSection then
        outputDebugString( "Секции для этого домена не существует!", 2 )
        return false
    end

    local domain = {
        type = domainType,
        section = domainSection,
        position = position,
        radius = radius,
        maxAgentNum = tonumber( maxAgentNum ) or DEFAULT_MAX_AGENT_NUM,
        agents = {}
    }    

    setmetatable( domain, DogDomainMT )    

    return domain
end

function DogDomain:destroy()
    for ped, agent in pairs( self.agents ) do
        xrPedAgents[ ped ] = nil
        xrPedDomains[ ped ] = nil

        agent:destroy()
    end
end

function DogDomain:onPulse()
    -- Запрещаем спавн когда игрок рядом
    local players = getElementsWithinRange( self.position, 50, "player" )
    if #players > 1 then
        return
    end

    local agentsNum = 0
    for ped, agent in pairs( self.agents ) do
        agentsNum = agentsNum + 1
    end

    if agentsNum < self.maxAgentNum then
        self:spawn()
    end
end

function DogDomain:spawn()
    local agentSection = xrSettingsGetSection( self.section.agent_type )
    if not agentSection then
        outputDebugString( "Секции для этого агента не существует!", 2 )
        return false
    end

    local ped = createPed( agentSection.model, self:getRandomPoint(), math.random() * 360 )
    if not ped then
        outputDebugString( "Ошибка при создании педа", 2 )
        return
    end

    setElementData( ped, "volatile", true )
    setElementSyncer( ped, true )

    local agent = DogBrain:create( self.section.agent_type, ped, self )
    if agent then
        self.agents[ ped ] = agent
        xrPedAgents[ ped ] = agent
        xrPedDomains[ ped ] = self

        triggerClientEvent( 
            EClientEvents.onClientDomainEvent, ped, 
            DOMAIN_AGENT_NEW, 
            self.id, 
            agent:writeBeginPacket() 
        )
    else

        -- Незачем хранить педа если он не был должным образом инициализирован
        destroyElement( ped )
    end
end

function DogDomain:remove( agent )
    local ped = agent.ped

    if self.agents[ ped ] then
        triggerClientEvent( EClientEvents.onClientDomainEvent, ped, DOMAIN_AGENT_REMOVE, self.id )

        agent:destroy()
        destroyElement( ped )

        self.agents[ ped ] = nil
        xrPedAgents[ ped ] = nil
        xrPedDomains[ ped ] = nil
    end
end

function DogDomain:onStartSync( ped, player )
    local agent = self.agents[ ped ]
    if agent then
        agent.syncer = player

        local packet = agent:writeSyncPacket()
        triggerClientEvent( player, EClientEvents.onClientDomainEvent, ped, DOMAIN_AGENT_START_SYNC, self.id, packet )
    end
end

function DogDomain:onStopSync( ped, player )
    local agent = self.agents[ ped ]
    if agent then
        agent.syncer = false

        if isElement( player ) then
            triggerClientEvent( player, EClientEvents.onClientDomainEvent, ped, DOMAIN_AGENT_STOP_SYNC, self.id )
        end
    end
end

function DogDomain:onAgentWasted( agent, killer, killerWeapon, bodypart )
    exports.sp_player:xrAddPlayerRank( killer, 2 )

    triggerClientEvent( EClientEvents.onClientAgentWasted, agent.ped, killer, killerWeapon, bodypart )
end

function DogDomain:getRandomPoint()
    local randRadius = math.interpolate( 1, self.radius, math.random() )
    local randAngle = ( math.random()*2 - 1 ) * math.pi

    -- Вычислим радиус-вектор
    local rvec = Vector3( 
        randRadius * math.cos( randAngle ), 
        randRadius * math.sin( randAngle ), 
        0 
    )
    local position = self.position + rvec

    return position
end

function DogDomain:writeBeginPacket()
    local packets = {}
    for ped, agent in pairs( self.agents ) do
        table.insert( packets, agent:writeBeginPacket() )
    end

    local packet = {
        self.type,
        self.id,
        self.position.x,
        self.position.y,
        self.position.z,
        self.radius,
        packets
    }
    
    return packet
end

--[[
    DogBrain
]]
DogBrain = {

}
DogBrainMT = {
    __index = DogBrain
}

function DogBrain:create( agentType, ped, domain )
    local agentSection = xrSettingsGetSection( agentType )
    if not agentSection then
        outputDebugString( "Секции для этого агента не существует!", 2 )
        return false
    end

    -- Расход сил. Чем выше - тем быстрее устает агент
    local powerExpense = math.interpolate( 
        tonumber( agentSection.power_expense_from ) or 0.5, 
        tonumber( agentSection.power_expense_to ) or 6, 
        math.random()
    )

    -- Скорость успокоения. Чем выше - тем быстрее агент забывает про тревогу
    local relaxationSpeed = math.interpolate( 
        tonumber( agentSection.relaxation_spd_from ) or 0.2, 
        tonumber( agentSection.relaxation_spd_to ) or 3,
        math.random()
    )    
    
    local brain = {
        type = agentType,
        section = agentSection,
        ped = ped,
        domain = domain,

        hunger = math.random(),
        energy = math.random(),
        anxiety = math.random(),

        powerExpense = powerExpense,
        relaxationSpeed = relaxationSpeed
    }
    
    setmetatable( brain, DogBrainMT )
    
    return brain
end

function DogBrain:destroy()
    
end

function DogBrain:update( dt )    

end

function DogBrain:onAttack( target )
    local multiplier = tonumber( self.section.attack_multiplier ) or 1

    triggerClientEvent( target, EClientEvents.onClientPlayerHit, target, PHT_STRIKE, 0.15 * multiplier, 3, false )
end

function DogBrain:onRemoteAction( actionHash )
    self.remoteAction = actionHash
end

function DogBrain:writeSyncPacket()
    local packet = {
        self.hunger,
        self.energy,
        self.anxiety
    }

    return packet
end

function DogBrain:onSyncDataReceive( packet )
    if type( packet ) ~= "table" or #packet ~= 3 then
        return
    end

    self.hunger = math.clamp( 0, 1, tonumber( packet[ 1 ] ) or self.hunger )
    self.energy = math.clamp( 0, 1, tonumber( packet[ 2 ] ) or self.energy )
    self.anxiety = math.clamp( 0, 1, tonumber( packet[ 3 ] ) or self.anxiety )
end

function DogBrain:writeBeginPacket()
    local packet = {
        self.type,
        self.ped,
        self.powerExpense,
        self.relaxationSpeed,
        self.remoteAction
    }

    return packet
end