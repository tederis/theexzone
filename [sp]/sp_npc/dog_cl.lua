--[[
    ActionAttack
]]
ActionAttack = {
    name = "attack"
}
setmetatable( ActionAttack, ActionMT )
ActionAttackMT = {
    __index = ActionAttack
}

function ActionAttack:new( key )
    local action = Action:new()

    action.key = key

    setmetatable( action, ActionAttackMT )
    
    return action
end

function ActionAttack:update( dt )
    local controller = self.agent.controller
    local target = self.blackboard:getValue( self.key )

    if isElement( target ) then
        MovementPursuit_apply( controller, target )
    end
end

function ActionAttack:run()
    local ped = self.agent.ped
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local prey = self.blackboard:getValue( self.key )
        if prey then
            self:setTimer( ActionAttack.onTimerEvent, 1 )
            self.agent:triggerRemoteAction( RemoteActions.RemoteActionAttack )

            -- Убеждаемся что мы синхер и отправляем событие укуса на сервер
            if isElementSyncer( ped ) then
                triggerServerEvent( EServerEvents.onAgentAttack, ped, prey )
            end

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionAttack:stop( forced )
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_DEFERRED
    end

    return BEHAVIOR_FAILED
end

function ActionAttack:onStopped()    
    Action.onStopped( self )
end

function ActionAttack:onTimerEvent()
    -- Анимация закончилась - говорим об этом родительскому ноду
    local parent = self.parent
    parent:onChildFinish( self )
end

--[[
    ActionEat
]]
ActionEat = {
    name = "eat"
}
setmetatable( ActionEat, ActionMT )
ActionEatMT = {
    __index = ActionEat
}

function ActionEat:new()
    local action = Action:new()

    setmetatable( action, ActionEatMT )
    
    return action
end

function ActionEat:run()
    if Action.run( self ) == BEHAVIOR_OK then
        self.agent:triggerRemoteAction( RemoteActions.RemoteActionEat )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionEat:stop( forced )
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionEat:onStopped()    
    Action.onStopped( self )
end

--[[
    ActionMoveTo
]]
ActionMoveTo = {
    name = "moveTo"
}
setmetatable( ActionMoveTo, ActionMT )
ActionMoveToMT = {
    __index = ActionMoveTo
}

function ActionMoveTo:new( key, anim, reachDist )
    local action = Action:new()

    action.key = key
    action.anim = anim
    action.reachTest = true
    action.reachDistSqr = math.pow( tonumber( reachDist ) or 2, 2 )

    setmetatable( action, ActionMoveToMT )
    
    return action
end

function ActionMoveTo:setReachTest( enabled )
    self.reachTest = enabled
    return self
end

function ActionMoveTo:update( dt )
    local parent = self.parent
    local ped = self.agent.ped
    local controller = self.agent.controller
    local domain = self.agent.domain
    local target = self.blackboard:getValue( self.key )

    if isElement( target ) then
        MovementPursuit_apply( controller, target )
        MovementCircleRetaining_apply( controller, domain.position, domain.radius )

        if self.reachTest then
            local distSqr = ( getElementActualPosition( target ) - ped.position ):getSquaredLength()
            if distSqr <= self.reachDistSqr then
                parent:onChildFinish( self )
            end
        end
    end
end

function ActionMoveTo:run()
    local domain = self.agent.domain
    local ped = self.agent.ped
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local target = self.blackboard:getValue( self.key )
        if isElement( target ) then
            local distSqr = ( getElementActualPosition( target ) - ped.position ):getSquaredLength()
            if distSqr <= self.reachDistSqr and self.reachTest then
                return BEHAVIOR_FINISHED
            end
        else
            return BEHAVIOR_FAILED
        end

        self.agent:triggerRemoteAction( self.anim )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionMoveTo:stop( forced )
    if Action.stop( self, forced ) == BEHAVIOR_OK then        
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionMoveTo:onStopped()
    Action.onStopped( self )
end

--[[
    ActionWalk
]]
ActionWalk = {
    name = "walk"
}
setmetatable( ActionWalk, ActionMT )
ActionWalkMT = {
    __index = ActionWalk
}

function ActionWalk:new( anim )
    local action = Action:new()

    action.domain = domain
    action.anim = anim

    setmetatable( action, ActionWalkMT )
    
    return action
end

