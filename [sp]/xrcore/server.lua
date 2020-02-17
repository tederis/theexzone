xrIncludeModule( "global.lua" )

xrCoreState = false

function onPlayerReady()
    triggerClientEvent( { client }, "onClientCoreResponse", client )
end

--[[
    Этап запуска
]]
addEvent( "onCoreStarted", false )
function onCoreStarted()
    outputDebugString( "Ядро успешно запущено" )

    triggerEvent( "onCoreStarted", root )

    addEvent( EServerEvents.onPlayerReady, true )
    addEventHandler( EServerEvents.onPlayerReady, root, onPlayerReady, true, "high+4" )

    xrCoreState = true
end

function onCoreStopped()
    removeEventHandler( EServerEvents.onPlayerReady, root, onPlayerReady )

    xrCoreState = false
end

--[[
    Этап инициализации
]]
local awaitResources = {

}
local awaitNum = 0

addEvent( "onCoreInitializing", false )
function onCoreInitializing()
    outputDebugString( "Этап инициализации" )

    xrCoreInit()

    awaitResources = {}
    awaitNum = 0

    -- Добавляем ресурсы к списку ожидаемых
    for resName, resMeta in pairs( g_ResourceNames ) do
        local res = getResourceFromName( resName )
        if res then           
            if not awaitResources[ resName ] and resMeta.awaitSignal then
                awaitResources[ resName ] = true
                awaitNum = awaitNum + 1
            end
        end
    end

    outputDebugString( "Ожидаем ответа от " .. awaitNum .. " ресурсов" )
    triggerEvent( "onCoreInitializing", root )
end

function xrCoreStart()
    outputDebugString( "Этап запуска" )

    for resName, resMeta in pairs( g_ResourceNames ) do
        local res = getResourceFromName( resName )
        if res then
            -- Запускаем ресурс если он не запущен
            if res.state == "loaded" then
                if not startResource( res ) then
                    outputDebugString( "Ошибка запуска ресурса " .. resName .. ". Цикл запуска прерван!", 1 )
                    return
                end
            end
        end
    end

    onCoreInitializing()
end

function xrCoreGetState()
    return xrCoreState
end

function xrCoreGetDB()
    return g_DB
end

function xrCoreInit()
    local userName = get( "db_user" )
    local userPassword = get( "db_pass" )

    g_DB = dbConnect( "mysql", "dbname=sp;host=127.0.0.1;charset=utf8", userName, userPassword )
    if not g_DB then
        outputDebugString( "Ошибка инициализация ядра: не удалось присоединиться к БД", 1 )
        return false
    end

    dbExec( g_DB, [[CREATE TABLE IF NOT EXISTS players( 
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
        name VARCHAR(64) NOT NULL, 
        password CHAR(60) NOT NULL, 
        donate INT, 
        date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP )]]
    )
    dbExec( g_DB, [[CREATE TABLE IF NOT EXISTS characters( 
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
        name VARCHAR(128) NOT NULL, 
        player_id INT UNSIGNED, 
        container_id INT UNSIGNED, 
        info TEXT,
        quests TEXT,
        faction BIGINT, 
        money INT, 
        donate INT, 
        rank INT, 
        reputation INT,
        skin INT,
        wanted INT,
        health FLOAT,
        armor FLOAT,
        date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP )]] )
    dbExec( g_DB, [[CREATE TABLE IF NOT EXISTS containers(
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        type BIGINT,
        lastId INT UNSIGNED,
        items TEXT)]] )
end

addEventHandler( "onResourceStart", root,
    function( startedResource )
        if startedResource == resource then
            xrCoreStart()
            return
        end
    end
)

addEvent( "onResourceInitialized", false )
addEventHandler( "onResourceInitialized", root,
    function( initializedRes )
        if awaitResources[ initializedRes.name ] then
            awaitResources[ initializedRes.name ] = nil
            awaitNum = awaitNum - 1

            if awaitNum == 0 then
                onCoreStarted()
            end
        end        
    end
)