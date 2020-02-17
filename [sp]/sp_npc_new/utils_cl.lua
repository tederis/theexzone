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

function processDeltaTime( dt, period, probability )
    local now = getCurrentTime()
    if ( now - dt ) % period > now % period then
        return math.random() <= probability
    end
    
    return false
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
    PerlinNoise
]]
local noisePattern = {
    -0.2006450695917,
    -0.66680242400616,
    -0.57575625646859,
    -0.87612858321518,
    -0.89170031249523,
    -0.44866901542991,
    -0.9044855106622,
    -0.3579336181283,
    -0.4545326307416,
    -0.26452634204179,
    -0.55526655819267,
    -0.56068608816713,
    -0.59652493428439,
    -0.91176854260266,
    -0.31215981673449,
    0.29530759342015,
    -0.70107179880142,
    -0.9406646406278,
    0.7569872662425,
    0.31083723250777,
    0.055287751369178,
    0.011713784188032,
    0.83138376288116,
    -0.62383012939245,
    -0.76168798375875,
    -0.88380649406463,
    0.4398575630039,
    0.27507007215172,
    0.76169187109917,
    -0.17588077764958,
    0.63186068087816,
    -0.4389531975612,
    0.15731679927558,
    -0.94389557559043,
    -0.31508178077638,
    0.26561648678035,
    -0.39256459102035,
    -0.21956729050726,
    0.90768286865205,
    0.15290277823806,
    0.51590636745095,
    -0.64758368954062,
    0.59221669007093,
    0.91938143316656,
    -0.55935223214328,
    -0.71994312666357,
    0.21468902658671,
    -0.26042403094471,
    -0.66060776729137,
    -0.028323707170784,
    -0.94958679843694,
    0.39467998407781,
    0.98339007701725,
    0.88179696444422,
    0.77084985468537,
    -0.77829790581018,
    0.99799047037959,
    0.21070741768926,
    0.49677216634154,
    0.75968234241009,
    -0.965173359029,
    0.12863284721971,
    -0.67927085515112,
    0.19214344024658,
    0.18473727162927,
    0.0056473640725017,
    -0.54224007297307,
    0.79217268060893,
    0.78608007356524,
    -0.63455720432103,
    -0.054924541153014,
    0.3019864410162,
    -0.28214089386165,
    -0.46270785108209,
    0.22136787418276,
    0.15850687399507,
    -0.18265097774565,
    -0.56394309923053,
    0.89808284305036,
    0.15674125496298,
    0.40773319453001,
    0.94849604554474,
    -0.44857876002789,
    0.39112327154726,
    0.83029300998896,
    -0.67772890534252,
    0.61282536573708,
    0.82828348129988,
    0.53297851327807,
    0.10959753207862,
    0.58796582370996,
    0.56780515424907,
    -0.76176962070167,
    0.90869496855885,
    -0.24005140550435,
    0.4229676509276,
    -0.08565766736865,
    0.21770852152258,
    0.21514033153653,
    -0.29957759287208
}
local noiseVerticesNum = 100

function getPerlinNoise( x )
    local decimal = math.floor( x )
    local value = noisePattern[ ( decimal % noiseVerticesNum ) + 1 ]
    local valueNext = noisePattern[ ( ( decimal + 1 ) % noiseVerticesNum ) + 1 ]
    local t = x - decimal

    local noise = value*(1-t) + valueNext*t

    return noise
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
        dt = 0
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

        self.angle = prevAngle + diffAngle*dt*5
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
    
    controller.force = controller.force + avoidance*6
end

--[[
    MovementWander
]]
local WANDER_CIRCLE_DIST = 4
local WANDER_CIRCLE_RADIUS = 1

function MovementWander_apply( controller, syncTime )
    local ped = controller.ped

    local time = getPerlinNoise( syncTime / 10000 )
    local nextAngle = time * math.pi

    local circleCenter = ped.velocity:getNormalized()
    circleCenter = circleCenter * WANDER_CIRCLE_DIST

    local displacement = Vector3( WANDER_CIRCLE_RADIUS * math.cos( nextAngle ), WANDER_CIRCLE_RADIUS * math.sin( nextAngle ), 0 )
    local steering = circleCenter + displacement   
    steering:normalize()

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