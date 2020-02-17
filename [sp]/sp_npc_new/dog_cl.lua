RemoteActionMT = {
    __index = {
        update = function()

        end,
        run = function()

        end,
        stop = function()

        end
    }
}

--[[
    ActionWalk
]]
ActionWalk = {
    name = "walk"
}

function ActionWalk:update( agent, dt )
    local controller = agent.controller
    local domain = agent.domain
    local syncTime = agent:getBlackboard( "syncTime" )
    local startTime = agent:getBlackboard( "startTime" )

    local now = getTickCount()
    local elapsed = now - startTime
    local elapsedSync = syncTime + elapsed

    MovementWander_apply( controller, elapsedSync )
    MovementCircleRetaining_apply( controller, domain.position, domain.radius )
end

function ActionWalk:run( agent, pattern, syncTime )
    agent:applyPattern( pattern )
    agent:setBlackboard( "syncTime", syncTime + getPlayerPing( localPlayer ) )
    agent:setBlackboard( "startTime", getTickCount() )
end

function ActionWalk:stop( agent )
    
end

--[[
    ActionToward
]]
ActionToward = {
    name = "toward"
}

function ActionToward:update( agent, dt )
    local controller = agent.controller
    local domain = agent.domain
    local target = agent:getBlackboard( "target" )
    local point = agent:getBlackboard( "point" )

    if isElement( target ) then
        MovementPursuit_apply( controller, target )
    elseif point then
        MovementSeek_apply( controller, point )
    end

    MovementCircleRetaining_apply( controller, domain.position, domain.radius )
end

function ActionToward:run( agent, pattern, tx, ty, tz )
    agent:applyPattern( pattern )

    if isElement( tx ) then
        agent:setBlackboard( "target", tx )
    elseif type( tx ) == "number" and type( ty ) == "number" and ( tz ) == "number" then
        agent:setBlackboard( "point", Vector3( tx, ty, tz ) )
    end
end

function ActionToward:stop( agent )
    
end

--[[
    ActionAway
]]
ActionAway = {
    name = "away"
}

function ActionAway:update( agent, dt )
    local controller = agent.controller
    local domain = agent.domain
    local target = agent:getBlackboard( "target" )
    local point = agent:getBlackboard( "point" )

    if isElement( target ) then
        MovementEvading_apply( controller, target )
    elseif point then
        MovementFlee_apply( controller, point )
    end

    MovementCircleRetaining_apply( controller, domain.position, domain.radius )
end

function ActionAway:run( agent, pattern, tx, ty, tz )
    agent:applyPattern( pattern )

    if isElement( tx ) then
        agent:setBlackboard( "target", tx )
    elseif type( tx ) == "number" and type( ty ) == "number" and ( tz ) == "number" then
        agent:setBlackboard( "point", Vector3( tx, ty, tz ) )
    end
end

function ActionAway:stop( agent )

end

--[[
    ActionStatic
]]
ActionStatic = {
    name = "static"
}

function ActionStatic:run( agent, pattern )
    agent:applyPattern( pattern )
end

function ActionStatic:stop( agent )
  
end

--[[
    DogDomain
]]
SIGHT_VECTOR = Vector3( 0, 0, 100 )

DogDomain = {
    
}
DogDomainMT = {
    __index = DogDomain
}

function DogDomain:create( domainType, position, radius )
    local domainSection = xrSettingsGetSection( domainType )
    if not domainSection then
        outputDebugString( "Секции для этого домена не существует!", 2 )
        return false
    end

    local domain = {
        type = domainType,
        section = domainSection,
        agents = setmetatable( {}, { __mode = "kv" } ),
        position = position,
        radius = radius,
        radiusSqr = radius*radius
    }

    return setmetatable( domain, DogDomainMT )
end

function DogDomain:destroy()
    for dogPed, dog in pairs( self.agents ) do
        dog:destroy()
    end
end

function DogDomain:update( dt )
    for _, agent in pairs( self.agents ) do
        if agent.streamedIn then
            agent:onUpdate( dt )
        end
    end
end

function DogDomain:insert( ped, agent )
    self.agents[ ped ] = agent
end

function DogDomain:remove( ped )
    local agent = self.agents[ ped ]
    if agent then
        agent:destroy()

        self.agents[ ped ] = nil
    end
end

function DogDomain:startSync( ped, packet )
    local agent = self.agents[ ped ]
    if agent then
        local position = ped.position

        --[[
            Если агент оказался за пределами зоны
            возвращаем его
        ]]
        if not self:isElementInside( ped ) then
            position = self:getRandomPoint()
        end    

        --[[
            Сервер не знает точного местонахождения поверхности земли, поэтому синхронизатор должен сперва расположить педа на земле
        ]]
        local hit, x, y, z = processLineOfSight( position + SIGHT_VECTOR, position - SIGHT_VECTOR, false, false, false, true )
        if hit then
            setElementPosition( ped, x, y, z + 1 )
        end

        agent:onStartSync()
    end
end

function DogDomain:stopSync( ped )
    local agent = self.agents[ ped ]
    if agent then
        agent:onStopSync()
    end
end

function DogDomain:getAgentsInRange( center, range, ignoreAgent )
    local agents = {}

    for ped, agent in pairs( self.agents ) do
        if agent ~= ignoreAgent then
            local dist = ( ped.position - center ):getLength()
            if dist <= range then
                table.insert( agents, agent )
            end
        end
    end

    return agents
end

function DogDomain:getRandomPoint()
    local randRadius = math.interpolate( 1, self.radius, math.random() )
    local randAngle = ( math.random()*2 - 1 ) * math.pi

    --[[
        Вычислям точку в пространстве
    ]]
    local rvec = Vector3( 
        randRadius * math.cos( randAngle ), 
        randRadius * math.sin( randAngle ), 
        0 
    )
    local position = self.position + rvec

    return position
