#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>

#undef REQUIRE_PLUGIN
#include <steamtools>

#pragma semicolon 1

#define BOW "tf_weapon_compound_bow"
#define ARROW "tf_projectile_arrow"

#define JUMPCHARGETIME 1
#define JUMPCHARGE (25 * JUMPCHARGETIME)

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Huntsman Heaven",
	author = "Powerlord",
	description = "An adaptation of Huntsman Hell",
	version = VERSION,
	url = "<- URL ->"
}

new String:g_Sounds_Explode[][] = {"weapons/explode1.wav", "weapons/explode2.wav", "weapons/explode3.wav" };
new String:g_Sounds_Jump[][] = { "", "" };

new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_Explode = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeRadius = INVALID_HANDLE;
new Handle:g_Cvar_ExplodeDamage = INVALID_HANDLE;
new Handle:g_Cvar_FireArrows = INVALID_HANDLE;
new Handle:g_Cvar_SuperJump = INVALID_HANDLE;

new Handle:jumpHUD;

new g_JumpCharge[MAXPLAYERS];

new bool:g_Enabled = false;

new bool:g_SteamTools = false;

new bool:g_Arena = false;

public OnPluginStart()
{
	CreateConVar("huntsmanheaven_version", VERSION, "Huntsman Heaven Version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_Cvar_Enabled = CreateConVar("huntsmanheaven_enabled", "1.0", "Enable Huntsman Heaven?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Explode = CreateConVar("huntsmanheaven_explode", "1.0", "Should arrows explode when they hit something?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_ExplodeRadius = CreateConVar("huntsmanheaven_exploderadius", "200.0", "If arrows explode, the radius of explosion in hammer units.", FCVAR_PLUGIN);
	g_Cvar_ExplodeDamage = CreateConVar("huntsmanheaven_explodedamage", "50.0", "If arrows explode, the damage the explosion does.", FCVAR_PLUGIN);
	g_Cvar_FireArrows = CreateConVar("huntsmanheaven_firearrows", "1.0", "Should all arrows catch on fire in Huntsman Heaven?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_SuperJump = CreateConVar("huntsmanheaven_superjump", "1.0", "Should super jump be enabled in Huntsman Heaven?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundStart);
	
	jumpHUD = CreateHudSynchronizer();
	LoadTranslations("huntsmanheaven.phrases");
	AutoExecConfig(true, "huntsmanheaven");
}

public OnAllPluginsLoaded()
{
	g_SteamTools = LibraryExists("SteamTools");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "SteamTools", false))
	{
		g_SteamTools = false;
	}
}

public OnMapStart()
{
	if (g_SteamTools)
	{
		Steam_SetGameDescription("Team Fortress");
	}

	for (new i = 0; i < sizeof(g_Sounds_Explode); ++i)
	{
		PrecacheSound(g_Sounds_Explode[i]);
	}
	
	for (new i = 0; i < sizeof(g_Sounds_Jump); ++i)
	{
		PrecacheSound(g_Sounds_Jump[i]);
	}
	
	if (FindEntityByClassname(-1, "tf_logic_arena") != -1)
	{
		g_Arena = true;
	}
	else
	{
		g_Arena = false;
	}
	
}

public OnConfigsExecuted()
{
	g_Enabled = GetConVarBool(g_Cvar_Enabled);
	
	UpdateGameDescription();
}

