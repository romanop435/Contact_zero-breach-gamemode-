if SERVER then return end

hook.Add("SpawnMenuOpen", "CZ_BlockSpawnMenu", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:IsSuperAdmin() then
		return false
	end
end)
