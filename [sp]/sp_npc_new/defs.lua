local IS_CLIENT = type( triggerServerEvent ) == "function"

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

--[[
    Remote patterns
]]
RemotePatterns = {

}

local _defineRemotePatternName = ""
local _defineRemotePatternFn = function( tbl )
    local nameHash = _hashFn( _defineRemotePatternName )
    RemotePatterns[ _defineRemotePatternName ] = nameHash
    RemotePatterns[ nameHash ] = tbl 

    tbl.name = _defineRemotePatternName
end
local RemotePattern = function( name )
    _defineRemotePatternName = name
    return _defineRemotePatternFn
end

function defineRemoteAnims()
    RemotePattern "RemotePatternAttack" {
        startAnim = "anim_attack",
        startSnd = "snd_attack_hit"
    }

    RemotePattern "RemotePatternEat" {
        startAnim = "anim_eat",
        startSnd = "snd_eat",
        randSnd = { 
            name = "snd_eat", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternRunAfterPrey" {
        startAnim = "anim_run",
        randSnd = { 
            name = "snd_attack", period = 2, prob = 0.6 
        }
    }

    RemotePattern "RemotePatternRunAfterDog" {
        startAnim = "anim_run_slow",
        randSnd = { 
            name = "snd_idle", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternRunAfterBody" {
        startAnim = "anim_run_slow",
        randSnd = { 
            name = "snd_idle", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternWalk" {
        startAnim = "anim_walk"
    }

    RemotePattern "RemotePatternRunSlowly" {
        startAnim = "anim_run_slow"
    }

    RemotePattern "RemotePatternRun" {
        startAnim = "anim_run",
        randSnd = { 
            name = "snd_idle", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternRunAway" {
        startAnim = "anim_run",
        randSnd = { 
            name = "snd_panic", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternRunToward" {
        startAnim = "anim_run_slow",
        randSnd = { 
            name = "snd_growl", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternEscape" {
        startAnim = "anim_run",
        randSnd = { 
            name = "snd_panic", period = 2, prob = 0.4 
        }
    }

    RemotePattern "RemotePatternSeatDown" {
        startAnim = "anim_sit_down"
    }

    RemotePattern "RemotePatternSeat" {
        startAnim = "anim_sit"
    }

    RemotePattern "RemotePatternSeatUp" {
        startAnim = "anim_seat_up"
    }

    RemotePattern "RemotePatternStand" {
        startAnim = "anim_stand"
    }

    RemotePattern "RemotePatternHowl" {
        startAnim = "anim_howl",
        randSnd = { 
            name = "snd_howl", period = 2, prob = 0.4 
        }
    }
end

--[[
    RemoteActions
]]
RemoteActions = {

}

function RemoteActionDef( name )
    local nameHash = _hashFn( name )
    RemoteActions[ name ] = nameHash

    if IS_CLIENT then
        local def = _G[ name ]
        if type( def ) ~= "table" then
            outputDebugString( "Класса для действия " .. tostring( name ) .. " не существует!", 1 )
            return
        end
        
        RemoteActions[ nameHash ] = setmetatable( def, RemoteActionMT )
    end
end

function defineRemoteActions()
    RemoteActionDef( "ActionWalk" )
    RemoteActionDef( "ActionToward" )
    RemoteActionDef( "ActionAway" )
    RemoteActionDef( "ActionStatic" )
end