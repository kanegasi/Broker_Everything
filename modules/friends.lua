
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I


-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "Friends"; -- FRIENDS L["ModDesc-Friends"]
local ttName,ttName2,ttColumns,tt,tt2,module = name.."TT",name.."TT2",8;
local unknownGameError = false;
local DSw, DSh =  0,  0;
local ULx, ULy =  0,  0;
local LLx, LLy = 32, 32;
local URx, URy =  5, 27;
local LRx, LRy =  5, 27;
local off, on = strtrim(gsub(ERR_FRIEND_OFFLINE_S,"%%s","")), strtrim(gsub(ERR_FRIEND_ONLINE_SS,"\124Hplayer:%%s\124h%[%%s%]\124h",""));
local gameIconPos = setmetatable({},{ __index = function(t,k) return format("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s",DSw,DSh,ULx,ULy,LLx,LLy,URx,URy,LRx,LRy) end})
local _BNet_GetClientTexture = BNet_GetClientTexture
local gameShortcut = setmetatable({
	[BNET_CLIENT_WTCG] = "HS",
	[BNET_CLIENT_OVERWATCH] = "OW",
	[BNET_CLIENT_HEROES] = "HotS",
	["BSAp"] = "Mobile",
},{ __index = function(t, k) return k end });
local gameNames = setmetatable({
	[BNET_CLIENT_APP]="Desktop App",
	["BSAp"] = "Mobile App",
	[BNET_CLIENT_D3]="Diablo 3",
	[BNET_CLIENT_DESTINY2]="Destiny 2",
	[BNET_CLIENT_HEROES]="Heroes of the Storm",
	[BNET_CLIENT_OVERWATCH]="Overwatch",
	[BNET_CLIENT_SC2]="Starcraft 2",
	[BNET_CLIENT_WOW]="World of Warcraft",
	[BNET_CLIENT_WTCG]="Hearthstone",
},{ __index = function(t, k) return k end });


-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\Addons\\"..addon.."\\media\\friends"}; --IconName::Friends--


-- some local functions --
--------------------------
local function BNet_GetClientTexture(game,tt2)
	if ns.profile[name].showGame=="2" and not tt2 then
		return gameShortcut[game]
	else
		local icon = _BNet_GetClientTexture(game)
		return format("|T%s:%s|t",icon,gameIconPos[game])
	end
	return "";
end

local function _status(afk,dnd)
	if ns.profile[name].showStatus=="1" then
		return ("|T%s:0|t"):format(_G["FRIENDS_TEXTURE_"  .. ((afk==true and "AFK") or (dnd==true and "DND") or "ONLINE")]);
	elseif ns.profile[name].showStatus=="2" then
		return (afk==true and C("gold","[AFK]")) or (dnd==true and C("ltred","[DND]")) or "";
	end
	return "";
end

local function updateBroker()
	local dataobj = ns.LDB:GetDataObjectByName(module.ldbName);
	local numBNFriends, numOnlineBNFriends = 0,0;
	if BNConnected() then
		numBNFriends, numOnlineBNFriends = BNGetNumFriends();
	end
	local numFriends = C_FriendList.GetNumFriends();
	local friendsOnline = C_FriendList.GetNumOnlineFriends();
	if not (tonumber(numOnlineBNFriends) and tonumber(friendsOnline)) then return end

	if ns.profile[name].splitFriendsBroker then
		local friends = friendsOnline;
		local bnfriends = numOnlineBNFriends;
		if ns.profile[name].showTotalCount then
			friends = friends.."/"..numFriends;
			bnfriends = bnfriends.."/"..numBNFriends;
		end
		dataobj.text = friends .." ".. C(BNConnected() and "ltblue" or "red",bnfriends);
	else
		local txt = numOnlineBNFriends + friendsOnline;
		if ns.profile[name].showTotalCount then
			txt = txt .."/".. (numBNFriends + numFriends);
		end
		dataobj.text = txt .. (BNConnected()==false and "("..C("red","BNet Off")..")" or "");
	end

	local broadcastText = select(4,BNGetInfo());
	if (broadcastText) and (strlen(broadcastText)>0) then
		dataobj.text=dataobj.text.." |Tinterface\\chatframe\\ui-chatinput-focusicon:0|t";
	end
