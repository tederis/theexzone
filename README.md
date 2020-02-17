# theexzone
MTA: The Exclusion Zone
1. Add these lines to acl.xml:
 <group name="sp_game">
        <acl name="Default"></acl>
        <acl name="sp_game"></acl>
        <object name="resource.xritems"></object>
        <object name="resource.xrcore"></object>
        <object name="resource.sp_gamemode"></object>
        <object name="resource.sp_inventory"></object>
        <object name="resource.sp_weapon"></object>
        <object name="resource.sp_hud_real"></object>
        <object name="resource.escape"></object>
        <object name="resource.anomaly"></object>
        <object name="resource.papi"></object>
        <object name="resource.sp_interact"></object>
        <object name="resource.sp_player"></object>
        <object name="resource.sp_login"></object>
        <object name="resource.sp_dialog"></object>
        <object name="resource.sp_npc"></object>
        <object name="resource.sp_chatbox"></object>
        <object name="resource.sp_npc_new"></object>
        <object name="resource.sp_hud_real_new"></object>
    </group>

    <acl name="sp_game">
        <right name="general.ModifyOtherObjects" access="true"></right>
        <right name="general.http" access="true"></right>
        <right name="function.startResource" access="true"></right>
        <right name="general.adminpanel" access="false"></right>
        <right name="general.tab_players" access="false"></right>
        <right name="general.tab_resources" access="false"></right>
        <right name="general.tab_maps" access="false"></right>
        <right name="general.tab_server" access="false"></right>
        <right name="general.tab_bans" access="false"></right>
        <right name="general.tab_adminchat" access="false"></right>
        <right name="command.kick" access="false"></right>
        <right name="command.freeze" access="false"></right>
        <right name="command.mute" access="false"></right>
        <right name="command.setnick" access="false"></right>
        <right name="command.shout" access="false"></right>
        <right name="command.spectate" access="false"></right>
        <right name="command.slap" access="false"></right>
        <right name="command.setgroup" access="false"></right>
        <right name="command.sethealth" access="false"></right>
        <right name="command.setarmour" access="false"></right>
        <right name="command.setmoney" access="false"></right>
        <right name="command.setskin" access="false"></right>
        <right name="command.setteam" access="false"></right>
        <right name="command.giveweapon" access="false"></right>
        <right name="command.setstat" access="false"></right>
        <right name="command.jetpack" access="false"></right>
        <right name="command.warp" access="false"></right>
        <right name="command.setdimension" access="false"></right>
        <right name="command.setinterior" access="false"></right>
        <right name="command.createteam" access="false"></right>
        <right name="command.destroyteam" access="false"></right>
        <right name="command.givevehicle" access="false"></right>
        <right name="command.repair" access="false"></right>
        <right name="command.blowvehicle" access="false"></right>
        <right name="command.destroyvehicle" access="false"></right>
        <right name="command.customize" access="false"></right>
        <right name="command.setcolor" access="false"></right>
        <right name="command.setpaintjob" access="false"></right>
        <right name="command.listmessages" access="false"></right>
        <right name="command.readmessage" access="false"></right>
        <right name="command.listresources" access="false"></right>
        <right name="command.start" access="false"></right>
        <right name="command.stop" access="false"></right>
        <right name="command.stopall" access="false"></right>
        <right name="command.delete" access="false"></right>
        <right name="command.restart" access="false"></right>
        <right name="command.execute" access="false"></right>
        <right name="command.setpassword" access="false"></right>
        <right name="command.setwelcome" access="false"></right>
        <right name="command.setgame" access="false"></right>
        <right name="command.setmap" access="false"></right>
        <right name="command.setweather" access="false"></right>
        <right name="command.blendweather" access="false"></right>
        <right name="command.setblurlevel" access="false"></right>
        <right name="command.setwaveheight" access="false"></right>
        <right name="command.setskygradient" access="false"></right>
        <right name="command.setgamespeed" access="false"></right>
        <right name="command.setgravity" access="false"></right>
        <right name="command.settime" access="false"></right>
        <right name="command.setfpslimit" access="false"></right>
        <right name="function.shutdown" access="false"></right>
        <right name="command.clearchat" access="false"></right>
        <right name="command.ban" access="false"></right>
        <right name="command.unban" access="false"></right>
        <right name="command.banip" access="false"></right>
        <right name="command.unbanip" access="false"></right>
        <right name="command.banserial" access="false"></right>
        <right name="command.unbanserial" access="false"></right>
        <right name="command.listbans" access="false"></right>
    </acl>

2. Check this setting in mtaserver.conf:
    <database_credentials_protection>0</database_credentials_protection>

3. You also should create a new database with name 'sp'. Connection settings should reside in MTA settings system: 'db_user' for database user and 'db_pass' for database pass.
