//待测试
global function AutoCleaner_Init
global function DeCloakGhostNPC
global function CleanUpLastNPC
global function ShowAliveNPCsPosition

//更改判定阈值（NPC数量）
const int NPC_SHOWPOS_COUNT_DEFAULT =  10
const int NPC_CLEAN_COUNT =  5
const int NPC_SHOWPOS_COUNT_SPECIAL =  5
const int NPC_CLEAN_SPECIAL =  1

//更改清除等待时间
const int COUNTDOWN_DEFAULT = 30
const int COUNTDOWN_SPECIAL = 10

struct
{
    int npcLeftToClean = 1 // default
    int CleanTimeCount = 60
    int ShowAliveNPCsPosition = 10
} file

void function AutoCleaner_Init()
{
    AddCallback_GameStateEnter(eGameState.Playing, OnWaveInProgress)
    AddClientCommandCallback( "showpos", ClientShowAliveNPCsPosition )
}

void function OnWaveInProgress()
{
    StartWaveStateLoop()
    TryCleanUpNPC()
}

void function StartWaveStateLoop()
{
    thread StartWaveStateLoop_Threaded()
}

void function StartWaveStateLoop_Threaded()
{
    int lastWaveState //用于存上一个tick中的波次状态，要卸载while外面，防止下一次循环开始时被清空
    bool firstLoop = true
    while(true)
    {
        int currentWaveState = GetGlobalNetInt("FD_waveState") //当前tick的波次状态
        bool waveStateChanged = currentWaveState != lastWaveState //检查波次是否更新

        //回合即将开始判定
        if(currentWaveState == WAVE_STATE_IN_PROGRESS)
        {
            if(waveStateChanged && !firstLoop)
            {
                int waveCount = GetGlobalNetInt("FD_currentWave")
                switch (waveCount) //根据波次输出信息 0-5
                {
                    case 0:
                        print("回合1开始")
                        file.npcLeftToClean = NPC_CLEAN_COUNT
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_DEFAULT
                        break;
                    case 1:
                        print("回合2开始")
                        file.npcLeftToClean = NPC_CLEAN_COUNT
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_DEFAULT
                        break;
                    case 2:
                        print("回合3开始")
                        file.npcLeftToClean = NPC_CLEAN_COUNT
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_DEFAULT
                        break;
                    case 3:
                        print("回合4开始")
                        file.npcLeftToClean = NPC_CLEAN_SPECIAL
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_SPECIAL
                        break;
                    case 4:
                        print("回合5开始")
                        file.npcLeftToClean = NPC_CLEAN_COUNT
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_DEFAULT
                        break;
                    case 5:
                        print("回合6开始")
                        file.npcLeftToClean = NPC_CLEAN_COUNT
                        file.CleanTimeCount = COUNTDOWN_DEFAULT
                        file.ShowAliveNPCsPosition = NPC_SHOWPOS_COUNT_DEFAULT
                        break;
                }
            }
        }
        firstLoop= false
        lastWaveState = GetGlobalNetInt("FD_waveState") //更新tick

        WaitFrame() //等待1tick直到下一个tick开始
    }
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
        if( file.npcLeftToClean < GetGlobalNetInt( "FD_AICount_Current" ) && GetGlobalNetInt( "FD_AICount_Current" ) <= file.ShowAliveNPCsPosition && GetNPCArrayOfTeam( TEAM_IMC ).len() != 0 )
        {
            waitthread ShowAliveNPCsPosition()
        }
        WaitFrame()
        if( GetGlobalNetInt( "FD_AICount_Current" ) <= file.npcLeftToClean && GetNPCArrayOfTeam( TEAM_IMC ).len() != 0 )
            waitthread CleanUpLastNPC()
        WaitFrame()
    }
}

void function ShowAliveNPCsPosition()
{
    array<entity> npcs = GetNPCArrayOfTeam( TEAM_IMC )
    bool isShowAnnouncementToPlayer = false
    if( npcs.len() < file.ShowAliveNPCsPosition )
        return
    if ( isShowAnnouncementToPlayer )
        return
    foreach (entity player in GetPlayerArray())
    {
        print("开始展示剩餘NPC位置")
        NSSendInfoMessageToPlayer( player, "偵測到預設敵人數量，已全圖展示剩餘敵人位置" )
        StatusEffect_AddTimed( player, eStatusEffect.sonar_detected, 1.0, 3.0, 0.0) //让玩家画面显示“侦测到声纳”
        // EmitSoundOnEntityOnlyToPlayer( player , player , "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
        isShowAnnouncementToPlayer = true
    }

    foreach (entity highlightnpc in GetNPCArray())
    {
        Highlight_SetEnemyHighlight( highlightnpc, "enemy_sonar" )
        print( highlightnpc.GetClassName() + " " + highlightnpc.GetTitle() + " " + highlightnpc.GetOrigin() )
    }

    while( file.npcLeftToClean < GetGlobalNetInt( "FD_AICount_Current" ) && GetGlobalNetInt( "FD_AICount_Current" ) <= file.ShowAliveNPCsPosition )
    {
        npcs = GetNPCArrayOfTeam( TEAM_IMC ) //持续更新npc数组
        if( npcs.len() < file.ShowAliveNPCsPosition )
            return
        WaitFrame()
    }
}

bool function DeCloakGhostNPC()
{
    svGlobal.levelEnt.EndSignal( "GameStateChanged" )
    while( true )
    {
        wait 1
        if( GetGameState() != eGameState.Playing )
            continue
        if( GetGlobalNetInt( "FD_AICount_Current" ) <= file.ShowAliveNPCsPosition && GetNPCArrayOfTeam( TEAM_IMC ).len() != 0 )
            return true
        break
    }
    return false
}

void function CleanUpLastNPC()
{
    array<entity> npcs = GetNPCArrayOfTeam( TEAM_IMC )
    if( npcs.len() == 0 ) //检查npc是否已被玩家清除
        return
    foreach (entity player in GetPlayerArray())
    {
        print("开始清理倒计时")
        NSSendInfoMessageToPlayer( player, "偵測到預設敵人數量，" + file.CleanTimeCount + "秒后將會自動清除剩餘敵人" )
        StatusEffect_AddTimed( player, eStatusEffect.sonar_detected, 1.0, 3.0, 0.0) //让玩家画面显示“侦测到声纳”
        // EmitSoundOnEntityOnlyToPlayer( player , player , "Burn_Card_Map_Hack_Radar_Pulse_V1_1P" )
    }

    foreach (entity highlightnpc in GetNPCArray())
    {
        Highlight_SetEnemyHighlight( highlightnpc, "enemy_sonar" )
    }
    float endTime = Time() + file.CleanTimeCount //存储循环结束时间
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

