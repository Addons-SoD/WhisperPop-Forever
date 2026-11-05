------------------------------------------------------------
-- MainFrame.lua
--
-- Abin
-- 2010-9-28
------------------------------------------------------------

local L = WHISPERPOP_LOCALE
local WHISPERPOPHOLDTIME = 0.1;					--小喇叭刷新flash
local function SetFrameMobile(frame)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
end

--[[	bf@178.com
-- Tip frame
local tipFrame = CreateFrame("Button", "WhisperPopTipFrame", UIParent)
WhisperPop.tipFrame = tipFrame
SetFrameMobile(tipFrame)
tipFrame:SetPoint("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 0, -2)
tipFrame:SetWidth(16)
tipFrame:SetHeight(16)
tipFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

tipFrame.icon = tipFrame:CreateTexture(tipFrame:GetName().."Icon", "ARTWORK")
tipFrame.icon:SetAllPoints(tipFrame)
tipFrame.icon:SetTexture("Interface\\Icons\\INV_Letter_18")
tipFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
tipFrame.icon:SetDesaturated(true)

tipFrame.text = tipFrame:CreateFontString(tipFrame:GetName().."Text", "ARTWORK", "GameFontGreenSmall")
tipFrame.text:SetPoint("LEFT", tipFrame, "RIGHT")

local function TipFrame_OnUpdate(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if self.elapsed > 0.5 then
		self.elapsed = 0
		if self.icon:IsShown() then
			self.icon:Hide()
		else
			self.icon:Show()
		end
	end
end

function tipFrame:SetTip(name)
	if type(name) ~= "string" then
		name = nil
	end

	if name == self.name then
		return
	end

	self.name = name
	self.elapsed = 0
	self.icon:Show()
	if name then
		self.icon:SetDesaturated(false)
		self.text:SetText(name)
		self:SetScript("OnUpdate", TipFrame_OnUpdate)
	else
		self.icon:SetDesaturated(true)
		self.text:SetText()
		self:SetScript("OnUpdate", nil)
	end
end

tipFrame:SetScript("OnClick", function(self)
	GameTooltip:Hide()
	WhisperPop:ToggleFrame()
end)

tipFrame:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("WhisperPop "..WhisperPop.version)
	GameTooltip:AddLine(L["tip tooltip"], 0, 1, 0, 1)
	GameTooltip:Show()
end)

tipFrame:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

--tipFrame:SetTip("Test")
]]

-- Main frame
local frame = WhisperPop:CreateCommonFrame("WhisperPopFrame", UIParent, L["title"]..WhisperPop.version)
WhisperPop.mainFrame = frame
table.insert(UISpecialFrames, frame:GetName())
SetFrameMobile(frame)
frame:SetToplevel(true)
frame:SetFrameStrata("DIALOG")
frame:SetPoint("CENTER", 0, -20)

-- Player list
local list = UICreateVirtualScrollList(frame:GetName().."List", frame, 10)
WhisperPop.list = list
list:SetHeight(200)
list:SetPoint("TOPLEFT", 7, -28)
list:SetPoint("TOPRIGHT", -7, -28)

local topLine = list:CreateTexture(nil, "ARTWORK")
topLine:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-Spacer")
topLine:SetHeight(16)
topLine:SetPoint("LEFT", list, "TOPLEFT", -1, 5)
topLine:SetPoint("RIGHT", list, "TOPRIGHT", 1, 5)

local bottomLine = list:CreateTexture(nil, "ARTWORK")
bottomLine:SetTexture("Interface\\OptionsFrame\\UI-OptionsFrame-Spacer")
bottomLine:SetHeight(16)
bottomLine:SetPoint("LEFT", list, "BOTTOMLEFT", -1, -2)
bottomLine:SetPoint("RIGHT", list, "BOTTOMRIGHT", 1, -2)

local function CompareData(data, name)
	if type(name) == "number" then
		return data.BNguid == name
	else
		return data.name == name
	end
end

local function DeleteButton_OnClick(self)
	WhisperPop.messageFrame:Hide()
	local data = self:GetParent().data
	if data then
		-- WoW Forever: BN 显示名可能来自 C_BattleNet，按 BNguid 删除更可靠。
		local key = (data.BNguid and data.BNguid > 0) and data.BNguid or data.name
		list:RemoveData(list:FindData(key, CompareData))
	end
	WhisperPop:OnListUpdate()
end

-- Show the help-tip
local function WhisperPop_ShowHelpTip(owner, ...)
	if type(owner) == "table" and type(owner.GetObjectType) == "function" then -- make sure owner if a frame
		if owner:GetBottom() < 120 then
			GameTooltip:SetOwner(owner, "ANCHOR_RIGHT", -2 - owner:GetWidth(), 2);
		else
			GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT", -2 - owner:GetWidth(), -2);
		end

		GameTooltip:ClearLines();
		GameTooltip:AddLine(L["help tip"]);

		local lines = { ... };
		for i = 1, #lines do
			GameTooltip:AddLine(lines[i], 1, 1, 1, 1);
		end

		GameTooltip:Show();
	end
end

local function DeleteButton_OnEnter(self)
	if self:GetParent().name and WhisperPopDB["help"] then
		WhisperPop_ShowHelpTip(WhisperPopFrame, string.format(L["delete message"], self:GetParent().name));
	end
end

local function WhisperPop_StartFlash()
	local button = WhisperPopOutButton
	if not button or not button.flash then return end
	button.flashMode = true;
	button.mode = "OUT";
	button.flashTime = 0;
	button.timeToFade = 0.8;
	button.flash:Show();
end

local function WhisperPop_StopFlash()
	local button = WhisperPopOutButton
	if not button or not button.flash then return end
	button.flashMode = false;
	button.flash:Hide();
end

--如果还有被标记为new的消息 就不取消falsh
local function CheckState()
	for i,data in pairs(list.listData) do
		if data.state == "new" then
			return;
		end
	end
	WhisperPop_StopFlash();
end

function list:OnButtonCreated(button)
	WhisperPop:CreatePlayerButton(button)
	button:RegisterForClicks("AnyUp")

	local del = CreateFrame("Button", button:GetName().."Delete", button, "UIPanelCloseButton")
	button.deleteButton = del
	del:SetWidth(16)
	del:SetHeight(16)
	del:SetPoint("RIGHT")
	del:SetScript("OnClick", DeleteButton_OnClick)
	del:SetScript("OnEnter", DeleteButton_OnEnter)
	del:SetScript("OnLeave", function ()
		GameTooltip:Hide();
	end)

	button.nameText:SetPoint("RIGHT", del, "LEFT")
end

function list:OnButtonUpdate(button, data)
	if data.BNguid and data.BNguid > 0 then
		-- WoW Forever: 旧 BNGetFriendInfoByID 已移除，统一走 C_BattleNet。
		button.name = WhisperPop:GetBNetName(data.BNguid) or data.name
	else
		button.name = data.name
	end
	button:SetPlayer(data.class, button.name)
	if data.state == "new" then
		button.nameText:SetTextColor(0, 1, 0)
	elseif data.state == "read" then
		button.nameText:SetTextColor(1, 1, 1)
	elseif data.state == "send" then
		button.nameText:SetTextColor(0.5, 0.5, 0.5)
	end
end

function list:OnButtonEnter(button, data)
	local name;
	if data.BNguid and data.BNguid > 0 then
		name = WhisperPop:GetBNetName(data.BNguid) or data.name;
	else
		name = data.name;
	end
	if WhisperPop.db.receiveonly and not data.state == "read" then
		WhisperPop.messageFrame:Hide()
		return
	end

	if data.state ~= "read" then
		if data.state == "new" then
			WhisperPop:OnListUpdate()
		end
		data.state = "read"
		button.nameText:SetTextColor(1, 1, 1)
	end

	CheckState()								--bf@178.com

	WhisperPop.messageFrame:ClearAllPoints()

	if button:GetLeft() > 350 then
		WhisperPop.messageFrame:SetPoint("RIGHT", button, "LEFT", -4, 0)
	else
		WhisperPop.messageFrame:SetPoint("LEFT", button, "RIGHT", 4, 0)
	end

	WhisperPop.messageFrame:SetData(data.class, name, data.messages, data.bnFriend)
	WhisperPop.messageFrame:StopCounting()
	if name and WhisperPopDB["help"] then
		WhisperPop_ShowHelpTip(WhisperPopFrame, string.format(L["player help tip text 1"], name), string.format(L["player help tip text 2"], name), string.format(L["player help tip text 3"], name), string.format(L["player help tip text 4"], name));
	end
end

function list:OnButtonLeave(button, data)
	WhisperPop.messageFrame:StartCounting()
end

-- WoW Forever: 打开密语输入框。使用 /w 目标统一处理普通玩家和 BattleTag，
-- 避免依赖已变化的 BNplayer 链接格式（现为 name:accountID:lineID:chatType:chatTarget）。
local function OpenWhisper(name)
	-- 12.1.5 起 ChatFrame_* 全局函数被重组到 ChatFrameUtil 命名空间。
	if ChatFrameUtil and type(ChatFrameUtil.OpenChat) == "function" then
		local ok = pcall(ChatFrameUtil.OpenChat, "/w "..name)
		if ok then return end
	end
	if type(ChatFrame_OpenChat) == "function" then
		ChatFrame_OpenChat("/w "..name)
	elseif type(ChatFrame_SendTell) == "function" then
		ChatFrame_SendTell(name)
	end
end

function list:OnButtonClick(button, data, flag)
	local name, presenceID;
	if data.BNguid and data.BNguid > 0 then
		name = WhisperPop:GetBNetName(data.BNguid) or data.name;
	else
		name = data.name;
		presenceID = WhisperPop:GetBNetIDByName(data.name)
	end
	if flag == "RightButton" then
		-- Right click brings up unit drop down menu
		if data.bnFriend then
			presenceID = presenceID or data.BNguid
			-- WoW Forever: 旧签名可能已调整，做能力探测并降级到普通玩家菜单。
			local shown = presenceID and type(FriendsFrame_ShowBNDropdown) == "function"
				and pcall(FriendsFrame_ShowBNDropdown, name, 1, nil, "BN_WHISPER", nil, nil, presenceID)
			if not shown and type(FriendsFrame_ShowDropdown) == "function" then
				pcall(FriendsFrame_ShowDropdown, name, 1)
			end
		elseif type(FriendsFrame_ShowDropdown) == "function" then
			pcall(FriendsFrame_ShowDropdown, name, 1)
		end
	elseif flag == "LeftButton" then
		if IsShiftKeyDown() then
			-- Query player info
			if C_FriendList and C_FriendList.SendWho then
				C_FriendList.SendWho("n-"..name)
			elseif type(SendWho) == "function" then
				SendWho("n-"..name)
			end
		elseif IsAltKeyDown() then
			-- Invite
			if data.bnFriend then
				if type(BNInviteFriend) == "function" and data.BNguid then
					pcall(BNInviteFriend, data.BNguid)
				elseif type(FriendsFrame_BattlenetInvite) == "function" then
					pcall(FriendsFrame_BattlenetInvite, nil, data.BNguid)
				elseif C_PartyInfo and C_PartyInfo.InviteUnit then
					pcall(C_PartyInfo.InviteUnit, name)
				end
			else
				-- WoW Forever: InviteUnit 已移至 C_PartyInfo.InviteUnit。
				if C_PartyInfo and C_PartyInfo.InviteUnit then
					pcall(C_PartyInfo.InviteUnit, name)
				elseif type(InviteUnit) == "function" then
					pcall(InviteUnit, name)
				end
			end
		else
			OpenWhisper(name)
		end
	end
end

list:SetScript("OnEvent", function (self, event, text, name, _, _, _, status, _, _, _, _, _, guid, BNguid)
	local bnFriend = event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM"

	-- WoW Forever: 聊天参数可能是 secret value，必须先探测再 type()/比较。
	local textSecret, nameSecret = WhisperPop:IsSecret(text), WhisperPop:IsSecret(name)
	if WhisperPop:IsSecret(status) then status = nil end
	if WhisperPop:IsSecret(guid) then guid = nil end
	if WhisperPop:IsSecret(BNguid) then BNguid = nil end
	if type(status) ~= "string" then status = nil end
	if type(guid) ~= "string" then guid = nil end
	if type(BNguid) ~= "number" then BNguid = nil end

	if textSecret then text = WhisperPop:SanitizeText(text) end
	if nameSecret then name = WhisperPop:SanitizeName(name) end

	if type(text) ~= "string" or type(name) ~= "string" then
		return
	end
	if WhisperPop:IsIgnoredMessage(text) or status == "DEV" then
		return
	end

	-- WoW Forever: Ambiguate 仍然存在，但做能力探测以防后续移除。
	if type(Ambiguate) == "function" then
		local ok, shortName = pcall(Ambiguate, name, "none")
		if ok and shortName then name = shortName end
	end

	-- Whenever we recieve a whisper message, we check if the person is already in list, if it is, we bring it to top
	local inform = event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM"
	local timeStamp = "|cffffd200"..date().."|r"
	-- local timeStamp = "|cffffd200"..strsub(date(), 10, 17).."|r"
	local reading = WhisperPop.messageFrame:IsReading() == name
	local findData = (bnFriend and BNguid and BNguid > 0) and BNguid or name
	local idx = list:FindData(findData, CompareData)
	local data = list:GetData(idx)
	if data then
		if idx ~= 1 then
			list:ShiftData(idx, 1)
		elseif reading then
			WhisperPop.messageFrame:AddMessage(timeStamp, text, inform, bnFriend)
			WhisperPop.messageFrame:UpdateHeight()
		end
	else
		local class = WhisperPop:GetClassByGUID(guid)
		data = { name = name, class = class, messages = {}, bnFriend = bnFriend } -- Person not in list, create a new record for him
		if bnFriend then
			data.class = "BN"
			if BNguid and BNguid > 0 then
				data.BNguid = BNguid
			end
		elseif status == "GM" then
			data.class = "GM"
		end
		list:InsertData(data, 1)
	end

	table.insert(data.messages, { text = text, time = timeStamp, timeraw = time(), inform = inform })

	if inform then
		-- Replying a person removes the "new" mark from him
		data.state = "send";
		CheckState()						--bf@178.com
	else
		if not reading then
			data.state = "new"
			WhisperPop_StartFlash();		--bf@178.com
		end
	end

	list:UpdateData(1)
	WhisperPop:OnNewMessage(name, text, inform, guid, bnFriend)
	WhisperPop:OnListUpdate()
end)

-----------------------------------
-- 大脚增强及调整相关模块
--
-- 增加按钮帮助说明提示
-- 小喇叭按钮响应消息
-- 动态调整小喇叭按钮位置
-- 大脚选项开关
-- 绑定说明本地化
--
-- Ever@178.com
-----------------------------------

function WhisperPopOutButton_OnUpdate(self, elapsed)
	if not self.flash then return end
	if (self.flashMode) then
		self.flashTime = self.flashTime + elapsed;
		if (self.mode == "IN") then
			if (self.flashTime < self.timeToFade) then
				self.flash:SetAlpha(1-0.8*(self.flashTime / self.timeToFade));
			else
				self.mode = "OUT";
				self.flashTime = 0;
			end
		elseif (self.mode == "HOLD") then
			if (self.flashTime < WHISPERPOPHOLDTIME) then
				self.flash:SetAlpha(1.0);
			else
				self.mode = "IN";
				self.flashTime = 0;
			end
		elseif (self.mode == "OUT") then
			if (self.flashTime < self.timeToFade) then
				self.flash:SetAlpha(0.2+0.8*(self.flashTime / self.timeToFade));
			else
				self.mode = "HOLD";
				self.flashTime = 0;
			end
		end
	else
		if (self.flash:IsShown()) then
			self.flash:Hide();
		end
	end
end

function WP_UpdateButtonSide(chatFrame)
	if not chatFrame or not WhisperPopOutButton then return end
	local chatFrameHeight = chatFrame:GetHeight() or 0;
	local bottomDist = chatFrame:GetBottom() or 0;
	local screenHeight = (type(GetScreenHeight) == "function" and GetScreenHeight()) or 0;
	if ( bottomDist > 0 and screenHeight > 0 and (bottomDist+chatFrameHeight/2) > screenHeight/2 ) then
		if ChatFrame1ButtonFrameBottomButton then WhisperPopOutButton:ClearAllPoints();
		WhisperPopOutButton:SetPoint("TOP",ChatFrame1ButtonFrameBottomButton,"BOTTOM") end
	else
		if FriendsMicroButton then WhisperPopOutButton:ClearAllPoints();
		WhisperPopOutButton:SetPoint("BOTTOM",FriendsMicroButton,"TOP")
		elseif ChatFrame1ButtonFrame then WhisperPopOutButton:ClearAllPoints();
		WhisperPopOutButton:SetPoint("BOTTOM",ChatFrame1ButtonFrame,"TOP") end
	end
end

-- WoW Forever: FCF_UpdateButtonSide 可能不存在，先做存在性探测。
if type(FCF_UpdateButtonSide) == "function" and type(hooksecurefunc) == "function" then hooksecurefunc("FCF_UpdateButtonSide",function(frame)
	if ( frame == DEFAULT_CHAT_FRAME ) then
		WP_UpdateButtonSide(frame);
	end
end) end

function WhisperPop_Toggle(switch)
	if (switch) then
		list:RegisterEvent("CHAT_MSG_WHISPER")
		list:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
		list:RegisterEvent("CHAT_MSG_BN_WHISPER")
		list:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM")
		if WhisperPopOutButton then WhisperPopOutButton:Show() end;
	else
		list:UnregisterEvent("CHAT_MSG_WHISPER")
		list:UnregisterEvent("CHAT_MSG_WHISPER_INFORM")
		list:UnregisterEvent("CHAT_MSG_BN_WHISPER")
		list:UnregisterEvent("CHAT_MSG_BN_WHISPER_INFORM")
		frame:Hide();
		if WhisperPopOutButton then WhisperPopOutButton:Hide() end;
	end
end
