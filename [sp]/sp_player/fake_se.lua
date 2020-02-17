local DESTROY_PERIOD = 1000 * 300
local DESTROY_REPEAT_PERIOD = 1000 * 30

function doPedDestroy( ped )
    -- Если элемент в текущий момент используется в сессии
    -- мы должны повторить попытку позже
    if exports.sp_inventory:xrGetElementRefsNum( ped ) > 0 then
        setTimer( doPedDestroy, DESTROY_REPEAT_PERIOD, 1, ped )

    -- В противном случае удаляем временный контейнер и педа
    else
        exports.xritems:xrDestroyContainer( ped )
        destroyElement( ped )
    end
end

function xrSpawnFakePlayer( player )
    local rx, ry, rz = getElementRotation( player )

    local ped = createPed( player.model, player.position, rz, false )
    if ped then
        setElementData( ped, "fake", true )
        setElementData( ped, "int", EHashes.ContainerClass )
        setElementData( ped, "cl", EHashes.CharacterFake )
        setElementFrozen( ped, true )
        setElementCollisionsEnabled( ped, false )    

        -- Создаем временный лут-контейнер
        local lootContainerId = exports[ "xritems" ]:xrCreateContainer( "PlayerContainer", true )
        if lootContainerId then
            setElementData( ped, "contId", lootContainerId )
        end	

        triggerClientEvent( EClientEvents.onClientPedFakeDead, ped, player )

        -- Через период DESTROY_PERIOD пед должен быть удален
        setTimer( doPedDestroy, DESTROY_PERIOD, 1, ped )

        return ped
    end

    return false
end