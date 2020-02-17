PI_2 = math.pi * 2

function getDifference( b1, b2 )
    local r = ( b2 - b1 ) % PI_2
    if r < -math.pi then
        r = r + PI_2
    end
    if r >= math.pi then
        r = r - PI_2
    end

    return r
end

function getCurrentTime()
    local now = getTickCount()
    return now / 1000
end

function isPedActuallyDead( ped )
    return isPedDead( ped ) or getElementHealth( ped ) <= 1
end

local humanoidTypes = {
    [ "ped" ] = true,
    [ "player" ] = true
}
function getElementActualPosition( element )
    if humanoidTypes[ getElementType( element ) ] then
        return element:getBonePosition( 2 )
    else
        return element:getPosition()
    end
end

function playRandomSound( name, looped, startN, endN )
    local randName = "sounds/" .. name
    if type( startN ) == "number" and type( endN ) == "number" then
        randName = randName .. math.random( startN, endN )
    end
    return playSound( randName .. ".ogg", looped == true )
end

function playRandomSound3D( position, name, looped, startN, endN )
    local randName = "sounds/" .. name
    if type( startN ) == "number" and type( endN ) == "number" then
        randName = randName .. math.random( startN, endN )
    end
    return playSound3D( randName .. ".ogg", position, looped == true )
end

--[[
    Time
]]
local weakMT = {
    __mode = "k"
}

Time = {

}
TimeMT = {
    __index = Time
}

function Time:new()
    local time = {
        schedules = {},
        delays = {}
    }

    for _, res in ipairs( TIMER_RESOLUTIONS ) do
        time.schedules[ res ] = setmetatable( {}, weakMT )
    end

    return setmetatable( time, TimeMT )
end

function Time:reset()
    self.schedules = {}
    self.delays = setmetatable( {}, weakMT )

    for _, res in ipairs( TIMER_RESOLUTIONS ) do
        self.schedules[ res ] = setmetatable( {}, weakMT )
    end
end

function Time:pulse( res )
    local resTimers = self.schedules[ res ] or EMPTY_TABLE
    for owner, fn in pairs( resTimers ) do
        fn( owner, res )
    end
end

function Time:update( dt )
    local now = getCurrentTime()

    for owner, ownerDelays in pairs( self.delays ) do
        for fn, endTime in pairs( ownerDelays ) do
            if now >= endTime then
                fn( owner, dt )

                --[[
                    При выполнении fn мог быть задан новый таймер на той же функции
                    поэтому обязательно проверяем
                ]]
                endTime = ownerDelays[ fn ]
                if endTime and endTime <= now then
                    ownerDelays[ fn ] = nil
                end
            end
        end
    end
end

function Time:delay( owner, fn, duration )
    local now = getCurrentTime()

    local ownerDelays = self.delays[ owner ]
    if ownerDelays then
        ownerDelays[ fn ] = now + duration
    else
        self.delays[ owner ] = {
            [ fn ] = now + duration
        }
    end

    return true
end

function Time:undelay( owner, fn )
    -- Если функция не указана - удаляем все задержки на объекте
    if type( fn ) ~= "function" then
        self.delays[ owner ] = nil

        return true
    end

    local ownerDelays = self.delays[ owner ]
    if ownerDelays then
        ownerDelays[ fn ] = nil
    end

    return true
end

function Time:schedule( owner, fn, resolution )
    local resTimers = self.schedules[ resolution ]
    if resTimers then
        resTimers[ owner ] = fn
    else
        outputDebugString( "Недопустимое разрешение таймера( " .. tostring( resolution ) .. " )", 2 )
    end

    return true
end

function Time:unschedule( owner, resolution )
    -- Если явно указано разрешение
    if type( resolution ) == "number" then
        local resTimers = self.schedules[ resolution ]
        if resTimers then
            resTimers[ owner ] = nil

            return true
        end
    end

    -- Ищем по всем разрешениям
    for res, resTimers in pairs( self.schedules ) do
        if resTimers[ owner ] then
            resTimers[ owner ] = nil
        end
    end

    return true
end

--[[
    PedMovement
]]
PedController = {
    
}
PedController.apply = setmetatable( {}, { 
    __index = function( tbl, key )
        
    end 
} )

PedControllerMT = {
    __index = PedController
}

