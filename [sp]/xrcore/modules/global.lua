xrIncludeModule( "utils.lua" )

EMPTY_TABLE = {
    -- Read only таблица
}
EMPTY_STR = "" -- Read only строка

MAX_PLAYER_WEIGHT = 40
PLAYER_OVERWEIGHT_START = 40

ZONE_OCCUPY_PERIOD_SECS = 45 * 60

G_TIME_DURATION = 3000

enum "EItemAttribute" {
    "EIA_TYPE",
    "EIA_ID",
    "EIA_SLOT",
    "EIA_CONDITION",
    "EIA_COUNT",
    "EIA_AMMO" -- Патронов в патроннике
}

EItemCopyAttributes = {
    EIA_COUNT,
    EIA_AMMO,
    EIA_CONDITION,
    EIA_TYPE
} 

EItemCompareAttributes = {
    EIA_TYPE,
    EIA_CONDITION,
    EIA_AMMO
}

enum "EContainerAttribute" {
    "ECA_ID",
    "ECA_TYPE",
    "ECA_ITEMS",
    "ECA_SLOTS",
    "ECA_LAST_ID",
    "ECA_OWNER",
    "ECA_PASSWORD",
    "ECA_DIRTY"
}

enum "EContainerOperator" {
    "ECO_CREATE",
    "ECO_REMOVE",
    "ECO_MODIFY"
}

enum "ESessionType" {
	"EST_PLAYER_PLAYER",
	"EST_PLAYER_NPC",
	"EST_PLAYER_OBJECT",
    "EST_PLAYER_SELF"
}

enum "PlayerHitType" {
    "PHT_RADIATION",
    "PHT_STRIKE",
    "PTH_SHOCK",
    "PTH_BURN",
    "PTH_POWER"
}

enum "CharacterFields" {
    "E_CHAR_PLAYER",
    "E_CHAR_NAME",
    "E_CHAR_ID",
    "E_CHAR_SKIN",
    "E_CHAR_HEALTH",
    "E_CHAR_ARMOR",
    "E_CHAR_MONEY",
    "E_CHAR_RANK",
    "E_CHAR_REP",
    "E_CHAR_CONT_ID",
    "E_CHAR_PLAYER_ID",
    "E_CHAR_FACTION",
    "E_CHAR_INFO",
    "E_CHAR_QUESTS",
    "E_CHAR_WANTED"
}

enum "BoostParams" {
    "EBHpRestore",
    "EBPowerRestore",
    "EBRadiationRestore",
    "EBBleedingRestore",
    "EBMaxWeight",
    "EBRadiationProtection",
    "EBTelepaticProtection",
    "EBChemicalBurnProtection",
    "EBBurnImmunity",
    "EBShockImmunity",
    "EBRadiationImmunity",
    "EBTelepaticImmunity",
    "EBChemicalBurnImmunity",
    "EBExplImmunity",
    "EBStrikeImmunity",
    "EBFireWoundImmunity",
    "EBWoundImmunity"
}

enum "BoostTypes" {
    "b_health_r",
    "b_power_r",
    "b_radiation_r",
    "b_bleeding_r",
    "b_max_weight",
    "b_radiation_p",
    "b_telepat_p",
    "b_chemburn_p",
    "b_burn_i",
    "b_shock_i",
    "b_radiation_i",
    "b_telepat_i",
    "b_chemburn_i",
    "b_explosion_i",
    "b_strike_i",
    "b_fire_wound_i",
    "b_wound_i"
}

enum "AffectTypes" {
    "EAT_HEALTH_RSPD",
    "EAT_POWER_RSPD",
    "EAT_RAD_RSPD",
    "EAT_BLEED_RSPD"
}

enum "PlayerStatus" {
    "EPS_AWAIT",
    "EPS_PLAYING"
}

enum "QuestPacket" {
    "QPT_TYPE",
    "QPT_STATE",
    "QPT_VARS"
}

enum "LoginErrorCode" {
    -- Login
    "LEC_AUTHORIZED",
    "LEC_UNREGISTERED",
    "LEC_FATAL",
    "LEC_LOGIN_LEN",
    "LEC_PASS_LEN",

    -- Register
    "REC_AUTHORIZED",
    "REC_REGISTERED",
    "REC_FATAL",

    -- Character
    "CEC_LIMIT",
    "CEC_NAME_LEN"
}

ERankNames = {
    "новичок",
    "опытный",
    "ветеран",
    "мастер"
}


enum "HelpStringCode" {
    "HSC_NONE",
    "HSC_FIRST",
    "HSC_ITEMS",
    "HSC_FIND_AREA",
    "HSC_KEEP_AREA",
    "HSC_CRUSH_AREA",