function ActionWalk:update( dt )
    local controller = self.agent.controller
    local domain = self.agent.domain

    MovementWander_apply( controller )
    MovementCircleRetaining_apply( controller, domain.position, domain.radius )
end

function ActionWalk:run()
    local parent = self.parent
    local ped = self.agent.ped
    local domain = self.agent.domain
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        self.agent:triggerRemoteAction( self.anim )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionWalk:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionWalk:onStopped()
    Action.onStopped( self )
end

--[[
    ActionRunAway
]]
ActionRunAway = {
    name = "run away"
}
setmetatable( ActionRunAway, ActionMT )
ActionRunAwayMT = {
    __index = ActionRunAway
}

function ActionRunAway:new( key, domain )
    local action = Action:new()

    action.key = key
    action.domain = domain

    setmetatable( action, ActionRunAwayMT )
    
    return action
end

function ActionRunAway:update( dt )
    local controller = self.agent.controller
    local domain = self.agent.domain
    local point = self.blackboard:getValue( self.key )

    if point then
        MovementFlee_apply( controller, point )
        MovementCircleRetaining_apply( controller, domain.position, domain.radius )
    end
end

function ActionRunAway:run()
    local parent = self.parent
    local blackboard = self.blackboard
    local ped = self.agent.ped
    local domain = self.domain
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local point = blackboard:getValue( self.key )
        if point then 
            self.agent:triggerRemoteAction( RemoteActions.RemoteActionRunAway )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionRunAway:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionRunAway:onStopped()
    local ped = self.agent.ped

    Action.onStopped( self )
end

--[[
    ActionRunToward
]]
ActionRunToward = {
    name = "run toward"
}
setmetatable( ActionRunToward, ActionMT )
ActionRunTowardMT = {
    __index = ActionRunToward
}

function ActionRunToward:new( key, domain )
    local action = Action:new()

    action.key = key
    action.domain = domain

    setmetatable( action, ActionRunTowardMT )
    
    return action
end

function ActionRunToward:update( dt )
    local controller = self.agent.controller
    local domain = self.agent.domain
    local point = self.blackboard:getValue( self.key )

    if point then
        MovementSeek_apply( controller, point )
        MovementCircleRetaining_apply( controller, domain.position, domain.radius )
    end
end

function ActionRunToward:run()
    local parent = self.parent
    local blackboard = self.blackboard
    local ped = self.agent.ped
    local domain = self.domain
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local point = blackboard:getValue( self.key )
        if point then
            self.agent:triggerRemoteAction( RemoteActions.RemoteActionRunToward )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionRunToward:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionRunToward:onStopped()
    local ped = self.agent.ped

    Action.onStopped( self )
end

--[[
    ActionEscape
]]
ActionEscape = {
    name = "escape"
}
setmetatable( ActionEscape, ActionMT )
ActionEscapeMT = {
    __index = ActionEscape
}

function ActionEscape:new( key, domain )
    local action = Action:new()

    action.key = key
    action.domain = domain

    setmetatable( action, ActionEscapeMT )
    
    return action
end

function ActionEscape:update( dt )
    local controller = self.agent.controller
    local domain = self.agent.domain
    local target = self.blackboard:getValue( self.key )

    if isElement( target ) then
        MovementEvading_apply( controller, target )
        MovementCircleRetaining_apply( controller, domain.position, domain.radius )
    end
end

function ActionEscape:run()
    if Action.run( self ) == BEHAVIOR_OK then
        local prey = self.blackboard:getValue( self.key )
        if prey then
            self.agent:triggerRemoteAction( RemoteActions.RemoteActionEscape )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionEscape:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionEscape:onStopped()
    Action.onStopped( self )
end

--[[
    ActionSeat
]]
local SEAT_STAGE_DOWN = 1
local SEAT_STAGE_IDLE = 2
local SEAT_STAGE_UP = 3

ActionSeat = {
    name = "seat"
}
setmetatable( ActionSeat, ActionMT )
ActionSeatMT = {
    __index = ActionSeat
}

function ActionSeat:new( brain )
    local action = Action:new()

    action.brain = brain
    action.stage = SEAT_STAGE_DOWN

    setmetatable( action, ActionSeatMT )
    
    return action
end

