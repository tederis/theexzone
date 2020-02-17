xrIncludeModule( "global.lua" )

--[[
    Response ticker
]]
addEvent( "onClientCoreResponse", true )

local _readyTimer = nil
local _onServerResponse = function()
    stopResponseTicker()
end
function startResponseTicker()    
    addEventHandler( "onClientCoreResponse", localPlayer, _onServerResponse, false )

    triggerServerEvent( EServerEvents.onPlayerReady, localPlayer )
    _readyTimer = setTimer( triggerServerEvent, 100, 100, EServerEvents.onPlayerReady, localPlayer )
end
function stopResponseTicker()
    if _readyTimer and isTimer( _readyTimer ) then
        killTimer( _readyTimer )
    end
    _readyTimer = nil

    removeEventHandler( "onClientCoreResponse", localPlayer, _onServerResponse )
end

--[[
    Core
]]
xrCoreState = false

addEvent( "onClientCoreStarted", false )
function onCoreStarted()
    -- Отправляем всем ресурсам сигнал о запуске ядра
    triggerEvent( "onClientCoreStarted", root )

    startResponseTicker()

    xrCoreState = true

    outputDebugString( "Клиентское ядро запущено" )
end

function onCoreStopped()
    stopResponseTicker()

    xrCoreState = false
end

local awaitResources = {

}
local awaitNum = 0

function xrCoreStart()
    awaitResources = {}
    awaitNum = 0

    for resName, resMeta in pairs( g_ResourceNames ) do
        local res = getResourceFromName( resName )
        if res then
            if res.state == "loaded" then
                if not awaitResources[ resName ] and resMeta.awaitSignal then
                    awaitResources[ resName ] = true
                    awaitNum = awaitNum + 1
                end
            elseif res.state == "starting" then
                if not awaitResources[ resName ] and resMeta.awaitSignal then
                    awaitResources[ resName ] = true
                    awaitNum = awaitNum + 1
                end
            end
        end
    end

    if awaitNum == 0 then
        onCoreStarted()
    end
end

function xrCoreGetState()
    return xrCoreState
end

addEventHandler( "onClientResourceStart", root,
    function( startedResource )
        if startedResource == resource then
            xrCoreStart()
            return
        end

        local resName = getResourceName( startedResource )
        if awaitResources[ resName ] then
            awaitResources[ resName ] = nil
            awaitNum = awaitNum - 1

            if awaitNum == 0 then
                onCoreStarted()
            end
        end
    end
)