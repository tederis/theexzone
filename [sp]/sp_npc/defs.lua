--[[
    Animations
]]
Animations = {

}
local _defineAnimName
local _defineAnim = function( data )
    local nameHash = _hashFn( _defineAnimName )

    data.hash = nameHash

    Animations[ _defineAnimName ] = nameHash
    Animations[ nameHash ] = data
end
local AnimDef = function( name )
    _defineAnimName = name
    return _defineAnim
end

function setPedAnimDef( ped, nameHash, lastFrame )
    local def = Animations[ nameHash ]
    if def then
        --[[local blockName, animData = getPedAnimation( ped )
        if blockName == def.block and animName == def.anim then
            return false
        end]]

        setPedAnimation( 
            ped, 
            def.block, 
            def.anim, 
            tonumber( def.time ) or -1, 
            def.loop == true,
            def.updatePosition == true,
            def.interruptable == true,
            def.freezeLastFrame == true,
            tonumber( def.blendTime ) or 250
        )

        if lastFrame then
            setPedAnimationProgress( ped, 1 )
        end

        return true
    end

    outputDebugString( "Анимация по такому хэшу не была найдена", 2 )
    return false
end

--[[
    Sounds
]]
Sounds = {

}
local _defineSndName
local _defineSnd = function( data )
    local nameHash = _hashFn( _defineSndName )

    data.hash = nameHash

    Sounds[ _defineSndName ] = nameHash
    Sounds[ nameHash ] = data
end
local SndDef = function( name )
    _defineSndName = name
    return _defineSnd
end

function playSndDef( nameHash )
    local def = Sounds[ nameHash ]
    if def then
        return playRandomSound( 
            def.name, 
            def.looped == true, 
            def.rangeFrom, 
            def.rangeTo 
        )
    end

    return false
end

function playSndDef3D( position, nameHash )
    local def = Sounds[ nameHash ]
    if def then
        local sound = playRandomSound3D(
            position,
            def.name, 
            def.looped == true, 
            def.rangeFrom, 
            def.rangeTo 
        )
        if sound then
            setSoundMinDistance( sound, tonumber( def.minDist ) or 5 )
            setSoundMaxDistance( sound, tonumber( def.maxDist ) or 20 )
        end

        return sound
    end

    return false
end

--[[
    Animation selectors
]]
AnimSelectors = {

}

