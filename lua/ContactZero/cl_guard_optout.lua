if SERVER then return end

if not ConVarExists("cz_optout_scp") then
	CreateClientConVar("cz_optout_scp", "0", true, false, "Do not spawn as SCP")
end

local function syncScpOptOut()
	local convar = GetConVar("cz_optout_scp")
	if not convar then return end
	net.Start("CZ_SetScpOptOut")
	net.WriteBool(convar:GetBool())
	net.SendToServer()
end

hook.Add("InitPostEntity", "CZ_SyncScpOptOutInit", function()
	timer.Simple(0, syncScpOptOut)
end)

cvars.AddChangeCallback("cz_optout_scp", function()
	syncScpOptOut()
end, "CZ_SyncScpOptOut")
