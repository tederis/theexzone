local function onPlayerInteract( targetElement )
    local typeHash = getElementData( targetElement, "int", false )    
    local classImpl = xrClasses[ typeHash ]
    if classImpl then
        classImpl:onUse( targetElement, client )
    end
end

--[[
    Initialization
]]
addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
        triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )

addEventHandler( "onCoreStarted", root,
--addEventHandler( "onResourceStart", resourceRoot,
    function()
        loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
        xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )
		
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

        addEvent( EServerEvents.onPlayerInteract, true )
        addEventHandler( EServerEvents.onPlayerInteract, root, onPlayerInteract )

        xrInitClasses() 
        
        initDrops()

        initGuitar()
    end
)