end

local function broadcastTooltip(self)
	local broadcastText,broadcastTime = 13,14; -- BNGetFriendToonInfo
	if (self~=false) then
		local blue = C("ltblue","colortable");

		GameTooltip:SetOwner(self,"ANCHOR_NONE");
		if (select(1,self:GetCenter()) > (select(1,UIParent:GetWidth()) / 2)) then
			GameTooltip:SetPoint("RIGHT",tt,"LEFT",-2,0);
		else
			GameTooltip:SetPoint("LEFT",tt,"RIGHT",2,0);
		end
		GameTooltip:SetPoint("TOP",self,"TOP", 0, 4);

		GameTooltip:ClearLines();
		GameTooltip:AddLine(self.name,blue[1],blue[2],blue[3]);
		GameTooltip:AddLine(date("%Y-%m-%d %H:%M:%S",self.toonInfo[broadcastTime]),.7,.7,.7);
		GameTooltip:AddLine(SecondsToTime(time()-self.toonInfo[broadcastTime]),.7,.7,.7);
		GameTooltip:AddLine(self.toonInfo[broadcastText],1,1,1,true);
		GameTooltip:Show();
	else
		GameTooltip:Hide();
	end
end

local function createTooltip2(self,data)
	if not (ns.profile[name].showBroadcastTT2 or ns.profile[name].showBattleTagTT2 or ns.profile[name].showRealIDTT2 or ns.profile[name].showZoneTT2 or ns.profile[name].showGameTT2 or ns.profile[name].showNotesTT2) then return end
	local color1 = "ltblue";
	tt2 = ns.acquireTooltip(
		{ttName2, 3, "LEFT","RIGHT","RIGHT"},
		{true,true},
		{self, "horizontal", tt}
	);
	if tt2.lines~=nil then tt2:Clear(); end
	local l=tt2:AddHeader(C("dkyellow",NAME));
	tt2:SetCell(l,2,C(data.className or color1,ns.scm(data.name)),nil,nil,0);
	tt2:AddSeparator();
	-- game
	if ns.profile[name].showGameTT2 then
		tt2:SetCell(tt2:AddLine(C(color1,data.client=="App" and L["Program"] or GAME)),2,gameNames[data.client] .." ".. BNet_GetClientTexture(data.client,true),nil,"RIGHT",0);
	end
	if data.client==BNET_CLIENT_WOW then
		-- realm
		if (data.realm) then
			tt2:SetCell(tt2:AddLine(C(color1,L["Realm"])),2,ns.scm(data.realm),nil,"RIGHT",0);
		end
		-- faction
		if ns.profile[name].showFactionTT2 then
			tt2:SetCell(tt2:AddLine(C(color1,FACTION)),2, data.factionL .. " |TInterface\\PVPFrame\\PVP-Currency-".. data.factionT ..":14:14:0:-1:32:32:3:29:3:29|t", nil,"RIGHT",0);
		end
	end
	-- zone
	if ns.profile[name].showZoneTT2 and data.area then
		tt2:SetCell(tt2:AddLine(C(color1,ZONE)),2,data.area,nil,"RIGHT",0);
	end
	-- notes
	if ns.profile[name].showNotesTT2 and data.notes:trim():len()>0 then
		tt2:AddSeparator(4,0,0,0,0);
		tt2:SetCell(tt2:AddLine(),1,C(color1,COMMUNITIES_ROSTER_COLUMN_TITLE_NOTE),nil,nil,0);
		tt2:AddSeparator();
		tt2:SetCell(tt2:AddLine(),1,ns.scm(data.notes,true),nil,"LEFT",0);
	end
	-- broadcast
	if ns.profile[name].showBroadcastTT2 and data.broadcast and data.broadcast:len()>0 then
		tt2:AddSeparator(4,0,0,0,0);
		tt2:SetCell(tt2:AddLine(),1,C(color1,BATTLENET_BROADCAST),nil,nil,0);
		tt2:AddSeparator();
		local broadcast = data.broadcast;
		if ns.profile.GeneralOptions.scm then
			broadcast="***"; -- dummy text
		else
			broadcast=ns.strWrap(broadcast,48);
		end
		tt2:SetCell(tt2:AddLine(),1,broadcast,nil,"LEFT",0);
		if data.broadcastTime then
			tt2:SetCell(tt2:AddLine(),1,C("ltgray","("..L["Active since"]..CHAT_HEADER_SUFFIX..SecondsToTime(time()-data.broadcastTime)..")"),nil,"RIGHT",0);
		end
	end

	ns.roundupTooltip(tt2);