function ActionSeat:run()
    local ped = self.agent.ped

    if Action.run( self ) == BEHAVIOR_OK then
        self.stage = SEAT_STAGE_DOWN
        self:setTimer( ActionSeat.onTimerEvent, 2 )

        self.agent:triggerRemoteAction( RemoteActions.RemoteActionSeatDown )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionSeat:stop( forced )
    local stage = self.stage

    if Action.stop( self, forced ) == BEHAVIOR_OK then
        if stage ~= SEAT_STAGE_UP then
            self.stage = SEAT_STAGE_UP
            self:setTimer( ActionSeat.onTimerEvent, 1 )

            self.agent:triggerRemoteAction( RemoteActions.RemoteActionSeatUp )
        end      

        return BEHAVIOR_DEFERRED
    end

    return BEHAVIOR_FAILED
end

function ActionSeat:onStopped()
    Action.onStopped( self )
end

function ActionSeat:onTimerEvent()
    local parent = self.parent
    local stage = self.stage
    local ped = self.agent.ped

    if stage == SEAT_STAGE_DOWN then 
        self.stage = SEAT_STAGE_IDLE
        self.agent:triggerRemoteAction( RemoteActions.RemoteActionSeat )
    elseif stage == SEAT_STAGE_IDLE then
        -- RESERVED
    elseif stage == SEAT_STAGE_UP then
        parent:onChildFinish( self )
    end
end

--[[
    ActionStaticAnim
]]
ActionStaticAnim = {
    name = "static anim"
}
setmetatable( ActionStaticAnim, ActionMT )
ActionStaticAnimMT = {
    __index = ActionStaticAnim
}

function ActionStaticAnim:new( anim )
    local action = Action:new()

    action.anim = anim

    setmetatable( action, ActionStaticAnimMT )
    
    return action
end

function ActionStaticAnim:run()
    if Action.run( self ) == BEHAVIOR_OK then
        self.agent:triggerRemoteAction( self.anim )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionStaticAnim:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
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

    domain.col = createColCircle( position:getX(), position:getY(), radius )    

    return setmetatable( domain, DogDomainMT )
end

function DogDomain:destroy()
    for dogPed, dog in pairs( self.agents ) do
        dog:destroy()
    end

    destroyElement( domain.col )
end

function DogDomain:update( dt )
    for _, agent in pairs( self.agents ) do
        if agent.simulating then
            agent:onUpdate( dt )
        end
    end
end

function DogDomain:insert( ped, agent )
    -- Отключаем столкновения между агентами
    --[[for agentPed, agent in pairs( self.agents ) do
        setElementCollidableWith( ped, agentPed, false )
        setElementCollidableWith( agentPed, ped, false )
    end]]

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

        agent:simulate()
    end
end

function DogDomain:stopSync( ped )
    local agent = self.agents[ ped ]
    if agent then
        agent:stop()
    end
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

