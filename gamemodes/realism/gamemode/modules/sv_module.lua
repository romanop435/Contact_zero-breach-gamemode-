print("loading sv_module finish")
concommand.Add("getpos2", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTraceNoCursor()
    local ent = tr.Entity

    if IsValid(ent) then
        ply:ChatPrint(tostring(ent:GetPos()))
        ply:ChatPrint(tostring(ent:GetAngles()))
        ply:ChatPrint(ent:MapCreationID(), ent:GetClass())
    else
        ply:ChatPrint("Vector(" .. tr.HitPos.x .. ", " .. tr.HitPos.y .. ", " .. tr.HitPos.z .. "),")
    end
end)