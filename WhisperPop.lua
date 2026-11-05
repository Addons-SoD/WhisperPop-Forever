------------------------------------------------------------
-- WhisperPop.lua
--
-- Abin
-- 2010-9-28
------------------------------------------------------------

WhisperPop = {}
local _getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
WhisperPop.version = _getMeta and _getMeta("WhisperPop", "Version") or "3.0"
WhisperPop.IGNORED_MESSAGES = { "<DBM>", "<BWS>", "<BigWigs>", "<BIGWIGS>", "<集合石插件>","<大脚团队提示>", "LVBM" } -- Add your ignore tags
WhisperPop.db = { sound = 1, time = 1, help = 1, keep = 1 }
WhisperPop.newNames = {}

-- WoW Forever: 玩家名字/聊天内容可能是 secret value，禁止对它们做
-- 比较、拼接或格式化。这里统一做能力探测和占位降级。
function WhisperPop:IsSecret(value)
	return type(issecretvalue) == "function" and issecretvalue(value) or false
end

function WhisperPop:SanitizeName(name)
	if self:IsSecret(name) then
		return WHISPERPOP_LOCALE["secret name"]
	end
	return name
end

function WhisperPop:SanitizeText(text)
	if self:IsSecret(text) then
		return WHISPERPOP_LOCALE["secret message"]
	end
	return text
end

-- WoW Forever: BNGetFriendInfoByID 已移除，改用 C_BattleNet.GetAccountInfoByID。
-- 同时兼容旧客户端，返回 BattleTag 供列表显示。
function WhisperPop:GetBNetName(id)
	if type(id) ~= "number" or self:IsSecret(id) then
		return nil
	end

	if C_BattleNet and C_BattleNet.GetAccountInfoByID then
		local ok, info = pcall(C_BattleNet.GetAccountInfoByID, id)
		if ok and type(info) == "table" then
			local name = info.battleTag or info.accountName
			if name then
				return self:SanitizeName(name)
			end
		end
	end

	if type(BNGetFriendInfoByID) == "function" then
		local ok, _, battleTag = pcall(BNGetFriendInfoByID, id)
		if ok and battleTag then
			return self:SanitizeName(battleTag)
		end
	end
end

function WhisperPop:GetBNetIDByName(name)
	if type(name) ~= "string" or self:IsSecret(name) then
		return nil
	end

	if type(BNet_GetBNetIDAccount) == "function" then
		local ok, id = pcall(BNet_GetBNetIDAccount, name)
		if ok and type(id) == "number" and not self:IsSecret(id) then
			return id
		end
	end
end

-- WoW Forever: GetPlayerInfoByGUID 仍由 PlayerScript 提供，这里保留 C_PlayerInfo 兜底。
function WhisperPop:GetClassByGUID(guid)
	if type(guid) ~= "string" or self:IsSecret(guid) then
		return nil
	end

	local getter = GetPlayerInfoByGUID or (C_PlayerInfo and C_PlayerInfo.GetPlayerInfoByGUID)
	if type(getter) ~= "function" then
		return nil
	end

	local ok, _, class = pcall(getter, guid)
	if ok and not self:IsSecret(class) then
		return class
	end
end

function WhisperPop:IsIgnoredMessage(text)
	local pattern
	for _, pattern in ipairs(self.IGNORED_MESSAGES) do
		if string.find(text, pattern, 1, true) then
			return pattern
		end
	end
end

function WhisperPop:CreateCommonFrame(name, parent, titleText)
	local frame = CreateFrame("Button", name, parent, "BackdropTemplate")
	frame:Hide()
	frame:SetWidth(165)
	frame:SetHeight(262)
	frame:SetClampedToScreen(true)
	frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })

	local title = frame:CreateFontString(name.."Title", "ARTWORK", "GameFontNormal")
	title:SetPoint("TOP", 0, -7)
	title:SetText(titleText)
	frame.title = title

	local button = CreateFrame("Button", name.."CloseButton", frame, "UIPanelCloseButton")
	frame.topClose = button
	button:SetPoint("TOPRIGHT", -2, -2)
	button:SetWidth(24)
	button:SetHeight(24)

	return frame
end

function WhisperPop:CreatePlayerButton(button, name, parent)
	if not button then
		button = CreateFrame("Frame", name, parent)
		button:SetWidth(100)
		button:SetHeight(20)
	end

	button.classIcon = button:CreateTexture(button:GetName().."ClassIcon", "ARTWORK")
	button.classIcon:SetWidth(16)
	button.classIcon:SetHeight(16)
	button.classIcon:SetPoint("LEFT", 4, 0)

	button.nameText = button:CreateFontString(button:GetName().."NameText", "ARTWORK", "GameFontHighlightSmallLeft")
	button.nameText:SetPoint("LEFT", button.classIcon, "RIGHT", 2, 0)

	button.SetPlayer = function(self, class, name)
		-- WoW Forever: 名字/职业也可能是 secret value，先降级为纯文本。
		if WhisperPop:IsSecret(name) then
			name = WHISPERPOP_LOCALE["secret name"]
		end
		if WhisperPop:IsSecret(class) then
			class = nil
		end
		self.nameText:SetText(name)
		local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
		if coords then
			self.classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
			self.classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			self.classIcon:Show()
		elseif class == "GM" then
			self.classIcon:SetTexture("Interface\\AddOns\\WhisperPop\\Texture\\GM")
			self.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			self.classIcon:Show()
		elseif class == "BN" then
			self.classIcon:SetTexture("Interface\\AddOns\\WhisperPop\\Texture\\BN")
			self.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			self.classIcon:Show()
		elseif type(class) == "string" and C_Texture and C_Texture.GetAtlasInfo then
			-- WoW Forever: CLASS_ICON_TCOORDS 可能已被移除，回退到 12.x 的
			-- ClassIcon_<CLASS> 图集。
			local atlas = "ClassIcon_"..string.upper(class)
			local ok, atlasInfo = pcall(C_Texture.GetAtlasInfo, atlas)
			if ok and atlasInfo then
				self.classIcon:SetAtlas(atlas)
				self.classIcon:Show()
			else
				self.classIcon:Hide()
			end
		else
			self.classIcon:Hide()
		end
	end

	return button
end

function WhisperPop:OnNewMessage(name, text, inform, guid)
	if not inform and self.db.sound and type(PlaySoundFile) == "function" then
		-- WoW Forever: 声音文件播放失败不应中断密语记录。
		pcall(PlaySoundFile, "Interface\\AddOns\\WhisperPop\\Notify.mp3") -- Got new message!
	end
end

function WhisperPop:GetNumNewNames()
	return #self.newNames
end

function WhisperPop:GetNewName(id)
	return self.newNames[id or 1]
end

function WhisperPop:OnListUpdate()
	for i = #self.newNames, 1, -1 do
		self.newNames[i] = nil
	end
	for i = 1, self.list:GetDataCount() do
		local data = self.list:GetData(i)
		if data.state == "new" then
			local name;
			if data.BNguid and data.BNguid > 0 then
				name = self:GetBNetName(data.BNguid) or data.name;
			else
				name = data.name;
			end
			table.insert(self.newNames, self:SanitizeName(name))
		end
	end

	-- self.tipFrame:SetTip(self.newNames[1])
end

function WhisperPop:ToggleFrame()
	if WhisperPop.mainFrame:IsShown() then
		WhisperPop.mainFrame:Hide()
	else
		WhisperPop.mainFrame:Show()
	end
end
