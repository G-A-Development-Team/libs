RunScript("GA/libs/Move-Resize.lua")

local ColorPalette = {
    Background = function() draw.Color(17, 17, 17, 245) end,
    TitleBar = function() draw.Color(250, 13, 13, 200) end,
    TitleBarText = function() draw.Color(255, 255, 255, 255) end,

}

local FontPalette = {
    TitleBar = draw.CreateFont("Bahnschrift", 19, 100),
}

local MainWindow = {
	X = 0,
	Y = 0,
	W = 200,
	H = 500,
	MinW = 100,
	MinH = 100,
	MaxW = 700,
	MaxH = 700,
	Resize = false,
	Move = false,
    OverrideLocation = true,

    Location = function(X, Y, W, H)
        local MENU = gui.Reference('MENU')
        local x, y = MENU:GetValue()
        
        return x - W - 5, y
    end,

    Draw = function (X, Y, W, H)

        --Background
        ColorPalette.Background()
        draw.RoundedRectFill(X, Y, X + W, Y + H, 6, 6, 6, 6, 6)
        --Title Bar
        ColorPalette.TitleBar()
        draw.RoundedRectFill(X, Y, X + W, Y + 46, 6, 5, 5, 0, 0)

        --Title
        draw.SetFont(FontPalette.TitleBar);
        ColorPalette.TitleBarText()
        draw.TextShadow(X + 8, Y + 15, "G-A Development Scripts");

    end,
}

table.insert(windows, MainWindow)
