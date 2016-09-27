#include <amxmodx>
#include <chatcolor>
#if AMXX_VERSION_NUM < 183
	#include colorchat
	#define engine_changelevel(%0) server_cmd("changelevel %s", %0)
#endif	

#define STARTTIME	22		// Время начала ночного режима. Тестировал только с 00 часов. Поддежка раннего времени есть, но не проверялось:)
#define ENDTIME		07		// Окончание ночного режима
#define MAP 		"de_dust2"	// Карта ночного режима
#define AUTORR		80		// Авторестарт карты (sv_restart 1) каждые n раундов. Установите 0 для отключения данной плюшки.

new g_pTimeLimit, g_iOldTime, Float:g_flResetTime;
new bool:g_bNight;
#if AUTORR > 0
new g_iRound;
#endif

public plugin_init()
{
#define VERSION "1.0.6"
	register_plugin("Lite NightMode", VERSION, "neygomon");
	register_cvar("lite_nightmode", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

	register_event("TextMsg", 	"eGameCommencing", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");	
	register_event("HLTV", 		"eRoundStart", "a", "1=0", "2=0");

	register_clcmd("say rtv", "RtvHook");
	register_clcmd("say_team rtv", "RtvHook");
	register_clcmd("say /rtv", "RtvHook");
	register_clcmd("say_team rtv", "RtvHook");
	register_clcmd("amx_rtv", "RtvHook");
	
	g_pTimeLimit = get_cvar_pointer("mp_timelimit");
}

public plugin_end()
	if(g_iOldTime) 
		set_pcvar_num(g_pTimeLimit, g_iOldTime);

public client_putinserver(id)
	if(g_bNight) 
		remove_user_flags(id, ADMIN_MAP|ADMIN_VOTE);
		
public eGameCommencing()
{
	g_flResetTime = get_gametime();
#if AUTORR > 0	
	g_iRound = 0;
#endif	
}	

public eRoundStart()
{
	static szCurMap[32], CurHour; time(CurHour);
#if STARTTIME > ENDTIME
	if(STARTTIME <= CurHour || CurHour < ENDTIME)
#else
	if(STARTTIME <= CurHour < ENDTIME)
#endif	
	{	
		if(!szCurMap[0])
		{
			get_mapname(szCurMap, charsmax(szCurMap));
			if(!equal(szCurMap, MAP))
				engine_changelevel(MAP);
		}	
		else if(!g_bNight)
		{
			g_bNight = true;
			RemovePlayersFlags();
			g_iOldTime = get_pcvar_num(g_pTimeLimit);
			set_pcvar_num(g_pTimeLimit, 0);
		}	
#if AUTORR > 0			
		static iRound; iRound = AUTORR - ++g_iRound;
		if(iRound > 0) client_print_color(0, 0, "^1[^4Only ^3%s^1] ^4Через ^3%d ^4раундов авторестарт карты. ^1[ ^4Тек. раунд: ^3%d ^1| ^4Всего: ^3%d^1 ]", MAP, iRound, g_iRound, AUTORR);
		else server_cmd("sv_restart 1");
#endif			
	}	
	else if(g_bNight)
	{
		set_pcvar_num(g_pTimeLimit, floatround(get_gametime() - g_flResetTime) / 60 + 5);
		g_bNight = false;
	}
}

public RtvHook(id)
{
	if(!g_bNight) return PLUGIN_CONTINUE;
	client_print_color(id, 0, "^1[^4Only ^3%s^1] ^4RTV не работает в ^3Ночном режиме!", MAP);
	return PLUGIN_HANDLED;
}

RemovePlayersFlags()
{
	static players[32], pcount;
	get_players(players, pcount, "ch");
	for(new i; i < pcount; i++)
		remove_user_flags(players[i], ADMIN_MAP|ADMIN_VOTE);
}