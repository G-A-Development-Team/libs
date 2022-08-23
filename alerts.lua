local function using(pkgn) file.Write( "\\using/json.lua", http.Get( "https://raw.githubusercontent.com/G-A-Development-Team/libs/main/json.lua" ) ) LoadScript("\\using/json.lua") local pkg = json.decode(http.Get("https://raw.githubusercontent.com/G-A-Development-Team/Using/main/using.json"))["pkgs"][ pkgn ] if pkg ~= nil then file.Write( "\\using/" .. pkgn .. ".lua", http.Get( pkg ) ) LoadScript("\\using/" .. pkgn .. ".lua") else print("[using] package doesn't exist. {" .. pkgn .. "}") end end

using "Overlay"

local alert = Overlay:AddComponent("window_test", Window((GetScreenWidth()/2)-(350/2), (GetScreenHeight()/2)-(200/2) - 50, 350, 200, {
    Title = "Do you accept the torture?",
    Move = false,
}))

alert:AddComponent("label_info", Label(10, 10, {
    Text = "An example of text is the words in a book.",
    Color = {255, 255, 255, 255},
}))

alert:AddComponent("label_info2", Label(10, 30, {
    Text = "An example of text is the words in a book.",
    Color = {255, 255, 255, 255},
}))

alert:AddComponent("button_yes", Button(10, 130, 100, 30, {
    Text = "Yes",
    Click = function() 
        alert:SetVisible(false)
    end,
}))

alert:AddComponent("button_no", Button(240, 130, 100, 30, {
    Text = "No",
    Click = function() 
        
    end,
}))