    "HSC_CAMPFIRE_AREA",

    "HSC_KILLER_REWARD"
}

EHelpStrings = {
    -- [ identifier ] = { text, priority, duration, appearance_probability }
    [ HSC_FIRST ] = { "Подойдите к торговцу. Он поможет с экипировкой.", 100, 10000, 1 },
    [ HSC_ITEMS ] = { "Часть вашей экипировки находится у торговца", 100, 10000, 1 },
    [ HSC_FIND_AREA ] = { "Найдите аванпост поблизости и захватите его.", 90, 5000, 1 },
    [ HSC_KEEP_AREA ] = { "Удерживайте аванпост до полного захвата", 100, 6000, 1 },
    [ HSC_CRUSH_AREA ] = { "Подавите противника и удержите аванпост", 100, 6000, 1 },

    [ HSC_CAMPFIRE_AREA ] = { "У костра ваше здоровье восстанавливается быстрее", 10, 4000, 0.3 }
}

enum "NPCActivityType" {
    "NAT_STROLL",
    "NAT_IDLE",
    "NAT_ATTACK"
}

ESkinsLookup = {
    [ 280 ] = true,
    [ 31 ] = true,
    [ 36 ] = true,
    [ 32 ] = true,
    [ 33 ] = true,
    [ 34 ] = true,
    [ 281 ] = true,
    [ 282 ] = true,
    [ 283 ] = true,
    [ 284 ] = true,
    [ 285 ] = true
}

EDirtyFlags = {
    None = 0x0,
    States = 0x1,
    Info = 0x2,
    Quests = 0x4,
    Reserved = 0x8,
    All = 0xF
}

EHashes = {
    CharacterPlayer = _hashFn( "char_player" ),
    CharacterFake = _hashFn( "char_fake" ),

    ZoneRadiation = _hashFn( "ZoneRadiation" ),
    ZoneSector = _hashFn( "ZoneSector" ),
    ZoneGreen = _hashFn( "ZoneGreen" ),
    ZoneCampfire = _hashFn( "ZoneCampfire" ),
    ZoneAnomaly = _hashFn( "ZoneAnomaly" ),

    SlotBag = _hashFn( "slot_bag" ),
    SlotBelt = _hashFn( "slot_belt" ),
    SlotAutomatic = _hashFn( "slot_automatic" ),
    SlotPistol = _hashFn( "slot_pistol" ),
    SlotKnife = _hashFn( "slot_knife" ),
    SlotGrenade = _hashFn( "slot_grenade" ),
    SlotTemp = _hashFn( "slot_temp" ),
    SlotTrade = _hashFn( "slot_trade" ),
    SlotAny = _hashFn( "slot_any" ),

    ArtefactItem = _hashFn( "ArtefactItem" ),
    GrenadeItem = _hashFn( "GrenadeItem" ),
    WeaponItem = _hashFn( "WeaponItem" ),
    LightItem = _hashFn( "LightItem" ),

    TorchItem = _hashFn( "device_torch" ),

    PlayerContainer = _hashFn( "PlayerContainer" ),

    QuestInfoPassedCourier = _hashFn( "info_passed_courier_quest" ),
    QuestInfoHasQuestCourier = _hashFn( "has_courier_quest" ),
    QuestInfoLastTime = _hashFn( "courier_quest_last_begin_time" ),
    QuestActionStartCourier = _hashFn( "act_start_courier_quest" ),
    QuestActionFinishCourier = _hashFn( "act_finish_courier_quest" ),

    InfoPlayerNaked = _hashFn( "is_player_naked" ),
    InfoTutorialPassed = _hashFn( "tutorial_passed" ),
    InfoIntroLeft = _hashFn( "is_intro_left" ),
    InfoAftefactCounter = _hashFn( "artefact_count" ),
    InfoLastThunderboltTime = _hashFn( "last_thunderbolt_time" ),

    QuestCourier = _hashFn( "quest_courier" ),

    MessageText = _hashFn( "MessageText" ),
    MessageFoundMoney = _hashFn( "MessageFoundMoney" ),
    MessageGiveItem = _hashFn( "MessageGiveItem" ),
    MessageRankIncrease = _hashFn( "MessageRankIncrease" ),

    -- AI
    AIDomainSimple = _hashFn( "ai_domain" ),
    AIDomainStrong = _hashFn( "ai_domain_strong" ),
    AIDogWeak = _hashFn( "ai_dog_weak" ),

    TeamStalker = _hashFn( "team_stalker" ),
    TeamBandit = _hashFn( "team_bandit" ),

    DropClass = _hashFn( "DropClass" ),
    ArtefactClass = _hashFn( "ArtefactClass" ),
    CharacterClass = _hashFn( "CharacterClass" ),
    CampfireClass = _hashFn( "CampfireClass" ),
    ContainerClass = _hashFn( "ContainerClass" ),

}

