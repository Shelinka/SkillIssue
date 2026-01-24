local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_DEAD")

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_DEAD" then
        PlaySoundFile("Interface\\AddOns\\SkillIssue\\Ion_wisdom.ogg", "Master")
    end
end)
