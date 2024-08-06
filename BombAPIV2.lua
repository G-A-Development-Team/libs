timePlanted = 0 
defusing = false 
ended = false

function UpdateBombInfo()
    local pC4               = (entities.FindByClass("C_C4"))[1];
    local pPlantedC4        = (entities.FindByClass("C_PlantedC4"))[1];
    if not pC4 and not pPlantedC4 then
		timePlanted = 0
        --g_iBombState = BOMB_NOTFOUND;
        return;

    elseif pPlantedC4 then

        if not pPlantedC4:GetPropBool("m_bBombTicking") then
            --g_iBombState = BOMB_DEAD;
        
        elseif pPlantedC4:GetPropBool("m_bBeingDefused") then
            defusing = true ended = false
        else
			defusing = false 
			ended = false
			--PLANTED--
			if timePlanted == 0 then
				timePlanted = globals.CurTime() 
			end
			ended = false
        end

        return;
    end
end

local m = {
	-- Updated August-6th-2024 @12:42 EST
	-- map_showbombradius || bombradius @ game/csgo/maps/<map>.vpk/entities/default_ents.vents_c ## only lists if value is overwritten
	["maps/de_ancient.vpk" ] = 650 * 3.5;
	["maps/de_anubis.vpk"  ] = 450 * 3.5;
	["maps/de_assembly.vpk"] = 500 * 3.5;
	["maps/de_inferno.vpk" ] = 620 * 3.5;
	["maps/de_mills.vpk"   ] = 500 * 3.5;
	["maps/de_mirage.vpk"  ] = 650 * 3.5;
	["maps/de_nuke.vpk"    ] = 650 * 3.5;
	["maps/de_overpass.vpk"] = 650 * 3.5;
	["maps/de_thera.vpk"   ] = 500 * 3.5;
	["maps/de_vertigo.vpk" ] = 500 * 3.5;
};

function GetBombRadius()
	return m[engine.GetMapName()] or 1750;
end

function BombDamage(pPlantedC4, pLocalPlayer)

    local iArmor = pLocalPlayer:GetPropInt("m_ArmorValue");

    local flBombRadius = GetBombRadius();
    local flDistance = (pPlantedC4:GetAbsOrigin() - (pLocalPlayer:GetAbsOrigin() + pLocalPlayer:GetPropVector("m_vecViewOffset"))):Length();
    local flDamage = (flBombRadius / 3.5) * math.exp(flDistance^2 / (-2 * (flBombRadius / 3)^2));

    if(iArmor == 0)then
        return flDamage;
    end

    local flReducedDamage = flDamage / 2;
    
    -- We do not have enough armor to cover the full damage of the bomb
    if(iArmor < flReducedDamage)then
        local flFraction = iArmor / flReducedDamage;
        return (flFraction * flReducedDamage) + (1 - flFraction) * flDamage;
    end

    return flReducedDamage;
	
end

--[[
client.AllowListener("bomb_planted")
client.AllowListener("bomb_begindefuse")
client.AllowListener("bomb_abortdefuse") 
client.AllowListener("bomb_exploded")
client.AllowListener("round_officially_ended")
client.AllowListener("bomb_defused") 
--]]
