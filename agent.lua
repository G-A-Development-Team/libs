--@Version[000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004]

local gun_info_json_url = 'https://steamcommunity.com/market/listings/730/@@weapon@@%20%7C%20@@skin@@%20%28@@wear@@%29/render?start=0&count=1&currency=3&language=english&format=json'


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
	local body = http.Get("https://raw.githubusercontent.com/Aimware0/aimware_scripts/main/libraries/json.lua")
	file.Write("libraries/json.lua", body)
end

RunScript("libraries/json.lua")


--------------------------------------------
--          READ JSON EXECUTION           --
--------------------------------------------

function file.Exists(file_name)
  local exists = false
  file.Enumerate(function(_name)
    if file_name == _name then
      exists = true
    end
  end)
  return exists
end

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

function getImageURL(img)
	return "https://community.akamai.steamstatic.com/economy/image/" .. img
end

function URLtoSVG(img)
	return common.DecodePNG( http.Get( svgData ) )
end

function getWeaponInfo(weapon, skin, wear)
	local weaponInfo = gun_info_json_url
	weaponInfo = weaponInfo:gsub('@@weapon@@', weapon)
	weaponInfo = weaponInfo:gsub('@@skin@@', skin)
	weaponInfo = weaponInfo:gsub('@@wear@@', wear)
	return http.Get( weaponInfo )
end

--Executes code to get gun info

