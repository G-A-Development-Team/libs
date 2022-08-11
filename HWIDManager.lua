function RandomVariable(length)
	local res = ""
	for i = 1, length do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

local randTime = 0

function GenerateRandomID(amt)
	return randTime .. RandomVariable(amt) .. randTime
end

callbacks.Register("Draw", function()
	randTime = randTime + globals.TickCount() + globals.RealTime() + globals.CurTime() + globals.FrameCount() + globals.FrameTime()
	GenerateRandomID(256)
end)


