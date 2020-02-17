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

function setPedAnimDef( ped, nameHash, progress )
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

        if type( progress ) == "number" then
            setPedAnimationProgress( ped, progress )
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

function playRandomSound3D( position, name, looped, startN, endN )
    local randName = name
    if type( startN ) == "number" and type( endN ) == "number" then
        randName = randName .. math.random( startN, endN )
    end
    return playSound3D( randName .. ".ogg", position, looped == true )
end

function playSndDef3D( position, nameHash, progress )
    local def = Sounds[ nameHash ]
    if def then
        local sound
        if def.rangeFrom and def.rangeTo then
            sound = playRandomSound3D( position, def.name, def.looped == true, def.rangeFrom, def.rangeTo )
        else
            sound = playSound3D(
                def.name,
                position,
                def.looped == true
            )
        end

        if sound then
            setSoundMinDistance( sound, tonumber( def.minDist ) or 5 )
            setSoundMaxDistance( sound, tonumber( def.maxDist ) or 20 )

            if type( progress ) == "number" then
                setSoundPosition( sound, getSoundLength( sound ) * progress )
            end
        end

        return sound
    end

    return false
end

function selectSndDef3D( nameHash )
    local def = Sounds[ nameHash ]
    if def then
        if def.rangeFrom and def.rangeTo then            
            return def.name .. math.random( def.rangeFrom, def.rangeTo ) .. ".ogg"
        end

        return def.name
    end

    return false
end

--[[
    Defs
]]
function defineAnimations()
    AnimDef "GuitarSeatDown" {
        block = "guitar",
        anim = "stand_sit",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "GuitarSeatUp" {
        block = "guitar",
        anim = "sit_stand",
        time = -1,
        loop = false,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = true,
        blendTime = 250
    }

    AnimDef "GuitarSeatPlay" {
        block = "guitar",
        anim = "guitar",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }

    AnimDef "GuitarSeat" {
        block = "guitar",
        anim = "sit",
        time = -1,
        loop = true,
        updatePosition = false,
        interruptable = false,
        freezeLastFrame = false,
        blendTime = 250
    }   
end

function defineSounds()
    SndDef "Guitar1" {
        name = "music/guitar_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar2" {
        name = "music/guitar_2.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar3" {
        name = "music/guitar_3.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar4" {
        name = "music/guitar_4.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar5" {
        name = "music/guitar_5.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar6" {
        name = "music/guitar_6.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar7" {
        name = "music/guitar_7.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar8" {
        name = "music/guitar_8.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar9" {
        name = "music/guitar_9.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar10" {
        name = "music/guitar_10.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar11" {
        name = "music/guitar_11.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar12" {
        name = "music/guitar_12.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar13" {
        name = "music/guitar_13.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar14" {
        name = "music/guitar_14.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar15" {
        name = "music/guitar_15.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "Guitar16" {
        name = "music/guitar_16.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "GuitarTest" {
        name = "music/test.mp3",
        minDist = 5,
        maxDist = 10
    }

    --[[
        Reactions
    ]]
    SndDef "StalkerReact1" {
        name = "music/reactions/stalker/reaction_music_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact2" {
        name = "music/reactions/stalker/reaction_music_2.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact3" {
        name = "music/reactions/stalker/reaction_music_3.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact4" {
        name = "music/reactions/stalker/reaction_music_4.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact5" {
        name = "music/reactions/stalker/reaction_music_5.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact6" {
        name = "music/reactions/stalker/reaction_music_6.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerReact7" {
        name = "music/reactions/stalker/reaction_music_7.ogg",
        minDist = 5,
        maxDist = 10
    }

    SndDef "BanditReact1" {
        name = "music/reactions/bandit/reaction_music_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact2" {
        name = "music/reactions/bandit/reaction_music_2.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact3" {
        name = "music/reactions/bandit/reaction_music_3.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact4" {
        name = "music/reactions/bandit/reaction_music_4.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact5" {
        name = "music/reactions/bandit/reaction_music_5.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact6" {
        name = "music/reactions/bandit/reaction_music_6.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditReact7" {
        name = "music/reactions/bandit/reaction_music_7.ogg",
        minDist = 5,
        maxDist = 10
    }

    --[[
        Jokes
    ]]
    SndDef "StalkerJoke1" {
        name = "jokes/stalker/joke_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke2" {
        name = "jokes/stalker/joke_2.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke3" {
        name = "jokes/stalker/joke_3.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke4" {
        name = "jokes/stalker/joke_4.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke5" {
        name = "jokes/stalker/joke_5.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke6" {
        name = "jokes/stalker/joke_6.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJoke7" {
        name = "jokes/stalker/joke_7.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJokeReact1" {
        name = "jokes/stalker/reaction_joke_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerJokeReact2" {
        name = "jokes/stalker/reaction_joke_2.ogg",
        minDist = 5,
        maxDist = 10
    }

    SndDef "BanditJoke1" {
        name = "jokes/bandit/joke_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke2" {
        name = "jokes/bandit/joke_2.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke3" {
        name = "jokes/bandit/joke_3.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke4" {
        name = "jokes/bandit/joke_4.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke5" {
        name = "jokes/bandit/joke_5.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke6" {
        name = "jokes/bandit/joke_6.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJoke7" {
        name = "jokes/bandit/joke_7.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJokeReact1" {
        name = "jokes/bandit/reaction_joke_1.ogg",
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditJokeReact2" {
        name = "jokes/bandit/reaction_joke_2.ogg",
        minDist = 5,
        maxDist = 10
    }

    --[[
        Combat commands
    ]]
    SndDef "StalkerCmdAttack" {
        name = "team_1/voice_attack_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdCamp" {
        name = "team_1/voice_camp_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdClear" {
        name = "team_1/voice_clear_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdFollow" {
        name = "team_1/voice_follow_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdHelp" {
        name = "team_1/voice_help_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdHold" {
        name = "team_1/voice_hold_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdMoney" {
        name = "team_1/voice_money_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdNo" {
        name = "team_1/voice_no_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdReport" {
        name = "team_1/voice_report_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdRetreat" {
        name = "team_1/voice_retreat_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdRoger" {
        name = "team_1/voice_roger_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdSilence" {
        name = "team_1/voice_silence_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "StalkerCmdTogether" {
        name = "team_1/voice_together_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }

    SndDef "BanditCmdAttack" {
        name = "team_2/voice_attack_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdCamp" {
        name = "team_2/voice_camp_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdClear" {
        name = "team_2/voice_clear_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdFollow" {
        name = "team_2/voice_follow_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdHelp" {
        name = "team_2/voice_help_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdHold" {
        name = "team_2/voice_hold_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdMoney" {
        name = "team_2/voice_money_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdNo" {
        name = "team_2/voice_no_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdReport" {
        name = "team_2/voice_report_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdRetreat" {
        name = "team_2/voice_retreat_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdRoger" {
        name = "team_2/voice_roger_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdSilence" {
        name = "team_2/voice_silence_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }
    SndDef "BanditCmdTogether" {
        name = "team_2/voice_together_",
        rangeFrom = 1,
        rangeTo = 3,
        minDist = 5,
        maxDist = 10
    }

    --[[
        Laughter
    ]]
    SndDef "StalkerLaughter" {
        name = "jokes/stalker/laughter_",
        rangeFrom = 1,
        rangeTo = 4,
        minDist = 5,
        maxDist = 10
    }

    SndDef "BanditLaughter" {
        name = "jokes/bandit/laughter_",
        rangeFrom = 1,
        rangeTo = 4,
        minDist = 5,
        maxDist = 10
    }
end