--[[
    DogBrain
]]
local MAX_PLAYER_DIST_SQR = 25*25
local HUNGER_SPEED = 0.005
local HUNGER_REST_SPEED = 0.02
local STAMINA_SPEED = 0.2
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

    local brain = {
        type = agentType,
        section = agentSection,
        ped = ped,
        domain = domain,


        simulating = false,
        dead = false,

        hunger = math.random(),
        energy = math.random(),
        anxiety = 0,

        vulnerable = false,

        powerExpense = math.interpolate( 0.5, 6, math.random() ),
        relaxationSpeed = math.interpolate( 0.2, 3, math.random() ),

        pursuers = {}
    }

    setmetatable( brain, DogBrainMT )

    --[[
        Если пед на момент создания агента мертв - задаем ему анимацию и выходим
    ]]
    if isPedDead( ped ) or getElementHealth( ped ) <= 1 then
        if isElementStreamedIn( ped ) then
            setElementCollisionsEnabled( ped, false )
            brain:playAnimation( "anim_die", true )
        end

        brain.dead = true

        return brain
    end    

    -- Контроллер управляет движениями и смешивает их
    local controller = PedController:create( ped )
    brain.controller = controller

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
    
    return brain
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
                            ActionMoveTo:new( "prey", RemoteActions.RemoteActionRunAfterPrey, 2 ) 
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
                local chaseAction = restOrWalkSelector:insert( ActionMoveTo:new( "target", RemoteActions.RemoteActionRunAfterDog ) ):setReachTest( false )
                chaseAction:insert( 
                    DecoratorBlackboard:new( "target" ) 
                ):setNotifyType( BLACKBOARD_VALUE_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH )
                chaseAction.name = "Chase dog[PLAY]"
            end

            -- Мы захотели побегать от других собачек
            do
                local runAction = restOrWalkSelector:insert( ActionWalk:new( RemoteActions.RemoteActionRunSlowly ) )
                runAction:insert( 
                    DecoratorBlackboard:new( "pursuers" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH ):setCallback( function( op ) return op and op > 0 end ):setDelay( 1 )
                runAction.name = "Run[PLAY]"
            end

            -- Собачка беспокоится о чем то?
            do
                local walk = restOrWalkSelector:insert( ActionWalk:new( RemoteActions.RemoteActionRunSlowly ) )
                walk:insert( 
                    DecoratorBlackboard:new( "anxiety" ) 
                ):setNotifyType( BLACKBOARD_RESULT_CHANGE ):setAbortType( BLACKBOARD_ABORT_BOTH ):setCallback( function( op ) return op and op > 0.3 and op < 0.7 end ):setDelay( 1 )
                walk.name = "Excited"
            end             
            
            -- Собачка сильно беспокоится о чем то?
            do
                local runAction = restOrWalkSelector:insert( ActionWalk:new( RemoteActions.RemoteActionRun ) )
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
                        ActionMoveTo:new( "body", RemoteActions.RemoteActionRunAfterBody, 1 ) 
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
                        ActionStaticAnim:new( RemoteActions.RemoteActionHowl ) 
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
                        ActionStaticAnim:new( RemoteActions.RemoteActionStand ) 
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
                    ActionWalk:new( RemoteActions.RemoteActionWalk ) 
                )
                walkAction.name = "Just walk"
            end
        end

        -- Обходим дерево и задаем индексы
        tree:traverse( 0 ) 
    end 
end

function DogBrain:destroy()
    self:stop()
end

function DogBrain:simulate()
    if self.dead or isPedActuallyDead( self.ped ) then
        setElementCollisionsEnabled( self.ped, false )
        self:playAnimation( "anim_die", true )

        return
    end

    if not self.simulating then
        -- Ставим дерево на выполнение
        if self.tree:run() == BEHAVIOR_OK then
            self.simulating = true

            outputDebugString( "Симуляция агента запущена" )
        else
            outputDebugString( "При запуске дерева поведения возникла проблема. Симуляция прервана." )
        end
    end
end

function DogBrain:stop()
    if self.simulating then
        local tree = self.tree

        -- Ставим дерево на останов
        tree:stop( true )

        -- Останавливаем вспомогательные системы
        self.blackboard:clear()
        self.time:reset()

        self.simulating = false

        -- Останавливаем агента
        if self.dead or isPedActuallyDead( self.ped ) then    
            setElementCollisionsEnabled( self.ped, false )
            self:playAnimation( "anim_die", true )    
        else
            self:playAnimation( "anim_stand" )
        end        

        outputDebugString( "Симуляция агента остановлена" )
    end
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

function DogBrain:triggerRemoteAction( actionHash )
    if self.simulating and isElementSyncer( self.ped ) and RemoteActions[ actionHash ] then
        triggerServerEvent( EServerEvents.onAgentRemoteEvent, self.ped, actionHash )
    end
end

function DogBrain:setRemoteEvent( actionHash )    
    if self.dead or isPedActuallyDead( self.ped ) then
        return
    end

    if isElementStreamedIn( self.ped ) then
        self:startRemoteEvent( actionHash )
    else
        self.remoteAction = actionHash
    end
end

function DogBrain:startRemoteEvent( actionHash )
    local lastAction = self.remoteAction
    if lastAction then
        RemoteActions[ lastAction ]:onStop( self )
    end

    local newAction = RemoteActions[ actionHash ]
    if newAction then
        newAction:onStart( self )
        self.remoteAction = actionHash
    else
        self.remoteAction = nil
    end
end

