class_plantedC = "C_PlantedC4"

timePlanted = 0 
defusing = false 
ended = false

function UpdateBombInfo()
    local pC4               = (entities.FindByClass("C_C4"))[1];
    local pPlantedC4        = (entities.FindByClass(class_plantedC))[1];
    if not pC4 and not pPlantedC4 then
        g_iBombState = BOMB_NOTFOUND;
        return;

    elseif pPlantedC4 then
        g_vecBombPosition = pPlantedC4:GetAbsOrigin();

        if not pPlantedC4:GetPropBool("m_bBombTicking") then
            g_iBombState = BOMB_DEAD;
        
        elseif pPlantedC4:GetPropBool("m_bBeingDefused") then
            defusing = true ended = false
        else
			defusing = false 
			ended = false
			[[PLANTED]]
			timePlanted = globals.CurTime() ended = false
        end

        return;
    end
end

function BombDamage(Bomb, Player)

    local playerOrigin = Player:GetAbsOrigin()
    local bombOrigin = Bomb:GetAbsOrigin()

	local C4Distance = math.sqrt((bombOrigin.x - playerOrigin.x) ^ 2 + 
	(bombOrigin.y - playerOrigin.y) ^ 2 + 
	(bombOrigin.z - playerOrigin.z) ^ 2);

	local Gauss = (C4Distance - 75.68) / 789.2 
	local flDamage = 450.7 * math.exp(-Gauss * Gauss);

		if Player:GetProp("m_ArmorValue") > 0 then

			local flArmorRatio = 0.5;
			local flArmorBonus = 0.5;

			if Player:GetProp("m_ArmorValue") > 0 then
			
				local flNew = flDamage * flArmorRatio;
				local flArmor = (flDamage - flNew) * flArmorBonus;
			 
				if flArmor > Player:GetProp("m_ArmorValue") then
				
					flArmor = Player:GetProp("m_ArmorValue") * (1 / flArmorBonus);
					flNew = flDamage - flArmor;
					
				end
			 
			flDamage = flNew;

			end

		end 
		
	return math.max(flDamage, 0);
	
end

client.AllowListener("bomb_planted")
client.AllowListener("bomb_begindefuse")
client.AllowListener("bomb_abortdefuse") 
client.AllowListener("bomb_exploded")
client.AllowListener("round_officially_ended")
client.AllowListener("bomb_defused") 