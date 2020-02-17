function PlayerAffector_applyBooster( player, itemHash )
    triggerClientEvent( player, EClientEvents.onClientApplyBooster, player, itemHash )
end

function PlayerAffector_applyItemAffects( player, itemHash, itemId )
    triggerClientEvent( player, EClientEvents.onClientApplyItemAffects, player, itemHash, itemId )
end

function PlayerAffector_removeItemAffects( player, itemHash, itemId )
    triggerClientEvent( player, EClientEvents.onClientRemoveItemAffects, player, itemHash, itemId )
end