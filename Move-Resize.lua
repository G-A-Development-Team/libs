local MainWindow = {
    OverrideLocation = true,
	X = 0,
	Y = 0,
	W = 100,
	H = 100,
	MinW = 100,
	MinH = 100,
	MaxW = 700,
	MaxH = 700,
	Resize = true,
	Move = true,

    Location = function()
        local MENU = gui.Reference('MENU')
        local x, y = MENU:GetValue()
        return x, y
    end,

    Draw = function (X, Y, W, H)
        draw.Color(0,255,255,255)
        draw.FilledRect(X, Y, X+10, Y+10)

    end,
}

local windows = {}

local function Move(window)
	if window.Move then
		if input.IsButtonDown(1) then
			mouseX, mouseY = input.GetMousePos();
			if shouldDrag then
				window.X = mouseX - dx;
				window.Y = mouseY - dy;
			end
			if mouseX >= window.X and mouseX <= window.X + window.W and mouseY >= window.Y and mouseY <= window.Y + window.H then
				window.Resize = false
				shouldDrag = true;
				dx = mouseX - window.X;
				dy = mouseY - window.Y;
			end
		else
			shouldDrag = false;
		end
	end
end

local function Resize(window)
	if window.Resize then
		draw.Color(255,0,0,255)
		draw.FilledRect(window.X+window.W, window.Y+window.H, window.X+window.W+10, window.Y+window.H+10)
		local resizex = window.X+window.W
		local resizey = window.Y+window.H
		local resizew = window.X+window.W+10
		local resizeh = window.Y+window.H+10
		if input.IsButtonDown(1) then
			mouseX, mouseY = input.GetMousePos();
			if shouldDrag then
				window.W = mouseX - dx;
				window.H = mouseY - dy;
				if window.W < window.MinW then window.W = window.MinW end
				if window.W > window.MaxW then window.W = window.MaxW end
				if window.H < window.MinW then window.H = window.MinW end
				if window.H > window.MaxW then window.H = window.MaxW end
			end
			if mouseX >= resizex and mouseX <= resizex + resizew and mouseY >= resizey and mouseY <= resizey + resizeh then
				window.Move = false
				shouldDrag = true;
				dx = mouseX - window.W;
				dy = mouseY - window.H;
			end
		else
			shouldDrag = false;
		end
	end
end

callbacks.Register("Draw", function()
    for i = 1, #windows do
        local window = windows[i]

        if window.OverrideLocation then
            window.X, window.Y = window.Location()
        end

        draw.Color(255,255,255,255)
        draw.FilledRect(window.X, window.Y, window.X+window.W, window.Y+window.H)
        window.Draw(window.X, window.Y, window.X+window.W, window.Y+window.H)

        if window.Resize then
            Resize(window)
        end

        if input.IsButtonReleased(1) then
            window.Move = true
            window.Resize = true
        end

        if window.Move then
            Move(window)
        end
        if input.IsButtonReleased(1) then
            window.Move = true
            window.Resize = true
        end

    end
end)

--Just insert a new window and done
table.insert(windows, MainWindow)
