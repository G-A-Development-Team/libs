file.Write("\\Cache/CustomObject.lua", http.Get("https://github.com/G-A-Development-Team/SharedMusicKitChanger/raw/main/custom-object.lua"))
LoadScript("\\Cache/CustomObject.lua")

local _clock_data = 23480913

local LoadedIcon
function gui.PictureBox(ref, x, y, w, h, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
			draw.Color(255, 255, 255, 255)
			draw.SetTexture(options.texture)
			draw.FilledRect(x, y, x+w, y+h)
			draw.SetTexture(nil)
		--end	
	end
	local options = options or {}
	
	local vars = {
		texture = texture,
	}
	local custom = gui._Custom(ref, "", "", x, y, w, h, paint, vars)
		
	function custom:SetOptions(options)
		vars.texture = options.texture or vars.texture
		self:SetSize(x+w, y+h)
	end
		
	return custom
end

local group_font_default = draw.CreateFont("Bahnschrift", 15, 100)
function gui.CustGroupBox(ref, var, x, y, w, h, text, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
			draw.Color(20, 20, 20, 150)
			draw.RoundedRectFill(x, y, x+w, y+h, 8)
			draw.Color(80, 80, 80, 255)
			draw.Line(x+15, y+30, x+w-15, y+30)
			draw.Color(255, 255, 255, 255)
			draw.SetFont(group_font_default)
			draw.Text(x+25,y+15, text)
	end
	local options = options or {}
	
	local vars = {
		text = text,
		w = w,
		h = h
	}
	local custom = gui._Custom(ref, var, "", x, y, w, h, paint, vars)
	local function paint(x, y, x2, y2, active, self, width, height)
	end
	gui._Custom(ref, "", "", x, y+h, 0, 0, paint, vars)
	
	function custom:SetWidth(w)
		var.w = w
	end
		
	function custom:SetHeight(h)
		var.h = h
	end
	
	function custom:SetOptions(options)
		vars.text = options.text or vars.text
		self:SetSize(x+w, y+h)
	end
		
	return custom
end


local specialtext_font_default = draw.CreateFont("Bahnschrift", 20, 100)
function gui.SpecialText(ref, var, x, y, text, r, g, b, a, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
			draw.Color(r, g, b, a)
			draw.SetFont(specialtext_font_default)
			draw.Text(x,y, text)
	end
	local options = options or {}
	
	local vars = {
		text = text,
		r = r,
		g = g,
		b = b,
		a = a,
	}
	local text_w, text_h = draw.GetTextSize(text)
	local custom = gui._Custom(ref, var, "", x, y, text_w, text_h, paint, vars)
		
	function custom:SetOptions(options)
		vars.text = options.text or vars.text
		vars.r = options.r or vars.r
		vars.g = options.g or vars.g
		vars.b = options.b or vars.b
		vars.a = options.a or vars.a
		self:SetSize(text_w, text_h)
	end
		
	return custom
end

function gui.URLText(ref, var, x, y, text, r, g, b, a, url, options)
	local gui_text = gui.SpecialText(ref, var, x, y, text, r, g, b, a, options)
	
	gui_text.OnClick = function(self)
		panorama.RunScript([[
            SteamOverlayAPI.OpenUrlInOverlayOrExternalBrowser("]] .. url .. [[")
        ]])
	end
	
	return gui_text
end

local play_icon = [[
<svg x="0px" y="0px" viewBox="0 0 1000 1000" width="40" height="40"><title>Layer 1</title>
<path fill="#fff"  id="svg_1"  d="M393.9,770.4L720.7,500L393.9,229.7V770.4z M501.1,7.8C218.3,7.8,10,217.3,10,500.2c0,282.9,199.9,492,482.8,492c282.8,0,497.2-209.2,497.2-492C990,217.3,784,7.8,501.1,7.8z M501.1,929.3C264,929.3,71.9,737.2,71.9,500.1C71.9,263,264,70.9,501.1,70.9c237.1,0,429.2,192.1,429.2,429.2C930.4,737.2,738.2,929.3,501.1,929.3z"/>
</svg>
]]
local play_texture = draw.CreateTexture(common.RasterizeSVG(play_icon, 1))

function gui.PlayButton(ref, var, x, y, options)
	local function paint(x, y, x2, y2, active, self, width, height)
		local options = self.custom_vars
			
			
			draw.SetFont(specialtext_font_default)
			local tX, tY = draw.GetTextSize(options.text)
			draw.Color(255,255,255,255)
			draw.RoundedRectFill(x-2, y-2, x+tX+15+40+2, y+10+40+2, 6)
			draw.Color(0,0,0,255)
			draw.RoundedRectFill(x, y, x+tX+15+40, y+10+40, 6)
			draw.Color(255,255,255,255)
			draw.SetTexture(play_texture)
			draw.FilledRect(x+5, y+5, x+5+40, y+5+40)
			draw.SetTexture(nil)
			draw.Color(255,255,255,255)
			draw.Text(x+10+40,y+10+(10-(20/tY)), options.text)			
	end
	local options = options or {}
	
	local vars = {
		text = options.text or vars.text,
		url = options.url or vars.url
	}
	local text_w, text_h = draw.GetTextSize(options.text)
	local custom = gui._Custom(ref, var, "", x, y, text_w+30, text_h+30, paint, vars)
		
	function custom:SetOptions(options)
		vars.text = options.text or vars.text
		vars.url = options.url or vars.url
		self:SetSize(text_w+30, text_h+30)
	end
	
	function custom:SetURL(url)
		vars.url = url
	end
	
	function custom:SetText(text)
		vars.text = text
		local text_w, text_h = draw.GetTextSize(options.text)
		self:SetSize(text_w+30, text_h+30)
	end
	
	function custom:GetOptions()
		return vars
	end
		
	return custom
end
local urlPlayCool = 500
local urlPlayLastCool = 0
function gui.URLPlayButton(ref, var, x, y, options)
	local gui_text = gui.PlayButton(ref, var, x, y, options)
	gui_text.OnClick = function(self)
		if urlPlayLastCool >_clock_data then 
			
			print( 'COOL     ' .. urlPlayLastCool )
			print( 'CLOCK    ' .. _clock_data )
			return 
		else 
			urlPlayLastCool = _clock_data+urlPlayCool 
		end
		local vars = self:GetOptions()
		print('Text ' .. vars.text .. ' URL ' .. vars.url)
		panorama.RunScript([[
            SteamOverlayAPI.OpenUrlInOverlayOrExternalBrowser("]] .. url .. [[")
        ]])
	end
	
	return gui_text
end

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


local gui_ref = gui.Reference("Visuals")
local gui_tab = gui.Tab(gui_ref, "smkc_tab", "Music Kit Changer")
local group_change = gui.CustGroupBox(gui_tab,"smkcv_group", 16, 32, 760, 342, "Music Kit Group")
local groupX, groupY = group_change:GetPos()
--local gui_changergroup = gui.Groupbox(gui_tab,"Music Kit Changer", 16, 16, 610, 900)
local kits_sorted = http.Get('https://raw.githubusercontent.com/G-A-Development-Team/SharedMusicKitChanger/main/music_kits.json?token=GHSAT0AAAAAABWLREXWHIHYNVUE4K43BAOSYW4NFEQ')
local kits = json.decode(kits_sorted)['kits']['kits']
local gui_kits_combo = gui.Combobox(gui_tab, "smkc_kitslist", "Music Kits", unpack(kits))
gui_kits_combo:SetWidth(280)
gui_kits_combo:SetPosX(groupX+300)
gui_kits_combo:SetPosY(groupY+32)
local kit_details = http.Get('https://raw.githubusercontent.com/G-A-Development-Team/SharedMusicKitChanger/main/kit_details.json')
local kits_details = json.decode(kit_details)['details']

local gui_shared = gui.Checkbox(gui_tab, "smkc_share", "Share your kit?", false)
gui_shared:SetPosX(groupX+496)
gui_shared:SetPosY(groupY-24)

local picture = gui.PictureBox(gui_tab, groupX+64, groupY+48, 250, 250)
local mvp_button = gui.URLPlayButton(gui_tab, "play_mvp", groupX+300, groupY+80, {text = "MVP Award", url = "https://google.com"})
local loss_button = gui.URLPlayButton(gui_tab, "play_mvp", groupX+300, groupY+80+49, {text = "Round Loss", url = "https://google.com"})
local death_button = gui.URLPlayButton(gui_tab, "play_mvp", groupX+300, groupY+80+98, {text = "Death Theme", url = "https://google.com"})


local settings = gui.CustGroupBox(gui_tab,"smkcv_settings", 16, 322, 760, 342, "Settings")
local groupX, groupY = settings:GetPos()
local settings_test = gui.Checkbox(gui_tab, "smkcv_test", "Test thing", true)
settings_test:SetPosX(groupX+16)
settings_test:SetPosY(groupY+32)


local blacklist = gui.CustGroupBox(gui_tab,"smkcv_blacklist", 16, 612, 760, 342, "Blacklist")

local gui_add = gui.Button(gui_tab, "Add", function() blacklist:SetWidth(10) print("set width") end)
local gui_add = gui.Button(gui_tab, "Add", function() blacklist:SetHeight(200) print("set heigfht")end)

function ecb_combobox_a_Changed()
	local img_url = kits_details[kits[gui_kits_combo:GetValue()+1]]['img']
    iconRGBA, iconWidth, iconHeight = common.DecodePNG(http.Get(img_url))
	iconTexture = draw.CreateTexture(iconRGBA, iconWidth, iconHeight)
	LoadedIcon = iconTexture
	picture:SetOptions({texture = LoadedIcon})
	mvp_button:SetURL(kits_details[kits[gui_kits_combo:GetValue()+1]]['Round MVP anthem'])
	loss_button:SetURL(kits_details[kits[gui_kits_combo:GetValue()+1]]['Round Loss'])
	death_button:SetURL(kits_details[kits[gui_kits_combo:GetValue()+1]]['Deathcam'])
end

	
	
callbacks.Register("Draw", function()
	_clock_data = _clock_data+1
    -- We are gonna check for a value and see if it has changed
    if ecb_value_a ~= gui_kits_combo:GetValue() then
        ecb_value_a = gui_kits_combo:GetValue();
        ecb_combobox_a_Changed();
   end
	
end)
