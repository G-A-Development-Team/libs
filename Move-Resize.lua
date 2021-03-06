windows = {}

local function Move(window)
	if window.Move then
		if input.IsButtonDown(1) then
			mouseX, mouseY = input.GetMousePos();
			if shouldDrag then
				window.X = mouseX - dx;
				window.Y = mouseY - dy;
			end
			if mouseX >= window.X and mouseX <= window.X + window.W and mouseY >= window.Y and mouseY <= window.Y + window.H then
				if window.BoundsHeight ~= nil then
					if mouseX >= window.X and mouseX <= window.X + window.W and mouseY >= window.Y and mouseY <= window.Y + window.BoundsHeight then
						window.Resize = false
						shouldDrag = true;
						dx = mouseX - window.X;
						dy = mouseY - window.Y;
						if window.Form.Dragging ~= nil then
							window.Form.Dragging = true
						end
					end
					
				else
					if window.BoundsWidth ~= nil then
						if mouseX >= window.X and mouseX <= window.X + window.BoundsWidth and mouseY >= window.Y and mouseY <= window.Y + window.H then
							window.Resize = false
							shouldDrag = true;
							dx = mouseX - window.X;
							dy = mouseY - window.Y;
							if window.Form.Dragging ~= nil then
								window.Form.Dragging = true
							end
						end
					else
						window.Resize = false
						shouldDrag = true;
						dx = mouseX - window.X;
						dy = mouseY - window.Y;
						if window.Form.Dragging ~= nil then
							window.Form.Dragging = true
						end
					end
				end
			else
				if window.Form.Dragging ~= nil then
					window.Form.Dragging = true
				end
			end
		else
			shouldDrag = false;
			if window.Form.Dragging ~= nil then
				window.Form.Dragging = false
			end
			
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
		
		if window.Form.Visible ~= nil then
			if window.Form.Visible ~= true then
				return
			end
		end

        if window.OverrideLocation then
            window.X, window.Y = window.Location(window.X, window.Y, window.W, window.H)
        end

		if window.Form ~= nil then
			window.X =  window.Form.Location.X
			window.Y = window.Form.Location.Y
			window.W = window.Form.Size.Width
			window.H = window.Form.Size.Height
			window.MinW = window.Form.MinimumSize.Width
			window.MinH = window.Form.MinimumSize.Height
			window.MaxW = window.Form.MaximumSize.Width
			window.MaxH = window.Form.MaximumSize.Height
		end

		window.Draw(window.X, window.Y, window.W, window.H)

		if window.Form ~= nil then
			if window.Form.BorderStyle == "Sizable" then
				Resize(window)
			end
		else
			if window.Resize then
				Resize(window)
			end
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
		if window.Form ~= nil then
			window.Form.Location.X = window.X
			window.Form.Location.Y = window.Y
			window.Form.Size.Width = window.W
			window.Form.Size.Height = window.H
			window.Form.MinimumSize.Width = window.MinW
			window.Form.MinimumSize.Height = window.MinH
			window.Form.MaximumSize.Width = window.MaxW
			window.Form.MaximumSize.Height = window.MaxH
		end

    end
end)
