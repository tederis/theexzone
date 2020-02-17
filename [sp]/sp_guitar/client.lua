function testReplace()
    local col = engineLoadCOL ( "models/guitar.col" )
    local txd = engineLoadTXD ( "models/guitar.txd", true )
	local dff = engineLoadDFF ( "models/guitar.dff" )

    if txd and dff and col then
        engineReplaceCOL ( col, 321 )
		engineImportTXD ( txd, 321 )
		engineReplaceModel ( dff, 321, false )
    end
    
    local ifp = engineLoadIFP( "models/guitar.ifp", "guitar" )
    if not ifp then
        outputDebugString( "Ошибка загрузки анимации guitar", 2 )
    end
end

--[[
    Init
]]
--addEventHandler( "onClientResourceStart", resourceRoot,
addEvent( "onClientCoreStarted", false )
addEventHandler( "onClientCoreStarted", root,
    function()
		--[[loadstring( exports[ "xrcore" ]:xrSettingsGetInline() )()
		xrIncludeModule( "config.lua" )
        xrIncludeModule( "player.lua" )
        xrIncludeModule( "global.lua" )  ]]

        testReplace()
    end
, false )