end

local function tooltipLineScript_OnMouseUp(self,data,button)
	if data.type=="realm" then
		-- whisper toon to toon
		if IsAltKeyDown() then
			if C_PartyInfo.InviteUnit then
				C_PartyInfo.InviteUnit(data.fullName);
			elseif InviteUnit then
				InviteUnit(data.fullName);
			end
		else
			ChatFrame_SendTell(data.fullName);
		end
	elseif data.type=="battlenet" then
		-- battlenet whisper
		if IsAltKeyDown() then
			if data.client=="WoW" then
				BNInviteFriend(data.toonID);
			end
		else
			local func,name = "BNet",data.account; -- account name
			if button=="RightButton" then
				func,name = "",data.name; -- toon name
				if ns.realm~=data.realm then
					name = name .."-".. ns.stripRealm(data.realm);
				end
			end
			securecall("ChatFrame_Send"..func.."Tell",name);
		end
	end
end

local C_BattleNet_GetFriendNumGameAccounts = (C_BattleNet and C_BattleNet.GetFriendNumGameAccounts) or BNGetNumFriendGameAccounts;
local C_BattleNet_GetFriendAccountInfo = (C_BattleNet and C_BattleNet.GetFriendAccountInfo) or function(friendIndex)
	-- upgrade old to new
	local accountInfo={gameAccountInfo={}};
	accountInfo.bnetAccountID,
	accountInfo.accountName,
	accountInfo.battleTag,
	accountInfo.isBattleTagFriend,
	accountInfo.gameAccountInfo.characterName,
	accountInfo.gameAccountInfo.gameAccountID,
	accountInfo.gameAccountInfo.clientProgram,
	accountInfo.gameAccountInfo.isOnline,
	accountInfo.lastOnlineTime,
	accountInfo.isAFK,
	accountInfo.isDND,
	accountInfo.customMessage,
	accountInfo.note,
	accountInfo.isFriend,
	accountInfo.customMessageTime,
	accountInfo.gameAccountInfo.wowProjectID,
	accountInfo.rafLinkType,
	accountInfo.gameAccountInfo.canSummon,
	accountInfo.isFavorite,
	accountInfo.gameAccountInfo.isWowMobile
	= BNGetFriendInfo(friendIndex)
	return accountInfo;
end

local C_BattleNet_GetFriendGameAccountInfo = (C_BattleNet and C_BattleNet.GetFriendGameAccountInfo) or function(friendIndex, accountIndex)
	local gameAccountInfo,_ = {};
	gameAccountInfo.hasFocus, -- 1
	gameAccountInfo.characterName, -- 2
	gameAccountInfo.clientProgram, -- 3
	gameAccountInfo.realmName, -- 4
	gameAccountInfo.realmID, -- 5
	gameAccountInfo.factionName, -- 6
	gameAccountInfo.raceName, -- 7
	gameAccountInfo.className, -- 8
	_, -- 9
	gameAccountInfo.areaName, -- 10
	gameAccountInfo.characterLevel, -- 11
	gameAccountInfo.richPresence, -- 12
	_, --accountInfo.customMessage, -- 13
	_, --accountInfo.customMessageTime, -- 14
	gameAccountInfo.isOnline, -- 15
	gameAccountInfo.gameAccountID, -- 16
	_, --accountInfo.bnetAccountID, -- 17
	gameAccountInfo.isGameAFK, -- 18
	gameAccountInfo.isGameBusy, -- 19
	gameAccountInfo.playerGuid, -- 20
	gameAccountInfo.wowProjectID, -- 21
	gameAccountInfo.isWowMobile -- 22
	= BNGetFriendGameAccountInfo(friendIndex, accountIndex)
	return gameAccountInfo
end