function DogBrain:onUpdate( dt )
    -- Обновляем таймеры
    self.time:update( dt )
    
    -- Обновляем контроллер и дерево поведения
    self.controller:beginFrame( dt )
    self.tree:update( dt )
    self.controller:endFrame( dt )    

    -- Обновляем текущее удаленное действие
    local remoteAction = self.remoteAction
    if remoteAction then
        RemoteActions[ remoteAction ]:onUpdate( self, dt )
    end

    if G_DEBUG then
        -- Терпимость к ранениям. При 1 агент не чувствует боли
        local injuryTolerance = tonumber( self.section.injury_tolerance ) or 0.3

        -- Порог наступления голода
        local hungerThreshold = tonumber( self.section.hunger_threshold ) or 0.7

        if getKeyState( "z" ) and not isPedActuallyDead( self.ped ) then
            local sx, sy = getScreenFromWorldPosition( self.ped.position )
            if sx then
                local tag = self.ped:getData( "dtag", false ) or ""
                dxDrawText( tag, sx, sy )

                dxDrawText( "Hunger: " .. self.hunger, sx, sy - 10 )
                dxDrawText( "Stamina: " .. self.energy, sx, sy - 20 )
                dxDrawText( "Anxiety: " .. self.anxiety, sx, sy - 30 )
                dxDrawText( "Health: " .. self.ped.health, sx, sy - 40 )
                dxDrawText( "Am I syncer? - " ..tostring( isElementSyncer( self.ped ) ), sx, sy - 50 )
                dxDrawText( "Speed: " .. ( self.ped.velocity:getLength() ), sx, sy - 60 )
                dxDrawText( "powerExpense: " .. self.powerExpense, sx, sy - 70 )
                dxDrawText( "relaxationSpeed: " .. self.relaxationSpeed, sx, sy - 80 )
                dxDrawText( "injuryTolerance: " .. injuryTolerance, sx, sy - 90 )
                dxDrawText( "hungerThreshold: " .. hungerThreshold, sx, sy - 100 )

                local i = 0
                for key, value in pairs( self.blackboard.keys ) do
                    dxDrawText( key .. " = " .. tostring( value.value ), sx, sy + 50 + 10*i )

                    i = i + 1
                end
            end
        end
    end
end

function DogBrain:onTimer( res )
    self.time:pulse( res )

    -- Обновляем с переменной частотой
    self:pulse( res )
end

function DogBrain:onWasted( killer, killerWeapon, bodypart )
    self.dead = true

    self:stop()

    setElementCollisionsEnabled( self.ped, false )
    self:playAnimation( "anim_die" )

    if isElementStreamedIn( self.ped ) then
        self:playSound( "snd_die" )
    end
end

function DogBrain:onLostSyncer()
    if self.dead or isPedActuallyDead( self.ped ) then
        setElementCollisionsEnabled( self.ped, false )
        self:playAnimation( "anim_die", true )    
    else
        self:playAnimation( "anim_stand" )
    end 
end

function DogBrain:onStreamIn()
    --[[
        Если на момент входа в стрим агент мертв - задаем соответствующую анимацию
    ]]
    if self.dead or isPedActuallyDead( self.ped ) then
        self.dead = true

        setElementCollisionsEnabled( self.ped, false )
        self:playAnimation( "anim_die" )

        return
    end

    --[[
        Если агент жив - оповещаем его о последнем сохраненном действии
    ]]
    if self.remoteAction then
        self:startRemoteEvent( self.remoteAction )
    else
        self:playAnimation( "anim_stand" )
    end
end

function DogBrain:pulse( dt )
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

function DogBrain:isContent()
    -- Если собачка уязвима - она не может быть довольна
    --[[if self.vulnerable then
        return false
    end]]
    
    -- Если есть добыча - нет времени для веселья
    --[[if self.prey then
        return false
    end]]

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

    -- Считаем кол-во сородичей, ведущих погоню за данной жертвой
    --[[local huntersNum = 0
    for _, agent in pairs( self.domain.agents ) do
        if agent.prey == prey then
            huntersNum = huntersNum + 1
        end
    end]]

    self.anxiety = 1
    self.blackboard:setValue( "anxiety", 1 )

    --[[
        Мы не должны позволять всей стае атаковать одну цель
        поэтому делаем проверку на кол-во атакующих
    ]]
    --if huntersNum <= 3 then
        self.prey = prey
        self.blackboard:setValue( "prey", prey )
    --[[else
        self.prey = false
        self.blackboard:setValue( "prey", false )
    end]]
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

    --outputDebugString( "Start pursuing " .. tostring( self.vulnerable ) .. ", " .. tostring( self.energy ) )
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

        --outputDebugString( "Stop pursuing " .. tostring( self.vulnerable ) .. ", " .. tostring( self.energy ) )
    end
end