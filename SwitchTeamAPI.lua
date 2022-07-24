SwitchTeamCallback = nil

callbacks.Register("FireGameEvent", function(event)
	if event:GetName() == "round_end" then SwitchTeamCallback() end
	if event:GetName() == "round_start" then SwitchTeamCallback() end
	if event:GetName() == "round_poststart" then SwitchTeamCallback() end
	if event:GetName() == "round_prestart" then SwitchTeamCallback() end
	if event:GetName() == "teamplay_round_start" then SwitchTeamCallback() end
	if event:GetName() == "round_officially_ended" then SwitchTeamCallback() end
	if event:GetName() == "teamchange_pending" then SwitchTeamCallback() end
	if event:GetName() == "jointeam_failed" then SwitchTeamCallback() end
	if event:GetName() == "player_death" then SwitchTeamCallback() end
	if event:GetName() == "cs_win_panel_round" then SwitchTeamCallback() end
end)

client.AllowListener("cs_win_panel_round")
client.AllowListener("player_death")
client.AllowListener("jointeam_failed")
client.AllowListener("teamchange_pending")
client.AllowListener("round_officially_ended")
client.AllowListener("teamplay_round_start")
client.AllowListener("round_prestart")
client.AllowListener("round_poststart")
client.AllowListener("round_start")
client.AllowListener("round_end")