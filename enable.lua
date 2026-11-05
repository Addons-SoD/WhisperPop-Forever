------------------------------------------------------------
-- enable.lua
--
-- Standalone auto-enable for WhisperPop.
-- When BigFoot is absent, this file activates the addon
-- at PLAYER_LOGIN by calling WhisperPop_Toggle(1).
-- When BigFoot is present, BigFoot controls the toggle
-- and this file does nothing.
------------------------------------------------------------

if not BigFoot then
	local f = CreateFrame("Frame")
	f:RegisterEvent("PLAYER_LOGIN")
	f:SetScript("OnEvent", function(self)
		self:UnregisterEvent("PLAYER_LOGIN")
		if WhisperPop_Toggle then
			WhisperPop_Toggle(1)
		end
	end)
end
