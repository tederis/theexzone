--[[
	xrSound
	Отвечает за воспроизведение фоновой музыки,
	рандомных криков и замены мировых звуков
]]
xrSound = { }

local rndSounds = {
    "sounds/random/new_drone1.ogg",
    "sounds/random/new_drone2.ogg",
    "sounds/random/rnd_3dmbridge.ogg",
    "sounds/random/rnd_ak47_1.ogg",
    "sounds/random/rnd_ak47_2.ogg",
    "sounds/random/rnd_crow.ogg",
    "sounds/random/rnd_disgusting.ogg",
    "sounds/random/rnd_distantmortar3.ogg",
    "sounds/random/rnd_dog6.ogg",
    "sounds/random/rnd_drone1.ogg",
    "sounds/random/rnd_drone2.ogg",
    "sounds/random/rnd_fallscream.ogg",
    "sounds/random/rnd_horror3.ogg",
    "sounds/random/rnd_horror4.ogg",
    "sounds/random/rnd_m-16_3.ogg",
    "sounds/random/rnd_m-16_4.ogg",
    "sounds/random/rnd_m-249.ogg",
    "sounds/random/rnd_moan.ogg",
    "sounds/random/rnd_moan1.ogg",
    "sounds/random/rnd_moan2.ogg",
    "sounds/random/rnd_moan3.ogg",
    "sounds/random/rnd_moan4.ogg",
    "sounds/random/rnd_moan5.ogg",
    "sounds/random/rnd_scr1.ogg",
    "sounds/random/rnd_scr2.ogg",
    "sounds/random/rnd_scr3.ogg",
    "sounds/random/rnd_scr4.ogg",
    "sounds/random/rnd_scr5.ogg",
    "sounds/random/rnd_scr7.ogg",
    "sounds/random/rnd_scr8.ogg",
    "sounds/random/rnd_scr9.ogg",
    "sounds/random/rnd_scr10.ogg",
    "sounds/random/rnd_the_horror1.ogg",
    "sounds/random/rnd_the_horror2.ogg",
    "sounds/random/rnd_the_horror3.ogg",
    "sounds/random/rnd_the_horror4.ogg",
    "sounds/random/rnd_thunder.ogg",
    "sounds/random/rnd_wolfhowl01.ogg",
    "sounds/random/rnd_wolfhowl02.ogg",
    "sounds/random/rt_coo1-m.ogg",
    "sounds/random/rt_sickened1.ogg",
    "sounds/random/rt_sickened2.ogg",
    "sounds/random/rt_swamp_thing1.ogg",
}

function xrSound.init()
    if not xrSound.enabled then
        xrSound.music = playSound( "sounds/amb02_l.ogg", true )
        
        -- Отключаем звуки шагов
        setWorldSoundEnabled ( 41, false )

        addEventHandler( "onClientPreRender", root, xrSound.update, false )
        addEventHandler( "onClientPedStep", localPlayer, xrSound.onStep, false )
        
        xrSound.enabled = true
    end
end

function xrSound.stop()
    if xrSound.enabled then
        stopSound( xrSound.music )

        removeEventHandler ( "onClientPreRender", root, xrSound.update )
        removeEventHandler( "onClientPedStep", localPlayer, xrSound.onStep )

        xrSound.enabled = false
    end
end

local lastRndTime = getTickCount ( )
function xrSound.update()	
	--[[
		Рандомные звуки
	]]
	local now = getTickCount ( )
	if now - lastRndTime > math.random ( 50000, 120000 ) then
		lastRndTime = now
		
		local randSound = math.random ( 1, #rndSounds )
        local sound = playSound ( rndSounds[randSound], false )
        if sound then
            setSoundVolume ( sound, math.random ( 30, 80 ) / 200 )
        end
	end
end

function xrSound.onStep( left )
    local randSound = math.random ( 1, 4 )
    local sound = playSound ( "sounds/human/step/t_gravel" .. randSound .. ".ogg", false )
    setSoundVolume ( sound, math.random ( 10, 50 ) / 250 )
end

local function onGamemodeJoin()
    xrSound.init()
end

local function onGamemodeLeave()
    xrSound.stop()
end

addEventHandler( "onClientCoreStarted", root,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "global.lua" )  

        addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeJoin, localPlayer, onGamemodeJoin, false )
        addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeLeave, localPlayer, onGamemodeLeave, false )          
     end
)