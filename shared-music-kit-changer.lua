-----------------------------------------------
-----  Shared Music Kit Changer  --------------
-----        Created By:         --------------
-----        Agentsix1           --------------
-----       Date: 7/29/2022      --------------
-----------------------------------------------
-----     Tested By:             --------------
-----     CaterPoe               --------------
-----------------------------------------------
--------------------------------------------
--          READ JSON EXECUTION           --
-- Credit To: Chicken4676                 --
-- Credit To: tg021 (Github)              --
--------------------------------------------

local json_lib_installed = false
file.Enumerate(function(filename)
    if filename == "libraries/json.lua" then
        json_lib_installed = true
    end
end)

if not json_lib_installed then
    local body = http.Get("https://raw.githubusercontent.com/G-A-Development-Team/libs/main/json.lua")
    file.Write("libraries/json.lua", body)
end

RunScript("libraries/json.lua")


--------------------------------------------
--          READ JSON EXECUTION           --
--------------------------------------------
local MusicKitChanger = {}
local json_kits = http.Get('https://raw.githubusercontent.com/G-A-Development-Team/libs/main/music.json')
local kits = json.decode(json_kits)['kits']['kits']
local gui_ref = gui.Reference("Visuals", "Other", "Extra")
local gui_kits = gui.Combobox(gui_ref, "MKC_KitName", "Music Kit Changer", unpack(kits))
gui_kits:SetDescription("Changes your music kit.")
local gui_shared = gui.Checkbox(gui_ref, "MKC_shared", "Share your kit with others?", false)
gui_kits:SetDescription("Changes your music kit.")


local user = {}
local kit = {}
local aw = {}
local domain = http.Get("https://raw.githubusercontent.com/G-A-Development-Team/libs/main/mkc_domain")
local cur_kit = -1

local function updateKit()
	if cur_kit == gui_kits:GetValue() then return end
	if gui_kits:GetValue() > 0 then
		if gui_shared:GetValue() then
			if entities.GetLocalPlayer() == nil  then return end
			local lp = entities.GetLocalPlayer()
			local lp_data = client.GetPlayerInfo(lp:GetIndex())
			http.Get(domain .. "setkit.php?steam=" .. lp_data['SteamID'] .. "&kit=" .. gui_kits:GetValue())
			cur_kit = gui_kits:GetValue()
		end
	end
end


-- Updates User and Kit arrays at the begining of every round
callbacks.Register("FireGameEvent", function(e)
	if gui_shared:GetValue() then
		if e == nil then return end
		if e:GetName() ~= "round_start" then
			return
		end
		user = {}
		kit = {}
		aw = {}
		local players = entities.FindByClass("CCSPlayer")
		for i = 1, #players do
			local player = players[i]
			if player:GetName() ~= "GOTV" then
				if user[i] == nil then
					local data = client.GetPlayerInfo(player:GetIndex())
					user[i] = data['SteamID']
					aw[i] = -1
					if kit[i] == nil then
						kit[i] = entities.GetPlayerResources():GetPropInt("m_nMusicID", player:GetIndex())
					end
					if user[i] ~= nil then
					end
				end
			end
		end
	end
end)

-- Gets and Sets the players music kit
local function setKit()
	if gui_shared:GetValue() then
		local players = entities.FindByClass("CCSPlayer")
		for i = 1, #players do
			local player = players[i]
			if player:GetName() ~= "GOTV" then
				if user[i] ~= nil then
					if aw[i] == -1 then
						local get_val = http.Get(domain .. "getkitv2.php?steam=" .. user[i])
						if get_val ~= nil then
							if get_val ~= "notfound" then
								kit[i] = get_val
								aw[i] = "FOUND"
								entities.GetPlayerResources():SetPropInt(kit[i], "m_nMusicID", player:GetIndex())
							else
								aw[i] = "NOT FOUND"
							end
						else
							aw[i] = "NOT FOUND"
						end
					end
				end
			end
		end
	end
end


local function applyKit()
	if entities.GetLocalPlayer() == nil then return end
	entities.GetPlayerResources():SetPropInt(gui_kits:GetValue(), "m_nMusicID", client.GetLocalPlayerIndex())
end

callbacks.Register("Draw", function()
	updateKit()
	setKit()
	applyKit()
end)

client.AllowListener("round_start")
