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

    domain.col = createColCircle( position:getX(), position:getY(), radius )

    setmetatable( domain, DogDomainMT )    

    return domain
end

function DogDomain:destroy()
    for ped, agent in pairs( self.agents ) do
        xrPedAgents[ ped ] = nil
        xrPedDomains[ ped ] = nil

        agent:destroy()
    end

    destroyElement( self.col )
end

function DogDomain:onPulse( dt )    
    local now = getTickCount()

    local agentsNum = 0
    for ped, agent in pairs( self.agents ) do
        if agent.simulating then
            if agent.syncerLostTime and now - agent.syncerLostTime > 10000 then
                agent:stop()
            else
                agent:update( dt )
            end
        end

        agentsNum = agentsNum + 1
    end

    -- Запрещаем спавн когда игрок рядом
    local players = getElementsWithinRange( self.position, 50, "player" )
    if #players > 1 then
        return
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
    setElementData( ped, "cl", self.section.agent_type, true )

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

        setElementSyncer( ped, true )
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
        agent.syncerLostTime = nil

        if not agent.simulating then
            agent:simulate()
        end

        local packet = agent:writeSyncPacket()
        triggerClientEvent( player, EClientEvents.onClientDomainEvent, ped, DOMAIN_AGENT_START_SYNC, self.id, packet )
    end
end

function DogDomain:onStopSync( ped, player )
    local agent = self.agents[ ped ]
    if agent then
        agent.syncer = false
        agent.syncerLostTime = getTickCount()

        if isElement( player ) then
            triggerClientEvent( player, EClientEvents.onClientDomainEvent, ped, DOMAIN_AGENT_STOP_SYNC, self.id )
        end
    end
end

--[[function DogDomain:onLostSyncer( ped )
    local agent = self.agents[ ped ]
    if agent then
        agent.syncer = false
    end
end]]

function DogDomain:onAgentWasted( agent, killer, killerWeapon, bodypart )
    exports.sp_player:xrAddPlayerRank( killer, 2 )

    agent:stop()
end

local DEFAULT_RANGE_FUNCTOR = function( element )
    return true
end
local DEAD_PLAYER_FUNCTOR = function( element )
    return getElementData( element, "fake", false ) == true
end

function DogDomain:getNearestElementInRange( center, range, fn, elementType )
    local minElement = false
    local minDistSqr = nil
    local rangeSqr = range*range
    local fn = fn or DEFAULT_RANGE_FUNCTOR

    for _, element in ipairs( getElementsWithinColShape( self.col, elementType ) ) do
        local distSqr = ( element.position - center ):getSquaredLength()
        if distSqr <= rangeSqr and ( not minDistSqr or distSqr < minDistSqr ) and fn( element ) then
            minDistSqr = distSqr
            minElement = element
        end
    end

    return minElement, math.sqrt( minDistSqr or 0 )
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

function DogDomain:onPostJoin( player )
    for ped, agent in pairs( self.agents ) do
        agent:onPostJoin( player )
    end
end

--[[
    DogBrain
]]
local MAX_PLAYER_DIST_SQR = 25*25
local HUNGER_SPEED = 0.005
local HUNGER_REST_SPEED = 0.02
local STAMINA_SPEED = 0.6
local STAMINA_REST_SPEED = 0.05
local ANXIETY_REST_SPEED = 0.01

local ZERO_VEC = Vector3( 0, 0, 0 )

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
        syncer = false,

        hunger = math.random(),
        energy = math.random(),
        anxiety = math.random(),

        powerExpense = powerExpense,
        relaxationSpeed = relaxationSpeed,

        pursuers = {}
    }
    
    setmetatable( brain, DogBrainMT )

    do
        -- Time управляем временем, задает задержки и планирует вызовы
        local time = Time:new()
        brain.time = time

        -- Доска хранит актуальные для дерева данные и отслеживает их изменение
        local blackboard = Blackboard:new()
        brain.blackboard = blackboard

        -- Непосредственно само дерево поведения
        local tree = BehaviorTree:new( blackboard, brain )
        brain.tree = tree
        
        -- Создаем логику для собаки
        brain:setupLogic()  
    end 
    
    return brain