local function createTooltip(tt)
	if not (tt and tt.key and tt.key==ttName) then return end -- don't override other LibQTip tooltips...

	local columns,l,c=8;
	local numFriends = C_FriendList.GetNumFriends();
	local friendsOnline = C_FriendList.GetNumOnlineFriends();

	local numBNFriends, numOnlineBNFriends = BNGetNumFriends();
	if tt.lines~=nil then tt:Clear(); end
	tt:SetCell(tt:AddLine(),1,C("dkyellow",L[name]),tt:GetHeaderFont(),"LEFT",0);

	local _, _, _, broadcastText = BNGetInfo();
	if broadcastText~=nil and broadcastText~="" then
		tt:AddSeparator(4,0,0,0,0);
		tt:SetCell(tt:AddLine(),1,C("dkyellow",L["My current broadcast message"]),nil,nil,columns);
		tt:AddSeparator();
		tt:SetCell(tt:AddLine(),1,C("white",ns.scm(broadcastText,true)),nil,nil,columns);
	end

	local fi,nt,ti;
	local visible = {};

	tt:AddSeparator(4,0,0,0,0);
	tt:AddLine(
		C("ltyellow",L["Real ID"].."/"..BATTLETAG), -- 1
		C("ltyellow",LEVEL),		-- 2
		C("ltyellow",CHARACTER),	-- 3
		ns.profile[name].showGame~="0"    and C("ltyellow",GAME)       or "", -- 4
		ns.profile[name].showZone         and C("ltyellow",ZONE)       or "", -- 5
		ns.profile[name].showRealm=="1"   and C("ltyellow",L["Realm"]) or "", -- 6
		ns.profile[name].showFaction=="2" and C("ltyellow",FACTION)    or "", -- 7
		ns.profile[name].showNotes        and C("ltyellow",L["Notes"]) or ""  -- 8
	);
	tt:AddSeparator();

	if ns.profile[name].showBNFriends then
		tt:SetCell(tt:AddLine(),1,C("ltgray",L["BattleNet friends"]),nil,"LEFT",0);
		if not BNConnected() then
			tt:SetCell(tt:AddLine(),1,"    "..C("ltred",BATTLENET_UNAVAILABLE),nil,"LEFT",0);
		elseif numOnlineBNFriends==0 then
			tt:SetCell(tt:AddLine(),1,"    "..C("gray",L["Currently no battle.net friends online..."]),nil,"LEFT",0);
		else
			-- RealId	Status Character	Level	Zone	Game	Realm	Notes
			for i=1, numBNFriends do
				local nt = C_BattleNet_GetFriendNumGameAccounts(i);
				local fi = C_BattleNet_GetFriendAccountInfo(i);
				if fi.gameAccountInfo.isOnline then
					for I=1, nt do
						local ti =  C_BattleNet_GetFriendGameAccountInfo(i,I);
						local bcIcon = fi.customMessage~="" and "|Tinterface\\chatframe\\ui-chatinput-focusicon:0|t" or "";
						if not visible[fi.bnetAccountID] then -- filter duplicates...
							local isBNColor=false;
							visible[fi.bnetAccountID] = true
							local l = tt:AddLine();

							-- wow logout is buggy. sometimes level==0 and reamid==0. player is logout out but displayed as playing wow
							if ti.characterLevel==0 and ti.realmID==0 then
								ti.clientProgram = "App"
							end

							-- battle tags / realids
							if ns.profile[name].showBattleTags~="0" then
								local a,b = strsplit("#",fi.battleTag);
								local BattleTag = C("ltblue",ns.scm(a))..C("ltgray","#"..ns.scm(b));
								local bnName=C("ltblue",ns.scm(fi.accountName));
								-- 0 Disabled
								-- 1 Name
								-- 2 Name (BattleTag)
								-- 3 BattleTag
								if ns.profile[name].showBattleTags=="2" then
									bnName = bnName .. C("white"," (")..BattleTag..C("white",")");
								elseif ns.profile[name].showBattleTags=="3" then
									bnName = BattleTag;
								end
								tt:SetCell(l,1,"    "..bnName..bcIcon); -- 1
							end

							-- level
							ti.characterLevel = tonumber(ti.characterLevel);
							if ti.characterLevel and ti.characterLevel>0 then
								tt:SetCell(l,2,C("white",ti.characterLevel));		-- 2
							end

							-- toon name
							local nameStr = (ti.characterName and ti.characterName~="" and ti.characterName) or (fi.isBattleTagFriend and fi.accountName and fi.accountName~="" and fi.accountName) or strsplit("#",fi.battleTag);
							if ti.clientProgram=="WoW" and ti.realmID>0 and ti.className then
								nameStr = C(ti.className,ns.scm(nameStr)); -- wow character name in class color
							else
								nameStr = C("ltblue",ns.scm(nameStr)); -- all other in light blue
							end
							-- toon name - append realm name or asterisk
							if tonumber(ns.profile[name].showRealm)>1 and ti.realmName~=ns.realm_short and ti.realmID and ti.realmID>0 then
								if ns.profile[name].showRealm=="2" then
									nameStr = nameStr..C("dkyellow","-"..ns.scm(ti.realmName));
								else
									nameStr = nameStr..C("dkyellow","*");
								end
							end
							-- toon name - append faction icon
							if ns.profile[name].showFaction=="1" and ti.clientProgram=="WoW" and ti.factionName then
								nameStr = nameStr.."|TInterface\\PVPFrame\\PVP-Currency-"..ti.factionName..":16:16:0:-1:32:32:2:30:2:30|t";
							elseif ns.profile[name].showBattleTags=="0" and ti.clientProgram~="App" then
								nameStr = nameStr.." "..bcIcon;
							end
							tt:SetCell(l,3,_status(fi.isAFK,fi.isDND)..nameStr); -- 3

							-- game icon or text
							if ns.profile[name].showGame~="0" then
								tt:SetCell(l,4,C("white", BNet_GetClientTexture(ti.clientProgram) ));	-- 4
							end

							-- zone or current screen
							if ns.profile[name].showZone then
								if ti.clientProgram=="WoW" and ti.areaName and ti.areaName:match("^"..GARRISON_LOCATION_TOOLTIP) and ti.areaName~=GARRISON_LOCATION_TOOLTIP then
									ti.areaName = GARRISON_LOCATION_TOOLTIP;
								end
								local zoneStr = (ti.areaName and ti.areaName~="" and ti.areaName) or --[[(ti.richPresence and ti.richPresence~="" and ti.richPresence) or]] (ti.clientProgram and ti.clientProgram~="" and gameNames[ti.clientProgram]) or UNKNOWN;
								tt:SetCell(l,5,C("white",zoneStr),nil,nil, ti.clientProgram=="WoW" and 1 or 3);			-- 5,6,7
							end

							if ti.clientProgram=="WoW" then
								-- realm (own column)
								if ns.profile[name].showRealm=="1" and ti.realmID>0 then
									local realm,_ = ti.realmName;
									if type(realm)=="string" and realm:len()>0 then
										local _,_realm = ns.LRI:GetRealmInfo(realm);
										if _realm and _realm~="" then
											realm = _realm;
										end
									end
									tt:SetCell(l,6,C(ns.realms[realm] and "green" or "white",ti.realmName or L["Classic realm"]));			-- 6
								end
								-- faction (own column)
								if ti.factionName then
									if ns.profile[name].showFaction=="2" then
										local color = "green";
										if ti.factionName=="Alliance" then
											color = "ff0077ff"
										elseif ti.factionName=="Horde" then
											color = "red"
										end
										tt:SetCell(l,7,C(color,_G["FACTION_"..ti.factionName:upper()] or ti.factionName));		-- 7
									elseif ns.profile[name].showFaction=="3" then
										if ti.factionName=="Neutral" then
											tt:SetCell(l,7,"|TInterface\\minimap\\tracking\\battlemaster:16:16:0:-1:32:32:2:30:2:30|t");
										else
											tt:SetCell(l,7,"|TInterface\\PVPFrame\\PVP-Currency-"..ti.factionName..":16:16:0:-1:32:32:2:30:2:30|t");
										end
									end
								end
							end
							-- notes
							if ns.profile[name].showNotes and fi.note then
								tt:SetCell(l,8,C("white",C("white",ns.scm(fi.note,true)))); -- 8
							end

							local data = {
								type = "battlenet",
								toonID = ti.gameAccountID,
								account = fi.accountName,
								className = ti.className or false,
								name = ti.characterName,
								client = ti.clientProgram,
								realm = ti.realmName,
								area = ti.clientProgram~="App" and (ti.areaName or ti.richPresence) or false,
								notes = (fi.note or ""):trim(),
								broadcast = (fi.customMessage or ""):trim(),
								broadcastTime = fi.customMessageTime or false,
							};
							if ti.factionName then
								data.factionT = ti.factionName:upper();
								data.factionL = _G["FACTION_"..ti.factionName:upper()];
							end

							tt:SetLineScript(l, "OnMouseUp", tooltipLineScript_OnMouseUp, data);
							tt:SetLineScript(l, "OnEnter", createTooltip2, data);
						end
					end
				end
			end
		end
	end

	if ns.profile[name].showFriends then
		tt:SetCell(tt:AddLine(),1,C("ltgray",FRIENDS),nil,"LEFT",0);
		if friendsOnline==0 then
			tt:SetCell(tt:AddLine(),1,"    "..C("gray",L["Currently no friends online..."]),nil,"LEFT",0);
		else
			local charName,level,class,area,connected,status,note,cName,cRealm,cGame=1,2,3,4,5,6,7,18,19,20; -- GetFriendInfo
			local l,c,s,n,_;
			for i=1, numFriends do
				local v = C_FriendList.GetFriendInfoByIndex(i);
				v.fullName = v.name;
				if v.name:find("-") then
					v.name, v.realm = strsplit("-",v.fullName,2);
				else
					v.realm = ns.realm;
					v.fullName = v.fullName .."-".. ns.realm;
				end
				v.client = BNET_CLIENT_WOW;
				if visible[v.name..v.realm..v.area] then
					-- filter duplicates...
				elseif v.name and v.connected then
					visible[v.name..v.realm..v.area] = true;

					local l = tt:AddLine("","","","","","","","");
					tt:SetCell(l,2,C("white",v.level));

					local nameStr = _status(v.afk,v.dnd) .. C(v.className:upper(),ns.scm(v.name));

					local realm,_
					if type(v.realm)=="string" and v.realm:len()>0 then
						_,realm = ns.LRI:GetRealmInfo(v.realm);
					end

					if tonumber(ns.profile[name].showRealm)>1 and v.realm~=ns.realm then
						if ns.profile[name].showRealm=="2" then
							nameStr = nameStr..C("dkyellow","-"..ns.scm(realm or v.realm));
						else
							nameStr = nameStr..C("dkyellow","*");
						end
					end
					if ns.profile[name].showFaction=="1" then
						nameStr = nameStr.."|TInterface\\PVPFrame\\PVP-Currency-"..ns.player.faction..":16:16:0:-1:32:32:2:30:2:30|t";
					end
					tt:SetCell(l,3,nameStr);

					-- client icon or text
					if ns.profile[name].showGame~="0" then
						tt:SetCell(l,4,C("white",BNet_GetClientTexture(v.client)));
					end
					-- zone
					if ns.profile[name].showZone then
						if v.area:match("^"..GARRISON_LOCATION_TOOLTIP) and v.area~=GARRISON_LOCATION_TOOLTIP then
							v.area = GARRISON_LOCATION_TOOLTIP;
						end
						tt:SetCell(l,5,C("white",v.area));
					end
					-- realm
					if ns.profile[name].showRealm=="1" then
						tt:SetCell(l,6,C("green",realm or v.realm));
					end
					-- faction
					if ns.profile[name].showFaction=="2" then
						tt:SetCell(l,7,C(ns.player.faction=="Horde" and "red" or "ltblue",ns.player.factionL or ns.player.faction));
					elseif ns.profile[name].showFaction=="3" then
						tt:SetCell(l,7,"|TInterface\\PVPFrame\\PVP-Currency-"..ns.player.faction..":16:16:0:-1:32:32:2:30:2:30|t");
					end
					-- notes
					if ns.profile[name].showNotes then
						tt:SetCell(l,8,C("white",ns.scm(v[note] or "")));
					end

					v.type = "realm";
					v.factionT = ns.player.faction:upper();
					v.factionL = ns.player.factionL;

					tt:SetLineScript(l, "OnMouseUp", tooltipLineScript_OnMouseUp, v);
					tt:SetLineScript(l, "OnEnter", createTooltip2, v);
				end
			end
		end
	end

	if not ns.profile[name].showBNFriends and not ns.profile[name].showFriends then
		tt:AddLine(C("ltgray",L["No friends to diplay. You have both disabled for tooltip"]));
	end

	if (ns.profile.GeneralOptions.showHints) then
		tt:AddSeparator(3,0,0,0,0);
		tt:SetCell(tt:AddLine(),1,C("ltblue",L["MouseBtn"]).." || "..C("green",WHISPER) .." - ".. C("ltblue",L["ModKeyA"].."+"..L["MouseBtn"]).." || "..C("green",TRAVEL_PASS_INVITE),nil,nil,columns);
		ns.ClickOpts.ttAddHints(tt,name,nil,2);
	end

	ns.roundupTooltip(tt);
