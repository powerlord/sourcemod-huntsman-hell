#include <sourcemod>
#include <sdkhooks>

#define LOGFILE "explosion.log"
public Plugin:myinfo = 
{
	name = "New Plugin",
	author = "Powerlord",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "env_explosion"))
	{
		SDKHook(entity, SDKHook_SpawnPost, ExplosionSpawn);
	}
}

public ExplosionSpawn(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	new inflictor = GetEntPropEnt(entity, Prop_Data, "m_hInflictor");
	new String:ownerClass[64];
	new magnitude = GetEntProp(entity, Prop_Data, "m_iMagnitude");
	new radius = GetEntProp(entity, Prop_Data, "m_iRadiusOverride");
	new String:filter[32];
	GetEntPropString(entity, Prop_Data, "m_iszDamageFilterName", filter, sizeof(filter));
	new Float:damageForce = GetEntPropFloat(entity, Prop_Data, "m_flDamageForce");
	new renderMode = GetEntProp(entity, Prop_Data, "m_nRenderMode");
	new ignoredEntity = GetEntProp(entity, Prop_Data, "m_hEntityIgnore");
	new spawnflags = GetEntProp(entity, Prop_Data, "m_spawnflags");
	
	if (IsValidEntity(owner))
	{
		GetEntityClassname(owner, ownerClass, sizeof(ownerClass));
	}
	
	LogToFile(LOGFILE, "Explosion! owner: %d (%s), inflictor: %d, magnitude: %d, radius: %d, filter: %s, damage force: %f, render mode: %d, ignored entity: %d, spawnflags: %d ",
	owner, ownerClass, inflictor, magnitude, radius, filter, damageForce, renderMode, ignoredEntity, spawnflags);
	
	
	
}