IS_SERVER = triggerClientEvent ~= nil

g_ResourceNames = {
    [ "xritems" ] = { awaitSignal = true },
    [ "sp_loading" ] = { awaitSignal = false },
    [ "sp_login" ] = { awaitSignal = true },
    [ "sp_inventory" ] = { awaitSignal = true },
    [ "sp_player" ] = { awaitSignal = true },
    [ "sp_weapon" ] = { awaitSignal = true },
    [ "sp_npc_new" ] = { awaitSignal = false },
    [ "sp_gamemode" ] = { awaitSignal = true },
    [ "sp_interact" ] = { awaitSignal = true },
    [ "sp_pipeline" ] = { awaitSignal = true },
    [ "sp_assets" ] = { awaitSignal = false },
    [ "sp_hud_real_new" ] = { awaitSignal = false },
    [ "sp_dialog" ] = { awaitSignal = false },
    [ "sp_world" ] = { awaitSignal = false },
    [ "sp_peds" ] = { awaitSignal = false },
    [ "sp_pda" ] = { awaitSignal = false },
    [ "sp_guitar" ] = { awaitSignal = false },
    [ "sp_chatbox" ] = { awaitSignal = false },
    [ "papi" ] = { awaitSignal = false },
    [ "anomaly" ] = { awaitSignal = false },

    -- Локации
    [ "escape" ] = { awaitSignal = true }
}