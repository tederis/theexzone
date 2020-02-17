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
end

function ActionAttack:run()
    local ped = self.agent.ped
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local prey = self.blackboard:getValue( self.key )
        if prey then
            self:setTimer( ActionAttack.onTimerEvent, 1 )
            triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, RemotePatterns.RemotePatternAttack, prey )

            self.agent:onAttack( prey )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionAttack:onPlayerJoin( player )
    local ped = self.agent.ped
    local prey = self.blackboard:getValue( self.key )

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, RemotePatterns.RemotePatternAttack, prey )
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
    local ped = self.agent.ped

    if Action.run( self ) == BEHAVIOR_OK then
        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, RemotePatterns.RemotePatternEat )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionEat:onPlayerJoin( player )
    local ped = self.agent.ped

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, RemotePatterns.RemotePatternEat )
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
        if self.reachTest then
            local distSqr = ( target.position - ped.position ):getSquaredLength()
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
            local distSqr = ( target.position - ped.position ):getSquaredLength()
            if distSqr <= self.reachDistSqr and self.reachTest then
                return BEHAVIOR_FINISHED
            end
        else
            return BEHAVIOR_FAILED
        end

        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, self.anim, target )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionMoveTo:onPlayerJoin( player )
    local ped = self.agent.ped
    local target = self.blackboard:getValue( self.key )

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, self.anim, target )
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
    action.randomShift = math.random() * 100

    setmetatable( action, ActionWalkMT )
    
    return action
end

function ActionWalk:update( dt )
end

function ActionWalk:run()
    local parent = self.parent
    local ped = self.agent.ped
    local domain = self.agent.domain
    local controller = self.agent.controller

    if Action.run( self ) == BEHAVIOR_OK then
        local now = getTickCount() + self.randomShift
        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionWalk, self.anim, now )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionWalk:onPlayerJoin( player )
    local ped = self.agent.ped

    do
        local now = getTickCount() + self.randomShift
        triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionWalk, self.anim, now )
    end
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
            triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionAway, RemotePatterns.RemotePatternRunAway, point:getX(), point:getY(), point:getZ() )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionRunAway:onPlayerJoin( player )
    local ped = self.agent.ped
    local point = blackboard:getValue( self.key )

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionAway, RemotePatterns.RemotePatternRunAway, point:getX(), point:getY(), point:getZ() )
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
            triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, RemotePatterns.RemotePatternRunToward, point:getX(), point:getY(), point:getZ() )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionRunToward:onPlayerJoin( player )
    local ped = self.agent.ped
    local point = blackboard:getValue( self.key )

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionToward, RemotePatterns.RemotePatternRunToward, point:getX(), point:getY(), point:getZ() )
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
end

function ActionEscape:run()
    local ped = self.agent.ped
    local prey = self.blackboard:getValue( self.key )

    if Action.run( self ) == BEHAVIOR_OK then
        if prey then
            triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionAway, RemotePatterns.RemotePatternEscape, prey )

            return BEHAVIOR_OK
        end
    end

    return BEHAVIOR_FAILED
end

function ActionEscape:onPlayerJoin( player )
    local ped = self.agent.ped
    local prey = self.blackboard:getValue( self.key )

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionAway, RemotePatterns.RemotePatternEscape, prey )
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

        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, RemotePatterns.RemotePatternSeatDown )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionSeat:onPlayerJoin( player )
    local ped = self.agent.ped

    local action = RemotePatterns.RemotePatternSeat
    if self.stage == SEAT_STAGE_DOWN then
        action = RemotePatterns.RemotePatternSeatDown
    elseif self.stage == SEAT_STAGE_UP then
        action = RemotePatterns.RemotePatternSeatUp
    end

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, action )
end

function ActionSeat:stop( forced )
    local ped = self.agent.ped
    local stage = self.stage

    if Action.stop( self, forced ) == BEHAVIOR_OK then
        if stage ~= SEAT_STAGE_UP then
            self.stage = SEAT_STAGE_UP
            self:setTimer( ActionSeat.onTimerEvent, 1 )

            triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, RemotePatterns.RemotePatternSeatUp )
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
        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, RemotePatterns.RemotePatternSeat )
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
    local ped = self.agent.ped

    if Action.run( self ) == BEHAVIOR_OK then
        triggerClientEvent( EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, self.anim )

        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end

function ActionStaticAnim:onPlayerJoin( player )
    local ped = self.agent.ped

    triggerClientEvent( player, EClientEvents.onClientRemoteAgentAction, ped, RemoteActions.ActionStatic, self.anim )
end

function ActionStaticAnim:stop( forced)
    if Action.stop( self, forced ) == BEHAVIOR_OK then
        return BEHAVIOR_OK
    end

    return BEHAVIOR_FAILED
end