end

function DogBrain:destroy()
    self:stop()
end

function DogBrain:setupLogic()
    local tree = self.tree
    if tree then
        local selector = tree:insert( Selector:new( "RootSelector") )

        -- Есть враг?
        do
            local hasEnemySelector = selector:insert( Selector:new( "EnemySelector") )
            hasEnemySelector:insert( 
                DecoratorBlackboard:new( "prey" ) 
            ):setNotifyType( BLACKBOARD_VALUE_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH )

            -- Уязвима ли сейчас собака?
            do 
                local hasRelativesSelector = hasEnemySelector:insert( Selector:new( "VulnerableSelector") )
                hasRelativesSelector:insert( 
                    DecoratorBlackboard:new( "vulnerable" )
                ):setInversed( true ):setAbortType( BLACKBOARD_ABORT_BOTH )

                do
                    local reachSeq = hasRelativesSelector:insert( Sequence:new( "ReachEnemySequence") )
                    
                    -- Бежим за жертвой
                    do
                        local chaseAction = reachSeq:insert( 
                            ActionMoveTo:new( "prey", RemotePatterns.RemotePatternRunAfterPrey, 2 ) 
                        )
                        chaseAction.name = "Chase pray"
                    end

                    -- Кусаем жертву
                    do
                        local bitAction = reachSeq:insert( 
                            ActionAttack:new( "prey" ) 
                        )
                        bitAction.name = "Attack prey"
                    end
                end
            end

            -- Если уязвима - убегаем поджав хвост
            do
                local escapeAction = hasEnemySelector:insert( 
                    ActionEscape:new( "prey", domain )
                )
                escapeAction:insert( 
                    DecoratorTimeLimit:new( 5 ) 
                )
                escapeAction.name = "Escape"
            end
        end

        -- Врага нет - гуляем или сидим
        do
            local restOrWalkSelector = selector:insert( Selector:new( "RunSelector") )

            -- Нам кто-то нанес урон?
            do
                local spotSelector = restOrWalkSelector:insert( Selector:new( "HasSpot?") )
                spotSelector:insert( 
                    DecoratorBlackboard:new( "spotPos" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH )

                -- У нас достаточно сил и здоровья чтобы бежать к врагу
                do
                    local seekAction = spotSelector:insert( ActionRunToward:new( "spotPos", domain )  )
                    seekAction:insert( 
                        -- Выжидаем 10 секунд перед сл. трапезой
                        DecoratorCooldown:new( 10 ) 
                    )
                    seekAction:insert( 
                        DecoratorBlackboard:new( "vulnerable" )
                    ):setInversed( true ):setAbortType( BLACKBOARD_ABORT_BOTH ):setDelay( 0.5 )
                    seekAction.name = "Look for enemy"
                end

                -- Мы слабы и нужно бежать от врага
                do
                    local fleeAction = spotSelector:insert( ActionRunAway:new( "spotPos", domain )  )
                    fleeAction.name = "Run away"
                end
            end            

            -- Мы захотели побегать за другой собачкой
            do
                local chaseAction = restOrWalkSelector:insert( ActionMoveTo:new( "target", RemotePatterns.RemotePatternRunAfterDog ) ):setReachTest( false )
                chaseAction:insert( 
                    DecoratorBlackboard:new( "target" ) 
                ):setNotifyType( BLACKBOARD_VALUE_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH )
                chaseAction.name = "Chase dog[PLAY]"
            end

            -- Мы захотели побегать от других собачек
            do
                local runAction = restOrWalkSelector:insert( ActionWalk:new( RemotePatterns.RemotePatternRunSlowly ) )
                runAction:insert( 
                    DecoratorBlackboard:new( "pursuers" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH ):setCallback( function( op ) return op and op > 0 end ):setDelay( 1 )
                runAction.name = "Run[PLAY]"
            end

            -- Собачка беспокоится о чем то?
            do
                local walk = restOrWalkSelector:insert( ActionWalk:new( RemotePatterns.RemotePatternRunSlowly ) )
                walk:insert( 
                    DecoratorBlackboard:new( "anxiety" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH ):setCallback( function( op ) return op and op > 0.3 and op < 0.7 end ):setDelay( 1 )
                walk.name = "Excited"
            end             
            
            -- Собачка сильно беспокоится о чем то?
            do
                local runAction = restOrWalkSelector:insert( ActionWalk:new( RemotePatterns.RemotePatternRun ) )
                runAction:insert( 
                    DecoratorBlackboard:new( "anxiety" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH ):setCallback( function( op ) return op and op > 0.7 end ):setDelay( 1 )
                runAction.name = "Alarmed"
            end 

            -- Мы захотели покушать
            do
                local eatSeq = restOrWalkSelector:insert( Sequence:new( "Eat sequence") )
                eatSeq:insert( 
                    -- Выжидаем 45 секунд перед сл. трапезой
                    DecoratorCooldown:new( 25 ) 
                )
                eatSeq:insert( 
                    DecoratorTimeLimit:new( math.random( 10, 25 ) )
                )
                eatSeq:insert( 
                    DecoratorBlackboard:new( "body" ) 
                ):setNotifyType( BLACKBOARD_VALUE_CHANGE ):setAbortType( BLACKBOARD_ABORT_SELF )
                eatSeq:insert( 
                    DecoratorBlackboard:new( "hunger" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_NONE ):setCallback( function( op ) return op and op > 0.7 end ):setDelay( 1 )
                
                -- Бежим к трупу
                do
                    local chaseAction = eatSeq:insert( 
                        ActionMoveTo:new( "body", RemotePatterns.RemotePatternRunSlowly, 1 ) 
                    )
                    chaseAction.name = "Go dinner"
                end

                -- Кусаем труп
                do
                    local eatAction = eatSeq:insert( 
                        ActionEat:new() 
                    )
                    eatAction.name = "Eat flesh"
                end
            end
              
            
            -- Мы захотели отдохнуть
            do
                local seatOrStandSelector = restOrWalkSelector:insert( Selector:new( "SeatOrStand") )
                seatOrStandSelector:insert( 
                    -- Проверяем на количество энергии. Если собачка полна сил - ей незачем отдыхать
                    DecoratorBlackboard:new( "energy" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_LOW_PRIORITY ):setCallback( function( op ) return op and op < 0.4 end ):setDelay( 1 )

                -- Посидим
                do
                    local seatAction = seatOrStandSelector:insert( 
                        ActionSeat:new( brain ) 
                    )
                    seatAction:insert( 
                        DecoratorTimeLimit:new( math.random( 10, 30 ) ) 
                    )
                    seatAction:insert( 
                        DecoratorCooldown:new( 60 ) 
                    )
                    seatAction.name = "Seat"
                end

                -- Повоим
                do
                    local standAction = seatOrStandSelector:insert( 
                        ActionStaticAnim:new( RemotePatterns.RemotePatternHowl ) 
                    )
                    standAction:insert( 
                        DecoratorTimeLimit:new( 6 )
                    )
                    standAction:insert( 
                        DecoratorCooldown:new( 25 ) 
                    )
                    standAction.name = "Howl"
                end

                -- Постоим
                do
                    local standAction = seatOrStandSelector:insert( 
                        ActionStaticAnim:new( RemotePatterns.RemotePatternStand ) 
                    )
                    standAction:insert( 
                        DecoratorTimeLimit:new( 8 ) 
                    )
                    standAction:insert( 
                        DecoratorCooldown:new( 7 ) 
                    )
                    standAction.name = "Stand"
                end
            end          

            -- Мы захотели походить
            do
                local walkSeq = restOrWalkSelector:insert( Sequence:new( "WantWalk") )      
                walkSeq:insert( 
                    DecoratorTimeLimit:new( 5 )
                )               
                local walkAction = walkSeq:insert( 
                    ActionWalk:new( RemotePatterns.RemotePatternWalk ) 
                )
                walkAction.name = "Just walk"
            end
        end

        -- Обходим дерево и задаем индексы
        tree:traverse( 0 ) 
    end 
end

function DogBrain:simulate()
    if self.dead then
        return
    end

    if not self.simulating then
        -- Ставим дерево на выполнение
        if self.tree:run() == BEHAVIOR_OK then
            self.simulating = true
            self.syncerLostTime = nil

            outputDebugString( "Симуляция агента запущена" )
        else
            outputDebugString( "При запуске дерева поведения возникла проблема. Симуляция прервана." )
        end
    end
end

function DogBrain:stop()
    if self.simulating then
        self.tree:stop( true )

        -- Останавливаем вспомогательные системы
        self.blackboard:clear()
        self.time:reset()

        self.syncerLostTime = nil
        self.simulating = false
        
        self.prey = nil
        self.spotTime = nil
        self.spotPos = nil
        self.vulnerable = false
        self.target = nil
        self.pursuers = {}

        outputDebugString( "Симуляция агента остановлена" )
    end
end

function DogBrain:onTimer( res )
    if self.simulating then
        self.time:pulse( res )
    end
end

function DogBrain:update( dt )
    local ped = self.ped
    local position = ped.position
    local velocity = ped.velocity
    local blackboard = self.blackboard
    local domain = self.domain
    local tree = self.tree
    local currentAction = tree.action
    local now = getCurrentTime()
    local agentSection = self.section    

    -- Терпимость к ранениям. При 1 агент не чувствует боли
    local injuryTolerance = tonumber( agentSection.injury_tolerance ) or 0.3

    -- Порог наступления голода
    local hungerThreshold = tonumber( agentSection.hunger_threshold ) or 0.7

    do
        if currentAction and currentAction.name == "eat" then
            self.hunger = math.max( self.hunger - HUNGER_REST_SPEED*dt, 0 )
        else
            self.hunger = math.min( self.hunger + HUNGER_SPEED*dt, 1 )
        end

        local speed = velocity:getLength()
        if speed > 0.005 then
            self.energy = math.max( self.energy - speed*STAMINA_SPEED*dt*self.powerExpense, 0 )
        else
            self.energy = math.min( self.energy + STAMINA_REST_SPEED*dt, 1 )
        end

        if self.prey or self.target or #self.pursuers > 0 then
            self.anxiety = 1
        else
            self.anxiety = math.max( self.anxiety - ANXIETY_REST_SPEED*dt*self.relaxationSpeed, 0 )
        end

        blackboard:setValue( "hunger", self.hunger )
        blackboard:setValue( "energy", self.energy )
        blackboard:setValue( "anxiety", self.anxiety )
    end

    do
        local spotTime = self.spotTime
        if spotTime and now - spotTime > 5 then
            blackboard:setValue( "spotPos", false )
            self.spotTime = nil
            self.spotPos = nil
        end
    end

    --[[
        Находим ближайшую цель
    ]]
    local perceptionRadius = tonumber( agentSection.perception_radius ) or 14
    local minPlayer, minPlayerDist = domain:getNearestElementInRange( position, perceptionRadius, DEFAULT_RANGE_FUNCTOR, "player" )
    if minPlayer ~= self.prey then
        if not minPlayer or getElementData( minPlayer, "ai_invisible", false ) ~= true then
            self:setPrey( minPlayer )
        end
    end

    --[[
        Задаем уязвимость
    ]]
    local allies = domain:getAgentsInRange( ped.position, perceptionRadius, self )
    local peaceful = self.hunger < hungerThreshold
    local unhealthy = getElementHealth( ped ) < ( 1 - injuryTolerance ) * 100
    local vulnerable = unhealthy or ( peaceful and #allies == 0 )

    -- Если атакующий находится за пределами зоны - убегаем от него
    if not vulnerable and self.spotTime and self.spotPos and not domain:isPointInside( self.spotPos ) then
        vulnerable = true
    end

    self.vulnerable = vulnerable
    blackboard:setValue( "vulnerable", vulnerable )
    
    --[[
        Собачка счастлива - а значит хочет развлекаться!
    ]]
    if self:isContent() then
        local minDog = false
        local minDogDistSqr = nil

        for _, dog in ipairs( allies ) do
            local distSqr = ( dog.ped.position - position ):getSquaredLength()
            if distSqr < 5 and ( not minDogDistSqr or distSqr < minDogDistSqr ) then
                minDogDistSqr = distSqr
                minDog = dog
            end
        end

        if minDog and not self.target and #self.pursuers == 0 then
            -- Если вторая собачка тоже счастлива - почему бы им не побегать друг за другом?
            if minDog:isContent() then
                self:startPursuing( minDog )
            end
        end
    else
        if self.target then
            self:stopPursuing()
        end
    end  

    --[[
        Собачка голодна и ищет трупик
    ]]
    if self.hunger >= hungerThreshold then
        local deadPlayer, deadPlayerDist = domain:getNearestElementInRange( position, 18, DEAD_PLAYER_FUNCTOR, "ped" )

        if not deadPlayer then
            deadPlayer, deadPlayerDist = domain:getNearestElementInRange( position, 18, function(op) return getElementHealth(op) <= 1 end, "ped" )
        end

        blackboard:setValue( "body", deadPlayer )
    end

    -- Обновляем таймеры
    self.time:update( dt )
    self.tree:update( dt )
end

function DogBrain:isContent()
    -- Терпимость к ранениям. При 1 агент не чувствует боли
    local injuryTolerance = tonumber( self.section.injury_tolerance ) or 0.3
    if getElementHealth( self.ped ) < ( 1 - injuryTolerance ) * 100 then
        return false
    end

    -- В иных случаях, если энергии достаточно можно и поиграть
    if self.energy > 0.2 then
        return true
    end

    return false
end

function DogBrain:setPrey( prey )
    -- Прекращаем преследование
    self:stopPursuing() 

    -- Забываем про точку
    self.spotTime = nil
    self.blackboard:setValue( "spotPos", false )

    self.anxiety = 1
    self.blackboard:setValue( "anxiety", 1 )

    self.prey = prey
    self.blackboard:setValue( "prey", prey )
end

function DogBrain:startPursuing( dog )
    -- Забываем про точку
    self.spotTime = nil
    self.blackboard:setValue( "spotPos", false )

    do
        self.blackboard:setValue( "target", dog.ped )
        self.target = dog
    end
    
    do
        table.insertIfNotExists( dog.pursuers, self )
        dog.blackboard:setValue( "pursuers", #dog.pursuers )
    end
end

function DogBrain:stopPursuing()
    local dog = self.target
    if dog then
        do
            self.blackboard:setValue( "target", false )
            self.target = false
        end

        do
            table.removeValue( dog.pursuers, self )
            dog.blackboard:setValue( "pursuers", #dog.pursuers )        
        end
    end
end

function DogBrain:onDamage( attacker, weapon, bodypart, loss )
    local blackboard = self.blackboard
    local domain = self.domain

    -- Запоминаем место, откуда был нанесен урон
    self.spotTime = getCurrentTime()
    self.spotPos = attacker.position
    blackboard:setValue( "spotPos", attacker.position )

    -- Делаем собаку раздраженной
    self.anxiety = 1
    blackboard:setValue( "anxiety", 1 )

    --[[ 
        Если атакующий находится вне зоны досягаемости агента -
        игнонируем урон
    ]]
    if not domain:isPointInside( attacker.position ) then
        return false
    end

    -- Сопротивляемость к ранениям. При 1 агент бессмертен
    local injuryResistance = tonumber( self.section.injury_resistance ) or 0.45
    if math.random() < injuryResistance then
        return false
    end    

    return true
end

function DogBrain:onPerception( point )
    local distSqr = ( self.ped.position - point ):getSquaredLength()
    local anxiety = 1 - math.clamp( 0, 1, distSqr / 16 )

    -- Делаем собаку раздраженной
    self.anxiety = anxiety
    self.blackboard:setValue( "anxiety", anxiety )    
end

function DogBrain:onAttack( target )
    local multiplier = tonumber( self.section.attack_multiplier ) or 1

    triggerClientEvent( target, EClientEvents.onClientPlayerHit, target, PHT_STRIKE, 0.15 * multiplier, 3, false )
end

function DogBrain:writeSyncPacket()
    local packet = {
        
    }

    return packet
end

function DogBrain:writeBeginPacket()
    local packet = {
        self.type,
        self.ped
    }

    return packet
end

function DogBrain:onPostJoin( player )
    local currentAction = self.tree.action
    if currentAction then
        currentAction:onPlayerJoin( player )
    end
end