end

function DogDomain:isElementInside( element )
    local distSqr = ( element.position - self.position ):getSquaredLength()

    return distSqr <= self.radiusSqr
end

function DogDomain:isPointInside( point )
    local distSqr = ( point - self.position ):getSquaredLength()

    return distSqr <= self.radiusSqr
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

    local streamedIn = isElementStreamedIn( ped )

    local brain = {
        type = agentType,
        section = agentSection,
        ped = ped,
        domain = domain,
        dead = false,
        streamedIn = streamedIn,
        blackboard = {
            -- Сюда пишут действия свои переменные
        },
        lastHealth = getElementHealth( ped )
    }

    setmetatable( brain, DogBrainMT )

    --[[
        Если пед на момент создания агента мертв - задаем ему анимацию
    ]]
    if isPedActuallyDead( ped ) then
        if streamedIn then
            setElementCollisionsEnabled( ped, false )
            brain:playAnimation( "anim_die", true )
        end

        brain.dead = true
    else
        brain:playAnimation( "anim_stand" )
    end    

    -- Контроллер управляет движениями и смешивает их
    brain.controller = PedController:create( ped )
    
    return brain
end

function DogBrain:destroy()
    
end

function DogBrain:playAnimation( fieldName, lastFrame )
    local animHash = self.section[ fieldName ]
    if type( animHash ) == "number" then
        setPedAnimDef( self.ped, animHash, lastFrame )
    else
        outputDebugString( "Хэш анимации не был найден", 2 )
    end
end

function DogBrain:playSound( fieldName )
    local sndHash = self.section[ fieldName ]
    if type( sndHash ) == "number" then
        playSndDef3D( self.ped.position, sndHash )
    end
end

function DogBrain:setRemoteEvent( actionHash, ... )    
    if self.dead then
        return
    end

    if self.streamedIn then
        self:startRemoteEvent( actionHash, ... )
    else
        local newAction = RemoteActions[ actionHash ]
        if newAction then
            self.remoteAction = actionHash
            self.remoteActionArgs = { ... }
        else
            self.remoteAction = nil
            self.remoteActionArgs = nil
        end
    end
end

function DogBrain:startRemoteEvent( actionHash, ... )
    local lastAction = self.remoteAction
    if lastAction then
        RemoteActions[ lastAction ]:stop( self )
    end

    -- Clean the blackboard
    self.blackboard = {

    }

    local newAction = RemoteActions[ actionHash ]
    if newAction then
        newAction:run( self, ... )
        self.remoteAction = actionHash
        self.remoteActionArgs = { ... }
    else
        self.remoteAction = nil
        self.remoteActionArgs = nil
    end
end

function DogBrain:setBlackboard( key, value )
    self.blackboard[ key ] = value
end

function DogBrain:getBlackboard( key )
    return self.blackboard[ key ]
end

function DogBrain:applyPattern( patternHash )
    local pattern = RemotePatterns[ patternHash ]
    if pattern then
        if pattern.startAnim then
            self:playAnimation( pattern.startAnim )
        end
        if pattern.startSnd then
            self:playSound( pattern.startSnd )
        end

        self.remotePattern = pattern
    else
        self.remotePattern = nil
    end
end

function DogBrain:onUpdate( dt )  
    if self.dead then
        return
    end

    self.controller:beginFrame( dt )
    do
        local remoteAction = self.remoteAction
        if remoteAction then
            RemoteActions[ remoteAction ]:update( self, dt )
        end
    end
    self.controller:endFrame( dt ) 

    local pattern = self.remotePattern
    if pattern then
        local randSndMeta = pattern.randSnd
        if randSndMeta and processDeltaTime( dt, randSndMeta.period, randSndMeta.prob )  then
            self:playSound( randSndMeta.name )
        end
    end
end

function DogBrain:onWasted()
    self.dead = true    

    if self.streamedIn then
        setElementCollisionsEnabled( self.ped, false )
        self:playAnimation( "anim_die" )
        self:playSound( "snd_die" )
    end
end

function DogBrain:onDamage( attacker, weapon, bodypart, loss )
    if not self.dead then
        local injuryResistance = tonumber( self.section.injury_resistance ) or 0
        local delta = math.ceil( 10 * ( 1 - injuryResistance ) )
        local health = math.max( self.lastHealth - delta, 0 )

        --[[
            Производим серую проверок для избежания крэша игры
        ]]
        if self.lastHealth > 0 and getElementHealth( self.ped ) > 0 and not isPedDead( self.ped ) then
            setElementHealth( self.ped, health )
        end

        self.lastHealth = health
    end
end

function DogBrain:onStartSync()
    if self.remoteAction then
        self:startRemoteEvent( self.remoteAction, unpack( self.remoteActionArgs ) )
    else
        self:playAnimation( "anim_stand" )
    end
end

function DogBrain:onStopSync()

end

function DogBrain:onLostSyncer()
    
end

function DogBrain:onStreamIn()
    self.streamedIn = true

    --[[
        Если на момент входа в стрим агент мертв - задаем соответствующую анимацию
    ]]
    if self.dead then
        setElementCollisionsEnabled( self.ped, false )
        self:playAnimation( "anim_die" )

        return
    end

    --[[
        Если агент жив - оповещаем его о последнем сохраненном действии
    ]]
    self.lastHealth = getElementHealth( self.ped )

    if self.remoteAction then
        self:startRemoteEvent( self.remoteAction, unpack( self.remoteActionArgs ) )
    else
        self:playAnimation( "anim_stand" )
    end
end

function DogBrain:onStreamOut()
    self.streamedIn = false
end