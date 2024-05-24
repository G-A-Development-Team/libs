Libraries = {
    "json" = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/json.lua",
    "string" = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/string.lua",
    "table" = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/table.lua"
}

local created = {}

file.Enumerate( function( filename )
    for loc, url in pairs( Libraries ) do
        if filename == "libraries/" .. loc .. ".lua" then
            loaded[ loc ] = url
        end
    end
end)

for loc, url in pairs( loaded ) do
    local body = http.Get( url )
    file.Write("libraries/" .. loc .. ".lua", body)
end

for loc, url in pairs( Libraries ) do
    RunScript("libraries/" .. loc .. ".lua")
end