public OnClientConnected(client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, HuntsmanSwitch);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_Cvar_SuperJump) || (g_Arena && StrEqual(name, "teamplay_round_start", false)))
	{
		return;
	}
	
	CreateTimer(0.2, JumpTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_Enabled)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class != TFClass_Sniper)
	{
		TF2_SetPlayerClass(client, TFClass_Sniper);
		TF2_RespawnPlayer(client);
	}
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	static Handle:item = INVALID_HANDLE;
	
	if (!g_Enabled)
	{
		return Plugin_Continue;
	}
	
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	
	if (StrEqual(classname, "tf_weapon_smg") || iItemDefinitionIndex == 57 || iItemDefinitionIndex == 231 || iItemDefinitionIndex == 642)
	{
		item = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(item, "tf_weapon_jar");
		TF2Items_SetItemIndex(item, 58);
		TF2Items_SetLevel(item, 5);
		TF2Items_SetQuality(item, 6);
		TF2Items_SetNumAttributes(item, 2);
		TF2Items_SetAttribute(item, 0, 56, 1.0);
		TF2Items_SetAttribute(item, 1, 292, 4.0);
		hItem = item;
		return Plugin_Changed;
	}
	else if (StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap"))
	{
		item = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(item, "tf_weapon_compound_bow");
		TF2Items_SetItemIndex(item, 56);
		TF2Items_SetLevel(item, 10);
		TF2Items_SetQuality(item, 6);
		TF2Items_SetNumAttributes(item, 2);
		TF2Items_SetAttribute(item, 0, 37, 0.5);
		TF2Items_SetAttribute(item, 1, 328, 1.0);
		hItem = item;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!g_Enabled)
	{
		return;
	}
	
	if (StrEqual(classname, ARROW))
	{
// We're testing lighting the bow itself for now
/*
		if (GetConVarBool(g_Cvar_FireArrows))
		{
			SDKHook(entity, SDKHook_SpawnPost, Arrow_Ignite);
		}
*/
		if (GetConVarBool(g_Cvar_Explode))
		{
			SDKHook(entity, SDKHook_StartTouchPost, Arrow_Explode);
		}
	}
}

public Arrow_Ignite(entity)
{
	if (!g_Enabled)
	{
		return;
	}
	
	SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
}

public Arrow_Explode(entity, other)
{
	new Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	new String:teamString[2];
	new String:magnitudeString[6];
	new String:radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	GetConVarString(g_Cvar_ExplodeDamage, magnitudeString, sizeof(magnitudeString));
	GetConVarString(g_Cvar_ExplodeRadius, radiusString, sizeof(radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntProp(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");
	AcceptEntityInput(explosion, "Kill");
	
	new random = GetRandomInt(0, sizeof(g_Sounds_Explode));
	EmitSoundToAll(g_Sounds_Explode[random], entity, SNDCHAN_WEAPON, _, _, _, _, _, origin);
}

public HuntsmanSwitch(client, weapon)
{
	if (!g_Enabled || !GetConVarBool(g_Cvar_FireArrows))
	{
		return;
	}
	
	new String:classname[64];
	
	GetEntityClassname(weapon, classname, sizeof(classname));

	if (StrEqual(classname, BOW))
	{
		SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1);
	}
}

UpdateGameDescription()
{
	if (g_SteamTools && g_Enabled)
	{
		new String:gamemode[32];
		
		Format(gamemode, sizeof(gamemode), "%s v.%d", "Huntsman Heaven", VERSION);
		Steam_SetGameDescription(gamemode);
	}
}

public Action:JumpTimer(Handle:hTimer)
{
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		SetHudTextParams(-1.0, 0.88, 0.35, 255, 255, 255, 255);
		new buttons = GetClientButtons(i);
		if (((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && (g_JumpCharge[i] >= 0) && !(buttons & IN_JUMP))
		{
			if (g_JumpCharge[i] + 5 < JUMPCHARGE)
			{
				g_JumpCharge[i] += 5;
			}
			else
			{
				g_JumpCharge[i] = JUMPCHARGE;
			}
			
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status", g_JumpCharge[i]);
		}
		else if (g_JumpCharge[i] < 0)
		{
			g_JumpCharge[i] += 5;
			ShowSyncHudText(i, jumpHUD, "%t", "jump_status_2", -g_JumpCharge[i]/20);
		}
		else
		{
			decl Float:ang[3];
			GetClientEyeAngles(i, ang);
			if ((ang[0] < -45.0) && (g_JumpCharge[i] > 1))
			{
				decl Float:pos[3];
				decl Float:vel[3];
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vel);
				vel[2]=750 + g_JumpCharge[i] * 13.0;
				SetEntProp(i, Prop_Send, "m_bJumping", 1);
				vel[0] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				vel[1] *= (1+Sine(float(g_JumpCharge[i]) * FLOAT_PI / 50));
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vel);
				g_JumpCharge[i]=-120;
				
				new random = GetRandomInt(0, sizeof(g_Sounds_Jump));
				EmitSoundToAll(g_Sounds_Jump[random] , i, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, _, _, _, _, pos, NULL_VECTOR);
			}
		}
	}
}

