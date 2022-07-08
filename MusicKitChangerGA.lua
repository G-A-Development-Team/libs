-----------------------------------------------
---------  Music Kit Changer  -----------------
---------    Created By:    -------------------
---------     Agentsix1      ------------------
---------   Date: 7/7/2022   ------------------
-----------------------------------------------
--------- Tested By:         ------------------
--------- CarterPoe          ------------------
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
MusicKitChanger.Json = http.Get('https://raw.githubusercontent.com/G-A-Development-Team/libs/main/music.json')
print(json.decode(MusicKitChanger.Json))
MusicKitChanger.List = json.decode(MusicKitChanger.Json)['kits']['kits']
MusicKitChanger.Gui = gui.Combobox(gui.Reference("Visuals", "Other", "Extra"), "MKC_KitName", "Music Kit Changer", unpack(MusicKitChanger.List))
MusicKitChanger.Gui:SetDescription("Changes your music kit.")
MusicKitChanger.Fire = function()
    if entities.GetLocalPlayer() == nil then return end
    local kit = MusicKitChanger.Gui:GetValue()
    if kit == 0 then return end
    entities.GetPlayerResources():SetPropInt(kit, "m_nMusicID", client.GetLocalPlayerIndex())
end


callbacks.Register("Draw", function()
    MusicKitChanger.Fire()
end)
