local hitgroups = {
    [HITGROUP_HEAD] = 2,
    [HITGROUP_STOMACH] = 1,
    [HITGROUP_LEFTARM] = 0.5,
    [HITGROUP_RIGHTARM] = 0.5,
    [HITGROUP_LEFTLEG] = 0.5,
    [HITGROUP_RIGHTLEG] = 0.5,
}

hook.Add('ScalePlayerDamage', 'damage', function( ply, hitgroup, dmginfo )
    local scale = hitgroups[hitgroup]
    if scale then dmginfo:ScaleDamage(scale) end
end)