end


-- module functions and variables --
------------------------------------
module = {
	events = {
		"BATTLETAG_INVITE_SHOW", -- ?
		"BN_BLOCK_LIST_UPDATED",
		"BN_CONNECTED",
		"BN_CUSTOM_MESSAGE_CHANGED",
		"BN_CUSTOM_MESSAGE_LOADED",
		"BN_DISCONNECTED",
		"BN_FRIEND_ACCOUNT_OFFLINE",
		"BN_FRIEND_ACCOUNT_ONLINE",
		"BN_FRIEND_INFO_CHANGED",
		"BN_FRIEND_INVITE_ADDED",
		"BN_FRIEND_INVITE_REMOVED",
		"BN_INFO_CHANGED",
		"FRIENDLIST_UPDATE",
		"PLAYER_LOGIN",
		"CHAT_MSG_SYSTEM"
	},
	config_defaults = {
		enabled = true,
		-- broker button
		splitFriendsBroker = true,
		showFriendsBroker = true,
		showBNFriendsBroker = true,

		-- tooltip 1
		showFriends = true,
		showStatus = "1",
		showBNFriends = true,
		showBattleTags = "3",
		showRealm = "1",
		showGame = "1",
		showFaction = "2",
		showZone = true,
		showNotes = true,
		showTotalCount = true,

		-- tooltip 2
		showBroadcastTT2 = true,
		showBattleTagTT2 = false,
		showRealIDTT2 = false,
		showFactionTT2 = false,
		showZoneTT2 = false,
		showGameTT2 = false,
		showNotesTT2 = false
	},
	clickOptionsRename = {
		["friends"] = "1_open_character_info",
		["menu"] = "2_open_menu"
	},
	clickOptions = {
		["friends"] = {SOCIAL_BUTTON,"call",{"ToggleFriendsFrame",1}},
		["menu"] = "OptionMenu"
	}
}

