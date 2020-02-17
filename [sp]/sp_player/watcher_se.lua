local xrPlayerWatchers = {}

xrMoneyWatcher = {
    onMoneyChanged = function( self, newValue )

    end
}

local function xrWatcher_onPlayerMoneyChange( prevValue, newValue )

end

local function onSyncPulse()

end

function initWatcher()
    addEvent( "onPlayerMoneyChange", false )
    addEventHandler( "onPlayerMoneyChange", root, xrWatcher_onPlayerMoneyChange )

    setTimer( onSyncPulse, 1000, 0 )
end