ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Keycard"
ENT.Spawnable = true
ENT.Category = "Contact Zero"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "KeycardLevel")
	if SERVER then
		self:SetKeycardLevel(1)
	end
end