ns.ClickOpts.addDefaults(module,{
	friends = "_LEFT",
	menu = "_RIGHT"
});

function module.options()
	return {
		broker = {
			splitFriendsBroker={ type="toggle", order=1, name=L["Split friends on Broker"], desc=L["Split Characters and BattleNet-Friends on Broker Button"] },
			showFriendsBroker={ type="toggle", order=2, name=L["Show friends"], desc=L["Display count of friends if 'Split friends on Broker' enabled otherwise add friends to summary count."]},
			showBNFriendsBroker={ type="toggle", order=3, name=L["Show BattleNet friends"], desc=L["Display count of BattleNet friends on Broker if 'Split friends on Broker' enabled otherwise add BattleNet friends to summary count."] },
			showTotalCount={ type="toggle", order=4, name=L["Show total count"], desc=L["Display total count of friens and/or BattleNet friends on broker button"] },
		},
		tooltip1 = {
			name = L["Main tooltip options"],
			order = 2,

			showFriends={ type="toggle", order=1, name=L["Show friends"],           desc=L["Display friends in tooltip"] },
			showBNFriends={ type="toggle", order=2, name=L["Show BattleNet friends"], desc=L["Display BattleNet friends in tooltip"] },
			showBattleTags={ type="select", order=3, name=L["Show BattleTag/RealID"],  desc=L["Display BattleTag and/or RealID in tooltip"], width="double",
				values={
					["0"] = NONE.." / "..ADDON_DISABLED,
					["1"] = "RealID or BattleName",
					["2"] = "RealID or BattleName (BattleTag)",
					["3"] = "BattleTag",
				},
			},
			showRealm={ type="select", order=4, name=L["Show realm"], desc=L["Display realm name in tooltip (WoW only)"], width="double",
				values={
					["0"] = NONE.." / "..ADDON_DISABLED,
					["1"] = L["Realm name in own column"],
					["2"] = L["Realm name in character name column"],
					["3"] = L["* (Asterisk) behind character name if on foreign realm"]
				},
			},
			showFaction={ type="select", order=5, name=L["Show faction"], desc=L["Display faction in tooltip (WoW only)"], width="double",
				values={
					["0"]=NONE.." / "..ADDON_DISABLED,
					["1"]=L["Icon behind character name"],
					["2"]=L["Faction name in own column"],
					["3"]=L["Faction icon in own column"]
				},
			},
			showGame={ type="select", order=6, name=L["Show game"], desc=L["Display game icon or game shortcut in tooltip"], --width="double",
				values={
					["0"]=NONE.." / "..ADDON_DISABLED,
					["1"]=L["Game icon"],
					["2"]=L["Game shortcut"]
				},
			},
			showStatus={ type="select", order=7, name=L["Show status"], desc=L["Display status like AFK in tooltip"], -- width="double",
				values={
					["0"]=NONE.." / "..ADDON_DISABLED,
					["1"]=L["Status icon"],
					["2"]=L["Status text"],
				},
			},
			showZone={ type="toggle", order=8, name=ZONE, desc=L["Display zone in tooltip"] },
			showNotes={ type="toggle", order=9, name=L["Notes"], desc=L["Display notes in tooltip"] },
		},
		tooltip2 = {
			name=L["Second tooltip options"],
			order = 3,

			desc={ type="description", order=11, name=L["The secondary tooltip will be displayed by moving the mouse over a friend in main tooltip. The tooltip will be displayed if one of the following options activated."], fontSize="medium"},
			showBroadcastTT2={ type="toggle", order=12, name=L["Show broadcast message"], desc=L["Display broadcast message in tooltip (BattleNet friend only)"] },
			showBattleTagTT2={ type="toggle", order=13, name=L["Show BattleTag"], desc=L["Display BattleTag in tooltip (BattleNet friend only)"] },
			showRealIDTT2={ type="toggle", order=14, name=L["Show RealID"], desc=L["Display RealID in tooltip if available (BattleNet friend only)"] },
			showFactionTT2={ type="toggle", order=15, name=L["Show faction"], desc=L["Display faction in tooltip if available"] },
			showZoneTT2={ type="toggle", order=16, name=L["Show zone"], desc=L["Display zone in second tooltip"] },
			showGameTT2={ type="toggle", order=17, name=L["Show game"], desc=L["Display game in second tooltip"] },
			showNotesTT2={ type="toggle", order=18, name=L["Show notes"], desc=L["Display notes in second tooltip"] },
		},
		misc = nil,
	}