--[[
    Defs
]]
function defineAnimations()
    AnimDef "DogAttack" {
        block = "dog",
        anim = "attack",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogRun" {
        block = "dog",
        anim = "run2",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogRunSlow" {
        block = "dog",
        anim = "run",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogWalk" {
        block = "dog",
        anim = "walk",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogSeatDown" {
        block = "dog",
        anim = "stand_seat",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogSeatIdle" {
        block = "dog",
        anim = "sit",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogSeatUp" {
        block = "dog",
        anim = "sit_stand",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogStretch" {
        block = "dog",
        anim = "stand",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogHowl" {
        block = "dog",
        anim = "lai",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogDie" {
        block = "dog",
        anim = "death",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogEat" {
        block = "dog",
        anim = "eat",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    --[[
        Dog strong
    ]]
    AnimDef "DogStrongAttack" {
        block = "dog2",
        anim = "attack",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogStrongRun" {
        block = "dog2",
        anim = "run2",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongRunSlow" {
        block = "dog2",
        anim = "run",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongWalk" {
        block = "dog2",
        anim = "walk",
        time = -1,
        loop = true,
        updatePosition = true,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongSeatDown" {
        block = "dog2",
        anim = "stand_seat",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogStrongSeatIdle" {
        block = "dog2",
        anim = "sit",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongSeatUp" {
        block = "dog2",
        anim = "sit_stand",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogStrongStretch" {
        block = "dog2",
        anim = "stand",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongHowl" {
        block = "dog2",
        anim = "lai",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "DogStrongDie" {
        block = "dog2",
        anim = "death",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "DogStrongEat" {
        block = "dog2",
        anim = "eat",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }
end

function defineSounds()
    SndDef "DogAttackHit" {
        name = "dog/attack_hit_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogAttack" {
        name = "dog/bdog_attack_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogHurt" {
        name = "dog/bdog_hurt_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogPanic" {
        name = "dog/bdog_panic_",
        rangeFrom = 0,
        rangeTo = 4,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogHowl" {
        name = "dog/bdog_howl_",
        rangeFrom = 0,
        rangeTo = 2,
        minDist = 5,
        maxDist = 250
    }

    SndDef "DogGrowl" {
        name = "dog/bdog_growl_",
        rangeFrom = 0,
        rangeTo = 2,
        minDist = 5,
        maxDist = 250
    }

    SndDef "DogIdle" {
        name = "dog/bdog_idle_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogDie" {
        name = "dog/bdog_die_",
        rangeFrom = 0,
        rangeTo = 2,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogEat" {
        name = "dog/bdog_eat_",
        rangeFrom = 0,
        rangeTo = 1,
        minDist = 5,
        maxDist = 100
    }

    --[[
        Dog strong
    ]]
    SndDef "DogStrongAttackHit" {
        name = "pseudodog/attack_hit_",
        rangeFrom = 0,
        rangeTo = 2,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongAttack" {
        name = "pseudodog/pdog_attack_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongHurt" {
        name = "pseudodog/pdog_hurt_",
        rangeFrom = 0,
        rangeTo = 1,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongPanic" {
        name = "pseudodog/pdog_aggression_",
        rangeFrom = 0,
        rangeTo = 1,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongHowl" {
        name = "pseudodog/pdog_howl_",
        rangeFrom = 0,
        rangeTo = 3,
        minDist = 5,
        maxDist = 250
    }

    SndDef "DogStrongGrowl" {
        name = "pseudodog/idle_",
        rangeFrom = 0,
        rangeTo = 1,
        minDist = 5,
        maxDist = 250
    }

    SndDef "DogStrongIdle" {
        name = "pseudodog/pdog_idle_",
        rangeFrom = 0,
        rangeTo = 4,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongDie" {
        name = "pseudodog/pdog_death_",
        rangeFrom = 0,
        rangeTo = 1,
        minDist = 5,
        maxDist = 100
    }

    SndDef "DogStrongEat" {
        name = "pseudodog/eat_",
        rangeFrom = 0,
        rangeTo = 0,
        minDist = 5,
        maxDist = 100
    }
end

local function processDeltaTime( dt, period, probability )
    local now = getCurrentTime()
    if ( now - dt ) % period > now % period then
        return math.random() <= probability
    end
    
    return false
end

RemoteActions = {

}

RemoteActionMT = {
    __index = {
        onStart = function()

        end,
        onStop = function()

        end,
        onUpdate = function()

        end
    }
}

local _defineRemoteActionName = ""
local _defineRemoteActionFn = function( tbl )
    tbl.name = _defineRemoteActionName
    local nameHash = _hashFn( _defineRemoteActionName )

    RemoteActions[ nameHash ] = setmetatable( tbl, RemoteActionMT )
    RemoteActions[ _defineRemoteActionName ] = nameHash  
end
local RemoteAction = function( name )
    _defineRemoteActionName = name
    return _defineRemoteActionFn
end

function defineRemoteActions()
    RemoteAction "RemoteActionAttack" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_attack" )
            agent:playSound( "snd_attack_hit" )
        end
    }

    RemoteAction "RemoteActionEat" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_eat" )
            agent:playSound( "snd_eat" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_eat" )
            end
        end
    }

    RemoteAction "RemoteActionRunAfterPrey" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.6 ) then
                agent:playSound( "snd_attack" )
            end
        end
    }

    RemoteAction "RemoteActionRunAfterDog" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run_slow" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_idle" )
            end
        end
    }

    RemoteAction "RemoteActionRunAfterBody" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run_slow" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_idle" )
            end
        end
    }

    RemoteAction "RemoteActionWalk" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_walk" )
        end
    }

    RemoteAction "RemoteActionRunSlowly" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run_slow" )
        end
    }

    RemoteAction "RemoteActionRun" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_idle" )
            end
        end
    }

    RemoteAction "RemoteActionRunAway" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_panic" )
            end
        end
    }

    RemoteAction "RemoteActionRunToward" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run_slow" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_growl" )
            end
        end
    }

    RemoteAction "RemoteActionEscape" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_run" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_panic" )
            end
        end
    }

    RemoteAction "RemoteActionSeatDown" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_sit_down" )
        end
    }

    RemoteAction "RemoteActionSeat" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_sit" )
        end
    }

    RemoteAction "RemoteActionSeatUp" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_seat_up" )
        end
    }

    RemoteAction "RemoteActionStand" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_stand" )
        end
    }

    RemoteAction "RemoteActionHowl" {
        onStart = function( self, agent )
            agent:playAnimation( "anim_howl" )
        end,
        onUpdate = function( self, agent, dt )
            if processDeltaTime( dt, 2, 0.4 ) then
                agent:playSound( "snd_howl" )
            end
        end
    }
end