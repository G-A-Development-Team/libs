local Object = {
	X = 0,
	Y = 0,
	W = 100,
	H = 100,
	MinW = 100,
	MinH = 100,
	MaxW = 700,
	MaxH = 700,
	Resize = true,
	Move = false
}

local function Move()
	if Object.Move then
		if input.IsButtonDown(1) then
			mouseX, mouseY = input.GetMousePos();
			if shouldDrag then
				Object.X = mouseX - dx;
				Object.Y = mouseY - dy;
			end
			if mouseX >= Object.X and mouseX <= Object.X + Object.W and mouseY >= Object.Y and mouseY <= Object.Y + Object.H then
				shouldDrag = true;
				dx = mouseX - Object.X;
				dy = mouseY - Object.Y;
			end
		else
			shouldDrag = false;
		end
	end
end

local function Resize()
	if Object.Resize then
		draw.Color(255,0,0,255)
		draw.FilledRect(Object.X+Object.W-10, Object.Y+Object.H-10, Object.X+Object.W, Object.Y+Object.H)
		local resizex = Object.X+Object.W-10
		local resizey = Object.Y+Object.H-10
		local resizew = Object.X+Object.W
		local resizeh = Object.Y+Object.H
		if input.IsButtonDown(1) then
			mouseX, mouseY = input.GetMousePos();
			if shouldDrag then
				Object.W = mouseX - dx;
				Object.H = mouseY - dy;
				if Object.W < Object.MinW then Object.W = Object.MinW end
				if Object.W > Object.MaxW then Object.W = Object.MaxW end
				if Object.H < Object.MinW then Object.H = Object.MinW end
				if Object.H > Object.MaxW then Object.H = Object.MaxW end
			end
			if mouseX >= resizex and mouseX <= resizex + resizew and mouseY >= resizey and mouseY <= resizey + resizeh then
				shouldDrag = true;
				dx = mouseX - Object.W;
				dy = mouseY - Object.H;
			end
		else
			shouldDrag = false;
		end
	end
end

callbacks.Register("Draw", function()
	draw.Color(255,255,255,255)
	draw.FilledRect(Object.X, Object.Y, Object.X+Object.W, Object.Y+Object.H)
	Resize()
	Move()
end)