EItemHashes = {
    wpn_pm = _hashFn( "wpn_pm" ),
    ammo9_18_fmj = _hashFn( "ammo_9x18_fmj" ),
    medkit = _hashFn( "medkit" ),
    bandage = _hashFn( "bandage" ),
    bolt = _hashFn( "bolt" ),

    DogTail = _hashFn( "mutant_dog_tail" )
}

EDetectorSlots = {
    SlotGeiger = _hashFn( "slot_geiger" ),
    SlotAnomaly = _hashFn( "slot_anomaly" )
}

EWeaponSlots = {
    EHashes.SlotKnife,
    EHashes.SlotPistol,
    EHashes.SlotAutomatic,
    EHashes.SlotGrenade
}

EWeaponSlotIndices = {}
for i, slotHash in ipairs( EWeaponSlots ) do
    EWeaponSlotIndices[ slotHash ] = i
end

EClientEvents = {
    onClientBehaviorTreeEvent = "c_a1",
    onClientAgentLostSyncer = "c_a2",
    onClientAgentRemoteEvent = "c_a3",
    onClientAgentWasted = "c_a4",
    onClientRemoteAgentAction = "c_a5",

    onClientContainerData = "c_c1",
    onClientContainerDestroy = "c_c2",
    onClientContainerChange = "c_c3",
    onClientItemUse = "c_c4",

    onZoneEvent = "c_z1",
    onClientThunderboltStarted = "c_z2",
    onClientThunderboltFinished = "c_z3",
    onClientThunderboltForced = "c_z4",

    onClientDialogData = "c_d1",
    onClientDomainEvent = "c_d2",

    onClientPlayerGamodeJoin = "c_g1",
    onClientPlayerGamodeLeave = "c_g2",

    onClientPlayerEnterLevel = "c_l1",
    onClientPlayerLeaveLevel = "c_l2",

    onClientItemRemove = "c_i1",
    onClientItemNew = "c_i2",
    onClientItemModify = "c_i3",
    onClientSessionStop = "c_i4",
    onClientSessionStart = "c_i5",
    onClientTradeError = "c_i6",

    onPlayerEmptyFire = "c_w1",
    onClientWeaponSelect = "c_w2",
    onClientMisfire = "c_w3",
    onClientPlayerReload = "c_w4",

    onClientAddRank = "c_p1",
    onClientApplyBooster = "c_p2",
    onClientBoosterApplied = "c_p3",
    onClientApplyItemAffects = "c_p4",
    onClientRemoveItemAffects = "c_p5",
    onClientPlayerHit = "c_p6",
    onClientPlayerDead = "c_p7",
    onClientPedFakeDead = "c_p8",

    onClientQuestState = "c_q1",
    onClientQuestVar = "c_q2",
    onClientQuestCreate = "c_q3",

    onClientHelpString = "c_h1",
    onClientNewsMessage = "c_h2"
}

EServerEvents = {
    onPlayerEnterLevel = "s_l1",
    onPlayerLeaveLevel = "s_l2",

    onThunderboltStarted = "s_z1",
    onThunderboltFinished = "s_z2",

    onPlayerGamodeLeave = "s_g1",
    onPlayerGamodeJoin = "s_g2",

    onSessionTradeOp = "s_i1",
    onSessionStop = "s_i2",
    onSessionItemMove = "s_i3",
    onSessionItemUse = "s_i4",    
    onSessionItemDrop = "s_i5",

    onAnomalyBoltHit = "s_a1",   
    onArtefactTake = "s_a2",
    onAgentAttack = "s_a3",
    onAgentRemoteEvent = "s_a4",
    onBehaviorTreeEvent = "s_a5",

    onReloadWeap = "s_w1",
    onPlayerBoltThrow = "s_w2",

    onPlayerForceDead = "s_p0",
    onPlayerDead = "s_p1",
    onPlayerDeadFinish = "s_p2",
    onPlayerReady = "s_p3",
    onPlayerInteract = "s_p4",
    onPlayerSpawn = "s_p5",

    onDialogTradeStart = "s_d1",
    onDialogPhraseSelect = "s_d2",
    onDialogStartTalk = "s_d3",
    onDialogEndTalk = "s_d4"
}