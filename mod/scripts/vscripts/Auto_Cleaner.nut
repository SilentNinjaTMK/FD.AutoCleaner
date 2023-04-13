global function AutoCleaner_Init

void function AutoCleaner_Init() {
    AddCallback_GameStateEnter(eGameState.Playing, OnWaveInProgress)
    AddClientCommandCallback( "clean", ClientCleanUpLastNPC )
}

bool function ClientCleanUpLastNPC( entity player, array<string> args )
{
    thread CleanUpLastNPC()
    return true
}

void function OnWaveInProgress()
{
    TryCleanUpNPC()
}

void function TryCleanUpNPC()
{
    thread TryCleanUpNPC_Thread()
}

void function TryCleanUpNPC_Thread()
{
    svGlobal.levelEnt.EndSignal( "GameStateChanged" )
    while( true )
    {
        while( GetGlobalNetInt( "FD_AICount_Current" ) != 5) //更改npc存活数量
            WaitFrame()
        waitthread CleanUpLastNPC()
    }
}

void function CleanUpLastNPC()
{
    array<entity> npcs = GetNPCArrayOfTeam( TEAM_IMC )
    if( npcs.len() == 0 ) //检查npc是否已被玩家清除
        return
    foreach (entity player in GetPlayerArray())
    {
        print("开始60s清理倒计时")
        NSSendInfoMessageToPlayer( player, "偵測到預設敵人數量，已標記剩餘敵人位置，60秒后將會自動清除剩餘敵人" )
        StatusEffect_AddTimed( player, eStatusEffect.sonar_detected, 1.0, 3.0, 0.0) //让玩家画面显示“侦测到声纳”
        // EmitSoundOnEntityOnlyToPlayer( player , player , "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
    }

    foreach (entity highlightnpc in GetNPCArray())
    {
        Highlight_SetEnemyHighlight( highlightnpc, "enemy_sonar" )
    }
    float endTime = Time() + 60 //存储循环结束时间
    while( Time() < endTime ) //当时间小于循环剩余时间时，保持等待
    {
        npcs = GetNPCArrayOfTeam( TEAM_IMC ) //持续更新npc数组
        if( npcs.len() == 0 ) //等待过程中被清空
            return
        WaitFrame()
    }
    foreach ( entity npc in GetNPCArrayOfTeam( TEAM_IMC ))
    {
        print( npc )
        if( IsAlive( npc ))
            npc.Die()
    }
    print("清理完成")
    foreach (entity player in GetPlayerArray())
    {
        NSSendInfoMessageToPlayer( player, "NPC已清除" )
    }
}

