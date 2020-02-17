local MIN_DIST_SQR = 2
local TEXT_COLOR = tocolor( 255, 255, 255 )
local sw, sh = guiGetScreenSize()

local activeElement = nil

local xrElements = {}

local humanoidTypes = {
    [ "ped" ] = true,
    [ "player" ] = true
}
local function getElementActualPosition( element )
    if humanoidTypes[ getElementType( element ) ] then
        return getPedBonePosition( element, 2 )
    else
        return getElementPosition( element )
    end
end

function xrInteractInsertElement( element )
    local interactHash = tonumber( getElementData( element, "int", false ) )
    if xrClasses[ interactHash ] then
        table.insert( xrElements, element )
    end
end

function xrInteractRemoveElement( element )
    table.removeValue( xrElements, element )
end

function xrGetNearestElements()
    return xrElements
end

function onTargetChange( prev, new )
    if isElement( new ) and not prev then
        triggerEvent( "onClientElementActionHit", new )
    elseif isElement( prev ) and not new then
        triggerEvent( "onClientElementActionLeave", prev )
    end
end

function onUpdatePulse()
    local posX, posY, posZ = getElementPosition( localPlayer )
    local minDistSqr = nil
    local minElement = nil

    for _, element in ipairs( xrGetNearestElements() ) do
        local elementPosX, elementPosY, elementPosZ = getElementActualPosition( element )
        local distSqr = ( posX - elementPosX )^2 + ( posY - elementPosY )^2 + ( posZ - elementPosZ )^2
        if not minDistSqr or distSqr < minDistSqr then
            minElement = element
            minDistSqr = distSqr
        end
    end

    -- Находим ближайший дроп
    local minDropElement, minDropDistSqr = getNearestDrop( posX, posY )
    if minDropElement and ( not minDistSqr or minDropDistSqr < minDistSqr ) then
        minElement = minDropElement
        minDistSqr = minDropDistSqr
    end

    -- Находим ближайший костер
    local firebinElement = exports.anomaly:xrGetPlayerZoneElement( localPlayer, EHashes.ZoneCampfire )
    if firebinElement then
        local x, y, z = getElementPosition( firebinElement )
        local firebinDistSqr = ( posX - x )^2 + ( posY - y )^2 + ( posZ - z )^2
        if not minDistSqr or firebinDistSqr < minDistSqr then
            minElement = firebinElement
            minDistSqr = firebinDistSqr
        end
    end

    if not minDistSqr or minDistSqr > MIN_DIST_SQR then
        minElement = nil
    end

    if minElement ~= activeElement then
        onTargetChange( activeElement, minElement )
        activeElement = minElement
    end  
end

function onRender()
    if not isElement( activeElement ) then
        return
    end

    local interactHash = getElementData( activeElement, "int", false )
    local classImpl = xrClasses[ interactHash ]
    if classImpl then
        if classImpl:isUsableClient( activeElement, localPlayer ) ~= true then
            return
        end

        local text = classImpl:getText( activeElement )
        dxDrawText( tostring( text ), 0, sh - 100, sw, sh, TEXT_COLOR, 1.6, "default", "center" )
    end
end

local _lastUseTime = getTickCount()
function onKey( button )
    if button ~= "e" then
        return
    end

    local now = getTickCount()
    if now - _lastUseTime < 800 then
        return
    end
    
    _lastUseTime = now

    -- Отсекаем выполнение при открытом чатбоксе, консоли или главном меню
    if isMTAWindowActive() then
        return
    end

    if not isElement( activeElement ) then
        return
    end

    local interactHash = getElementData( activeElement, "int", false )
    local classImpl = xrClasses[ interactHash ]
    if classImpl then
        if classImpl:isUsableClient( activeElement, localPlayer ) ~= true then
            return
        end        

        if not isElementLocal( activeElement ) then
            triggerServerEvent( EServerEvents.onPlayerInteract, localPlayer, activeElement )
        end

        classImpl:onClientUse( activeElement, localPlayer )
    end
end

local function onElementDestroy()
    xrInteractRemoveElement( source )
end

local function onPlayerGamodeJoin()
    if source ~= localPlayer then
        xrInteractInsertElement( source )
    end
end

local function onPlayerGamodeLeave()
    if source ~= localPlayer then
        xrInteractRemoveElement( source )
    end
end

local function onRadialMenuKey( _, state )
    if state == "down" then
        local team = getPlayerTeam( localPlayer )
        local teamName = team and getTeamName( team ) or EMPTY_STR
        xrRadialMenu:setVar( "Faction", teamName )

        local damageProof = getElementData( localPlayer, "damageProof", false )
        xrRadialMenu:setVar( "CombatPhase", damageProof ~= true )
        xrRadialMenu:setVar( "TestAbility", getElementData( localPlayer, "test", false ) )

        xrRadialMenu:show()
    else
        xrRadialMenu:hide()
    end
end

addEventHandler( "onClientCoreStarted", root,
--addEventHandler( "onClientResourceStart", resourceRoot,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "streamer.lua" )
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )
        xrIncludeModule( "locale.lua" )

        if not xrSettingsInclude( "zones/zones.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации аномалий!", 2 )
            return
		end
				
		if not xrSettingsInclude( "items_only.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации предметов!", 2 )
            return
        end

        if not xrSettingsInclude( "characters/stalkers.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации персонажей!", 2 )
            return
        end

        if not xrSettingsInclude( "environment/containers.ltx" ) then
            outputDebugString( "Ошибка загрузки конфигурации контейнеров!", 2 )
            return
        end      
        
        xrIncludeLocaleFile( "st_items_equipment" )
        xrIncludeLocaleFile( "st_items_weapons" )
        xrIncludeLocaleFile( "st_items_mutants" )
        xrIncludeLocaleFile( "st_items_artefacts" )
        xrIncludeLocaleFile( "st_items_outfit" )

        xrInitClasses()

        defineAnimations()
        defineSounds()

        initDrops()
        initGuitar()        
        
        setTimer( onUpdatePulse, 300, 0 )
        addEventHandler( "onClientRender", root, onRender, false )
        addEventHandler( "onClientElementDestroy", root, onElementDestroy )
        addEvent( EClientEvents.onClientPlayerGamodeJoin, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeJoin, root, onPlayerGamodeJoin )
        addEvent( EClientEvents.onClientPlayerGamodeLeave, true )
        addEventHandler( EClientEvents.onClientPlayerGamodeLeave, root, onPlayerGamodeLeave )

        for _, ped in ipairs( getElementsByType( "ped" ) ) do
            xrInteractInsertElement( ped )
        end

        local xml = xmlLoadFile( "radial.xml", true )
        if xml then
            xrRadialMenu:load( xml )

            xmlUnloadFile( xml )
        end    

        bindKey( "e", "down", onKey )
        bindKey( "q", "both", onRadialMenuKey )
    end
)