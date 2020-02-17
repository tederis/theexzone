--[[
    Initialization
]]
addEvent( "onCoreInitializing", false )
addEventHandler( "onCoreInitializing", root,
    function()
		triggerEvent( "onResourceInitialized", resourceRoot, resource )
    end
, false )