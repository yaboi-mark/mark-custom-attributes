#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <dhooks>
#include <sdktools>
#include <sdktools_engine>

#pragma newdecls required

#include <tf2utils>
#include <tf_custom_attributes>
#include <stocksoup/tf/entity_prop_stocks>
#include <stocksoup/var_strings>

Handle g_DHookPrimaryAttack;

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.cattr_starterpack");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.cattr_starterpack).");
	}
	
	g_DHookPrimaryAttack = DHookCreateFromConf(hGameConf, "CTFWeaponBase::PrimaryAttack()");
	
	delete hGameConf;
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1) {
		if (TF2Util_IsEntityWeapon(entity)) {
			HookWeaponEntity(entity);
		}
	}
	
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
}

public void OnEntityCreated(int entity, const char[] className) {
	if (TF2Util_IsEntityWeapon(entity)) {
		HookWeaponEntity(entity);
	}
}

void HookWeaponEntity(int weapon) {
	DHookEntity(g_DHookPrimaryAttack, true, weapon, .callback = OnWeaponPrimaryAttackPost);
}

public void OnClientPostThinkPost(int client) {
	if (!IsPlayerAlive(client)) {
		return;
	}
}

public MRESReturn OnWeaponPrimaryAttackPost(int weapon) {
	int owner = TF2_GetEntityOwner(weapon);
	if (owner < 1 || owner > MaxClients) {
		return MRES_Ignored;
	}
	
	char attr[64];
	if (!TF2CustAttr_GetString(weapon, "fan style knockback", attr, sizeof(attr))) {
		return MRES_Ignored;
	}
	
	float onhit = ReadFloatVar(attr, "onhit", 0.0);
	if (onhit == 1) {
		return MRES_Ignored;
	}
	
	float dir = ReadFloatVar(attr, "direction", 0.0);
	float amp = ReadFloatVar(attr, "strength", 1.0);
	
	float vecView[3];
	float vecFwd[3];
	float vecPos[3];
	float vecVel[3];

	GetClientEyeAngles(owner, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(owner, vecPos);

	vecPos[0]+=vecFwd[0]*dir;
	vecPos[1]+=vecFwd[1]*dir;
	vecPos[2]+=vecFwd[2]*dir;
	
	float vec[3];
	GetEntPropVector(owner, Prop_Data, "m_vecVelocity", vec);

	GetEntPropVector(owner, Prop_Send, "m_vecOrigin", vecFwd);

	SubtractVectors(vecPos, vecFwd, vecVel);
	ScaleVector(vecVel, amp);

	float newvec[3];

	TeleportEntity(owner, NULL_VECTOR, NULL_VECTOR, vecVel);
	
	
	return MRES_Ignored;
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage,
		int &damagetype, int &weapon, float damageForce[3], float damagePosition[3],
		int damagecustom) {
	if (!IsValidEntity(weapon)) {
		return Plugin_Continue;
	}
	int owner = TF2_GetEntityOwner(weapon);
	if (owner < 1 || owner > MaxClients) {
		return Plugin_Continue;
	}
	
	char attr[64];
	if (!TF2CustAttr_GetString(weapon, "fan style knockback", attr, sizeof(attr))) {
		return Plugin_Continue;
	}
	
	float onhit = ReadFloatVar(attr, "onhit", 0.0);
	if (onhit == 0) {
		return Plugin_Continue;
	}
	
	float dir = ReadFloatVar(attr, "direction", 0.0);
	float amp = ReadFloatVar(attr, "strength", 1.0);
	
	float vecView[3];
	float vecFwd[3];
	float vecPos[3];
	float vecVel[3];

	GetClientEyeAngles(owner, vecView);
	GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
	GetClientEyePosition(owner, vecPos);

	vecPos[0]+=vecFwd[0]*dir;
	vecPos[1]+=vecFwd[1]*dir;
	vecPos[2]+=vecFwd[2]*dir;
	
	float vec[3];
	GetEntPropVector(owner, Prop_Data, "m_vecVelocity", vec);

	GetEntPropVector(owner, Prop_Send, "m_vecOrigin", vecFwd);

	SubtractVectors(vecPos, vecFwd, vecVel);
	ScaleVector(vecVel, amp);

	float newvec[3];

	TeleportEntity(owner, NULL_VECTOR, NULL_VECTOR, vecVel);
	
	
	return Plugin_Continue;
}