function PedController:create( ped )
    local forwardVec = ped.matrix:getForward()
    local angle = math.atan2( forwardVec:getY(), forwardVec:getX() )

    local controller = {
        ped = ped,
        movements = {},
        angle = angle,
        force = Vector3(),
        dt = 0,
        weight = math.interpolate( -5, 5, math.random() )
    }

    return setmetatable( controller, PedControllerMT )
end

function PedController:beginFrame( dt )
    local force = self.force
    force:setX( 0 )
    force:setY( 0 )
    force:setZ( 0 )

    self.dt = dt
end

function PedController:endFrame( dt )
    local ped = self.ped
    local velocity = ped.velocity
    local force = self.force        

    local nextVelocity = velocity + force
    if nextVelocity:getSquaredLength() > 0.003 then
        setElementRotation( ped, 0, 0, 90 - math.deg( self.angle ), "ZXY", true )

        local prevAngle = self.angle
        local nextAngle = math.atan2( nextVelocity:getY(), nextVelocity:getX() )
        local diffAngle = getDifference( prevAngle, nextAngle )

        self.angle = prevAngle + diffAngle*dt*3
    end     
end

--[[
    MovementCircleRetaining
]]
function MovementCircleRetaining_apply( controller, center, radius )
    local ped = controller.ped

    local centerDir = center - ped.position
    local affectFactor = math.max( 0, centerDir:getLength() - radius*0.9 )
    local avoidance = centerDir:getNormalized() * affectFactor
    
    controller.force = controller.force + avoidance*8
end

--[[
    MovementWander
]]
local WANDER_CIRCLE_DIST = 10
local WANDER_CIRCLE_RADIUS = 1

function MovementWander_apply( controller )
    local ped = controller.ped

    local time = ( getTickCount() % 8000 ) / 8000
    local speed = math.min( ped.velocity:getSquaredLength() * 10, 1 )
    local nextAngle = math.sin( time * PI_2 ) * PI_2 * controller.weight * speed

    local circleCenter = ped.velocity:getNormalized()
    circleCenter = circleCenter * WANDER_CIRCLE_DIST

    local displacement = Vector3( WANDER_CIRCLE_RADIUS * math.cos( nextAngle ), WANDER_CIRCLE_RADIUS * math.sin( nextAngle ), 0 )
    local steering = circleCenter + displacement   
    steering:normalize()

    controller.force = controller.force + steering
end

--[[
    MovementAround
]]
function MovementAround_apply( controller, center, radius )
    local ped = controller.ped

    local time = ( getTickCount() % 5000 ) / 5000
    local angle = time * math.pi * 2

    local displacement = Vector3( radius * math.cos( angle ), radius * math.sin( angle ), 0 )
    local circlePos = center + displacement
    local steering = circlePos - ped.position

    local len = steering:getLength()
    if len > 3 then
        steering = steering / len
        steering = steering * 3
    end

    controller.force = controller.force + steering
end

--[[
    MovementPursuit
]]
function MovementPursuit_apply( controller, target )
    local ped = controller.ped
    local pedPosition = ped.position
    local pedVelocity = ped.velocity
    local targetPosition = getElementActualPosition( target )
    local targetVelocity = target.velocity

    local futureTargetPosition = targetPosition + targetVelocity * ( controller.dt * 100 )
    local steering = futureTargetPosition - pedPosition

    controller.force = controller.force + steering

    if G_DEBUG then
        dxDrawLine3D( pedPosition, targetPosition, tocolor( 255, 0, 0 ), 4 )
    end
end

--[[
    MovementEvading
]]
function MovementEvading_apply( controller, target )
    local ped = controller.ped
    local pedPosition = ped.position
    local pedVelocity = ped.velocity
    local targetPosition = target.position
    local targetVelocity = target.velocity    
    
    local futureTargetPosition = targetPosition + targetVelocity * ( controller.dt * 100 )
    local steering = pedPosition - futureTargetPosition
    steering:normalize()
    steering = steering * 2

    controller.force = controller.force + steering
end

--[[
    MovementFlee
]]
function MovementFlee_apply( controller, point )
    local ped = controller.ped

    local steering = ped.position - point
    steering:normalize()
    steering = steering * 10

    controller.force = controller.force + steering
end

--[[
    MovementSeek
]]
function MovementSeek_apply( controller, point )
    local ped = controller.ped

    local steering = point - ped.position
    steering:normalize()
    steering = steering * 10

    controller.force = controller.force + steering
end