Libraries = {
    "json"   = { found = false, url = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/json.lua" },
    "string" = { found = false, url = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/string.lua" },
    "table"  = { found = false, url = "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/table.lua" }
}

file.Enumerate( function( filename )
    
    for loc, data in pairs( Libraries ) do
        if filename == "libraries/" .. loc .. ".lua" then
            Libraries[ loc ].found = true
        end
    end

end)

for loc, data in pairs( loaded ) do
    if not Libraries[ loc ].found then
        local body = http.Get( data.url )
        file.Write("libraries/" .. loc .. ".lua", body)
    end
end

for loc, data in pairs( Libraries ) do
    RunScript("libraries/" .. loc .. ".lua")
end