end

-- function module.init() end

function module.onevent(self,event,arg1)
	if event=="BE_UPDATE_CFG" and arg1 and arg1:find("^ClickOpt") then
		ns.ClickOpts.update(name);
	elseif event=="PLAYER_LOGIN" then
		if type(ns.profile[name].showBattleTags)=="boolean" then
			ns.profile[name].showBattleTags = ns.profile[name].showBattleTags and "3" or "0";
		end
	elseif ns.eventPlayerEnteredWorld then
		updateBroker();
		if (tt) and (tt.key) and (tt.key==ttName) and (tt:IsShown()) then
			createTooltip(tt);
		end
	end
end

-- function module.optionspanel(panel) end
-- function module.onmousewheel(self,direction) end
-- function module.ontooltip(tt) end

function module.onenter(self)
	if (ns.tooltipChkOnShowModifier(false)) then return; end
	tt = ns.acquireTooltip(
		{ttName, ttColumns, "LEFT","CENTER", "LEFT", "CENTER", "LEFT", "LEFT", "LEFT", "LEFT"},
		{false},
		{self}
	);
	createTooltip(tt);
end

-- function module.onleave(self) end
-- function module.onclick(self,button)
-- function module.ondblclick(self,button) end


-- final module registration --
-------------------------------
ns.modules[name] = module;
