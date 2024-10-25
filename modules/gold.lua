
-- module independent variables --
----------------------------------
local addon, ns = ...
local C, L, I = ns.LC.color, ns.L, ns.I
local time,date,tinsert,tconcat=time,date,tinsert,table.concat;


-- module own local variables and local cached functions --
-----------------------------------------------------------
local name = "Gold"; -- BONUS_ROLL_REWARD_MONEY L["ModDesc-Gold"]
local ttName, ttName2, tt, tt2, createTooltip, module = name.."TT", name.."TT2";
local login_money,Date = nil,{};
local listTopProfit,accountBankMoney = {},nil;
local me = ns.player.name_realm;
local ttLines = {
	{"showProfitSession",L["Session"],"session"},
	{"showProfitDaily",HONOR_TODAY,"daily"},
	{"showProfitDaily",HONOR_YESTERDAY,"daily",true},
	{"showProfitWeekly",ARENA_THIS_WEEK,"weekly"},
	{"showProfitWeekly",HONOR_LASTWEEK,"weekly",true},
	{"showProfitMonthly",L["This month"],"monthly"},
	{"showProfitMonthly",L["Last month"],"monthly",true},
};


-- register icon names and default files --
-------------------------------------------
I[name] = {iconfile="Interface\\Minimap\\TRACKING\\Auctioneer",coords={0.05,0.95,0.05,0.95}} --IconName::Gold--


-- some local functions --
--------------------------
local function migrateData()
	if not (ns.data[name] and ns.data[name].Profit) then return end
	-- reason to migrate from ns.data to ns.toons:
	-- Toon profit entries in ns.data wouldn't be delete on deleting toon data by user.
	for interval,Players in pairs(ns.data[name].Profit)do
		for Player, Values in pairs(Players) do
			if ns.toonsDB[Player] then
				ns.tablePath(ns.toonsDB,Player,name,"profit",interval);
				ns.toonsDB[Player][name].profit[interval] = Values;
				if ns.toonsDB[Player].gold then
					ns.toonsDB[Player][name].money = ns.toonsDB[Player].gold;
					ns.toonsDB[Player].gold = nil
				end
			end
		end
	end
	--ns.data[name] = nil;
end

local function updateAccountBankMoney()
	if not (C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account) then
		return;
	end
	accountBankMoney = C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0
end

local function listProfitOnEnter(self,data)
	local ttl = ttLines[data.index];
	local num = ns.profile[name].numProfitTop;

	tt2 = ns.acquireTooltip(
		{ttName2,2,"LEFT","RIGHT","RIGHT"},
		{true,true},
		{self,"horizontal",tt}
	);
	if tt2.lines~=nil then tt2:Clear(); end

	tt2:AddHeader(L["GoldProfitTopHeader"]:format(num), C("dkyellow",ttl[2]));
	tt2:AddSeparator();
	local key = ttl[3]..(ttl[4] and "Last" or "");
	local rText = C("orange",L["Experimental"]);
	for _,d in ipairs({"up","down"})do
		local h,direction=true,d=="up";
		if listTopProfit[key][d] then
			local c = 1;
			for Value,Toons in ns.pairsByKeys(listTopProfit[key][d],direction)do -- Type > Up/Down > Value > [Toons]
				if h then
					tt2:AddLine(C("ltgray",direction and L["GoldProfits"] or L["GoldLosses"]), rText)
					rText = ""
					h=false;
				end
				if not direction then
					Value = -Value;
				end
				tt2:AddLine(table.concat(Toons,"|n"),C(direction and "green" or "red",ns.GetCoinColorOrTextureString(name,Value,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT})));
				c=c+1;
				if c>num then break; end
			end
		end
	end

	ns.roundupTooltip(tt2);
end

local function getProfit(tbl,isCurrent)
	local method,Table=ns.profile[name].profitMethod;
	local t = {session=0,daily=0,weekly=0,monthly=0,dailyLast=0,weeklyLast=0,monthlyLast=0};
	if isCurrent and ns.toon[name].money then
		t.session = ns.toon[name].money-login_money;
	end
	if method==1 then
		Table = tbl.profit;
	elseif method==2 then
		Table = tbl.profitv2;
	end
	if Table then
		for _,interval in ipairs({"daily","weekly","monthly"}) do
			local _date,_tbl = Date[interval],Table[interval];
			if _date and type(_tbl)=="table" then
				if method==1 then
					t[interval] = _tbl[_date[1]] or 0;
					t[interval.."Last"] = tonumber(_tbl[_date[2]]) or 0;
				elseif method==2 then
					t[interval] = tbl.money-(_tbl[_date[1]] or 0);
					t[interval.."Last"] = (_tbl[_date[1]] or 0) - (_tbl[_date[2]] or 0);
					--t[interval.."Last2"] = (_tbl[_date[2]] or 0) - (_tbl[_date[3]] or 0);
				end
			end
		end
	end
	return t;
end

local function getProfitAll()
	local values = {};
	wipe(listTopProfit)
	for i, toonNameRealm,toonName,toonRealm,toonData,isCurrent in ns.pairsToons(name,{--[[currentFirst=true, currentHide=true, forceSameRealm=true]]}) do
		if toonData[name] and (toonData[name].profit or toonData[name].profitv2) then
			local val = getProfit(toonData[name],isCurrent);
			for interval,Value in pairs(val) do
				values[interval] = (values[interval] or 0) + Value;
				if not listTopProfit[interval] then
					listTopProfit[interval] = {up={},down={}}
				end
				if Value>0 then
					if not listTopProfit[interval].up[Value] then
						listTopProfit[interval].up[Value] = {}
					end
					tinsert(listTopProfit[interval].up[Value],toonNameRealm)
				elseif Value<0 then
					if not listTopProfit[interval].down[Value] then
						listTopProfit[interval].down[Value] = {}
					end
					tinsert(listTopProfit[interval].down[Value],toonNameRealm)
				end
			end
		end
	end
	return values;
end

local updateProfit;
function updateProfit()
	local w,day,T = tonumber(date("%w")),86400,date("*t"); w = w==0 and 7 or w;
	local today = time({year=T.year,month=T.month,day=T.day,hour=23,min=59,sec=59});
	local week = time({year=T.year,month=T.month,day=T.day+(7-w)+1,hour=0,min=0,sec=0})-1;

	Date.daily = { today, today-day, today-day-day };
	Date.weekly = { week, week-(day*7), week-(day*14) };
	Date.monthly = {
		time({year=T.year,month=T.month+1,day=1,hour=0,min=0,sec=0})-1,
		time({year=T.year,month=T.month,day=1,hour=0,min=0,sec=0})-1,
		time({year=T.year,month=T.month-1,day=1,hour=0,min=0,sec=0})-1
	};

	ns.tablePath(ns.toon,name,"profit");
	ns.tablePath(ns.toon,name,"profitv2");
	local money = login_money<ns.toon[name].money and login_money or ns.toon[name].money;
	for interval,timestamp in pairs(Date) do
		-- profit table for current character; get or create
		if not ns.toon[name].profit[interval] then
			ns.toon[name].profit[interval] = {}
		end
		local profitV1 = ns.toon[name].profit[interval];

		if profitV1[timestamp[1]]==nil then
			-- this day/week/month is nil; set 0
			profitV1[timestamp[1]] = 0;
		end

		if profitV1[timestamp[2]]==nil then
			-- yesterday/last week/last month is nil; set 0 as string
			profitV1[timestamp[2]] = "0";
		elseif type(profitV1[timestamp[2]])=="number" then
			-- string is fixed value; today/this week/this month is number and will be a string on change to yesterday/last week/last month
			profitV1[timestamp[2]] = tostring(ns.toon[name].money-profitV1[timestamp[2]]);
		end

		local c = 0; -- cleanup older entries
		for x in ns.pairsByKeys(profitV1,true) do
			c=c+1;
			if c>5 then
				profitV1[x] = nil;
			end
		end

		-- profit table (v2) for current character; get or create
		if not ns.toon[name].profitv2[interval] then
			ns.toon[name].profitv2[interval] = {}
		end
		local profitV2 = ns.toon[name].profitv2[interval];
		for i=1, 3 do
			if not profitV2[timestamp[i]] then
				profitV2[timestamp[i]] = money;
			end
		end

		c = 0; -- cleanup older entries
		for x in ns.pairsByKeys(profitV2,true) do
			c=c+1;
			if c>5 then
				profitV2[x] = nil;
			end
		end
	end

	local validKey={session=true,daily=true,weekly=true,monthly=true,dailyLast=true,weeklyLast=true,monthlyLast=true}
	for k in pairs(ns.toon[name].profit) do
		if not validKey[k] then
			ns.toon[name].profit[k]=nil;
		end
	end
	C_Timer.After(today-time()+1,updateProfit); -- next update
end

local function deleteCharacterGoldData(self,name_realm,button)
	if button == "RightButton" then
		Broker_Everything_CharacterDB[name_realm][name] = nil;
		tt:Clear();
		createTooltip(tt,true);
	end
end

local function updateBroker()
	local broker = {};
	if ns.profile[name].showCharGold then
		tinsert(broker,ns.GetCoinColorOrTextureString(name,ns.toon[name].money,{hideMoney=ns.profile[name].goldHideBB}));
	end
	if ns.profile[name].showProfitSessionBroker and ns.toon[name] then
		local p = getProfit(ns.toon[name],true);
		if p.session~=0 then
			local sign = (p.session>0 and "|Tinterface\\buttons\\ui-microstream-green:14:14:0:0:32:32:6:26:26:6|t") or (p.session<0 and "|Tinterface\\buttons\\ui-microstream-red:14:14:0:0:32:32:6:26:6:26|t") or "";
			tinsert(broker, sign .. ns.GetCoinColorOrTextureString(name,p.session,{hideMoney=ns.profile[name].goldHideBB}));
		end
	end
	updateAccountBankMoney()
	if ns.profile[name].accountBankMoneyBroker and accountBankMoney and accountBankMoney>0 then
		tinsert(broker,(ns.profile[name].accountBankShortcut and L["AccountBankShortcut"].." " or "")..ns.GetCoinColorOrTextureString(name,accountBankMoney,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
	end
	if #broker==0 then
		broker = {BONUS_ROLL_REWARD_MONEY};
	end
	ns.LDB:GetDataObjectByName(module.ldbName).text = table.concat(broker,ns.profile[name].delimiterBB);
end

local function ttAddProfit(all)
	tt:AddSeparator(4,0,0,0,0);
	local l=tt:AddLine(C("ltyellow",L["GoldProfits"]));
	if all then
		tt:SetCell(l,2,C("gray",L["All Chars"]).." "..C("orange","Experimental"))
	end
	tt:AddSeparator();

	local values,valuesV2
	if all then
		values = getProfitAll();
	else
		values = getProfit(ns.toon[name],true)
	end
	for i,v in ipairs(ttLines) do
		if not (i==1 and all) then
			local Value,color,icon = values[v[3]..(v[4] and "Last" or "")] or 0;
			if ns.profile[name].showProfitEmpty and Value==0 then
				color,icon = "gray","";
			elseif Value>0 then
				color,icon = "ltgreen","|Tinterface\\buttons\\ui-microstream-green:14:14:0:0:32:32:6:26:26:6|t";
			elseif Value<0 then
				color,icon,Value = "ltred","|Tinterface\\buttons\\ui-microstream-red:14:14:0:0:32:32:6:26:6:26|t",-Value;
			end
			if color then
				local l = tt:AddLine(C(color,v[2]), icon .. ns.GetCoinColorOrTextureString(name,Value,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
				if i>1 and all then
					tt:SetCell(l,3,C("dkyellow",">"))
					tt:SetLineScript(l,"OnEnter",listProfitOnEnter,{index=i,all=all});
				end
			end
		end
	end
end

function createTooltip(tt,update)
	if not (tt and tt.key and tt.key==ttName) then return end -- don't override other LibQTip tooltips...

	local sAR,sAF = ns.profile[name].showCharsFrom=="4",ns.profile[name].showAllFactions==true;
	local totalGold = {Alliance=0,Horde=0,Neutral=0};
	totalGold[ns.player.faction] = ns.toon[name].money;

	updateAccountBankMoney()
	if accountBankMoney~=nil then
		totalGold.Neutral = accountBankMoney;
	end

	if tt.lines~=nil then tt:Clear(); end

	tt:AddHeader(C("dkyellow",L["Gold information"]));
	tt:AddSeparator(4,0,0,0,0);

	if(sAR or sAF)then
		tt:AddLine(C("ltgreen","("..(sAR and L["All realms"] or "")..((sAR and sAF) and "/" or "")..(sAF and L["AllFactions"] or "")..")"));
		tt:AddSeparator(4,0,0,0,0);
	end

	local faction = ns.player.faction~="Neutral" and " |TInterface\\PVPFrame\\PVP-Currency-"..ns.player.faction..":16:16:0:-1:16:16:0:16:0:16|t" or "";
	tt:AddLine(C(ns.player.class,ns.player.name) .. faction, ns.GetCoinColorOrTextureString(name,ns.toon[name].money,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
	if ns.profile[name].accountBankMoney and accountBankMoney~=nil then
		tt:AddLine(C("dkyellow",ACCOUNT_BANK_PANEL_TITLE),ns.GetCoinColorOrTextureString(name,accountBankMoney,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT,test=true}))
	end
	tt:AddSeparator();


	local lineCount=0;
	for i,toonNameRealm,toonName,toonRealm,toonData,isCurrent in ns.pairsToons(name,{--[[currentFirst=true,]] currentHide=true,--[[forceSameRealm=true]]}) do
		if toonData[name] and toonData[name].money then
			local faction = toonData.faction~="Neutral" and " |TInterface\\PVPFrame\\PVP-Currency-"..toonData.faction..":16:16:0:-1:16:16:0:16:0:16|t" or "";
			local line = tt:AddLine(
				C(toonData.class,ns.scm(toonName)) .. ns.showRealmName(name,toonRealm) .. faction,
				ns.GetCoinColorOrTextureString(name,toonData[name].money,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT})
			);

			tt:SetLineScript(line, "OnMouseUp", deleteCharacterGoldData, toonNameRealm);

			totalGold[toonData.faction] = totalGold[toonData.faction] + toonData[name].money;

			line = nil;
			lineCount=lineCount+1;
		end
	end

	if(lineCount>0)then
		tt:AddSeparator()
		if ns.profile[name].splitSummaryByFaction and ns.profile[name].showAllFactions then
			tt:AddLine(L["Total Gold"].." |TInterface\\PVPFrame\\PVP-Currency-Alliance:16:16:0:-1:16:16:0:16:0:16|t", ns.GetCoinColorOrTextureString(name,totalGold.Alliance,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
			tt:AddLine(L["Total Gold"].." |TInterface\\PVPFrame\\PVP-Currency-Horde:16:16:0:-1:16:16:0:16:0:16|t", ns.GetCoinColorOrTextureString(name,totalGold.Horde,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
			if ns.profile[name].accountBankMoney and accountBankMoney~=nil then
				tt:AddSeparator()
				tt:AddLine(TOTAL..(accountBankMoney and " + "..C("dkyellow",ACCOUNT_BANK_PANEL_TITLE) or ""), ns.GetCoinColorOrTextureString(name,totalGold.Alliance+totalGold.Horde+totalGold.Neutral,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}));
			end
		else
			tt:AddLine(L["Total Gold"], ns.GetCoinColorOrTextureString(name,totalGold.Alliance+totalGold.Horde+totalGold.Neutral,{inTooltip=true,hideMoney=ns.profile[name].goldHideTT}))
		end
	end

	if ns.profile[name].showProfitSession or ns.profile[name].showProfitDaily or ns.profile[name].showProfitWeekly or ns.profile[name].showProfitMonthly then
		ttAddProfit();
	end

	if ns.profile[name].showProfitDailyAll or ns.profile[name].showProfitWeeklyAll or ns.profile[name].showProfitMonthlyAll then
		ttAddProfit(true)
	end

	if ns.profile.GeneralOptions.showHints then
		tt:AddSeparator(4,0,0,0,0);
		ns.AddSpannedLine(tt,C("ltblue",L["MouseBtnR"]).." || "..C("green",L["Remove entry"]));
		ns.ClickOpts.ttAddHints(tt,name);
	end

	if not update then
		ns.roundupTooltip(tt);
	end
end

if (C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account) then
	local function updateToonProfits(value)
		login_money = login_money + value
		for _,interval in ipairs({"daily","weekly","monthly"}) do
			local Table,_date = ns.toon[name].profitv2,Date[interval];
			if Table and type(Table[interval])=="table" then
				Table[interval][_date[1]] = Table[interval][_date[1]] + value;
				Table[interval][_date[2]] = Table[interval][_date[2]] + value;
			end
		end
	end
	hooksecurefunc(C_Bank,"WithdrawMoney",function(bankType, amountToWithdraw)
		if bankType ~= Enum.BankType.Account then return end
		updateToonProfits(amountToWithdraw)
	end)

	hooksecurefunc(C_Bank,"DepositMoney",function(bankType, amountToDeposit)
		if bankType ~= Enum.BankType.Account then return end
		updateToonProfits(-amountToDeposit)
	end)
end


-- module functions and variables --
------------------------------------
module = {
	events = {
		"PLAYER_LOGIN",
		"PLAYER_MONEY",
		"PLAYER_TRADE_MONEY",
		"TRADE_MONEY_CHANGED",
	},
	config_defaults = {
		enabled = true,
		showAllFactions=true,
		showRealmNames=true,
		showCharsFrom="2",
		showCharGold = true,
		showProfitSessionBroker = true,
		splitSummaryByFaction = true,
		showProfitSession = true,
		showProfitDaily = true,
		showProfitWeekly = true,
		showProfitMonthly = true,
		showProfitDailyAll = true,
		showProfitWeeklyAll = true,
		showProfitMonthlyAll = true,
		showProfitTop = true,
		numProfitTop = 3,
		showProfitEmpty = true,
		goldHideBB = "0",
		goldHideTT = "0",
		accountBankMoneyBroker = true,
		accountBankMoney = true,
		accountBankShortcut = true,
		delimiterBB = ", ",
		profitMethod = 2,
	},
	new = {
		showProfitDailyAll = true,
		showProfitWeeklyAll = true,
		showProfitMonthlyAll = true,
		showProfitEmpty = true,
		showProfitTop = true,
		numProfitTop = true,
		accountBankMoneyBroker = true,
		accountBankMoney = true,
		accountBankShortcut = true,
		delimiterBB = true,
	},
	clickOptionsRename = {
		["1_open_tokenframe"] = "currency",
		["2_open_character_info"] = "charinfo",
		["3_open_bags"] = "bags",
		["4_open_menu"] = "menu"
	},
	clickOptions = {
		["currency"] = "Currency",
		["charinfo"] = "CharacterInfo",
		["bags"] = {"Open all bags","call","ToggleAllBags"}, -- L["Open all bags"]
		["menu"] = "OptionMenuCustom"
	}
}

ns.ClickOpts.addDefaults(module,{
	currency = "_LEFT",
	charinfo = "__NONE",
	bags = "__NONE",
	menu = "_RIGHT"
});

function module.options()
	return {
		broker = {
			goldHideBB = 0,
			delimiterBB = 1,
			showCharGold={ type="toggle", order=2, name=L["Show character gold"],     desc=L["Show character gold on broker button"] },
			showProfitSessionBroker={ type="toggle", order=3, name=L["Show session profit"],     desc=L["Show session profit on broker button"] },
			accountBankMoneyBroker = {type="toggle", order=4, name=ACCOUNT_BANK_PANEL_TITLE or "Warband bank", desc=L["AccountBankMoneyBrokerDesc"], hidden=ns.IsClassicClient},
			accountBankShortcut = {type="toggle", order=5, name=L["AccountBankShortcutBB"], desc=L["AccountBankShortcutBBDesc"], hidden=ns.IsClassicClient},
		},
		tooltip = {
			goldHideTT = 1,
			showAllFactions=2,
			showRealmNames=3,
			showCharsFrom=4,
			splitSummaryByFaction={type="toggle",order=5, name=L["Split summary by faction"], desc=L["Separate summary by faction (Alliance/Horde)"] },
			accountBankMoney = {type="toggle",order=6, name=ACCOUNT_BANK_PANEL_TITLE or "Warband bank", desc=L["AccountBankMoneyDesc"], hidden=ns.IsClassicClient},

			profit = {
				type = "group", order=7, inline = true,
				name = L["GoldProfits"],
				args = {
					showProfitEmpty = { type="toggle", order=1, name=L["GoldProfitEmpty"], desc=L["GoldProfitEmptyDesc"]},
					profitHeader1 = { type="header", order=10, name=L["GoldProfitThis"] },
					showProfitSession = { type="toggle", order=11, name=L["GoldProfitSession"], desc=L["GoldProfitSessionDesc"]},
					showProfitDaily   = { type="toggle", order=12, name=L["GoldProfitDaily"],   desc=L["GoldProfitDailyDesc"] },
					showProfitWeekly  = { type="toggle", order=13, name=L["GoldProfitWeekly"],  desc=L["GoldProfitWeeklyDesc"] },
					showProfitMonthly = { type="toggle", order=14, name=L["GoldProfitMonthly"], desc=L["GoldProfitMonthlyDesc"] },
					profitHeader2 = { type="header", order=20, name=L["GoldProfitAll"] },
					showProfitDailyAll   = { type="toggle", order=22, name=L["GoldProfitDaily"],   desc=L["GoldProfitDailyAllDesc"] },
					showProfitWeeklyAll  = { type="toggle", order=23, name=L["GoldProfitWeekly"],  desc=L["GoldProfitWeeklyAllDesc"] },
					showProfitMonthlyAll = { type="toggle", order=24, name=L["GoldProfitMonthly"], desc=L["GoldProfitMonthlyAllDesc"] },
					showProfitTop = { type = "toggle", order=25, name=L["GoldProfitTop"], desc=L["GoldProfitTopDesc"]},
					numProfitTop = { type = "range", order=26, name=L["GoldProfitTopNum"], desc=L["GoldProfitTopNumDesc"], min=2, max=20, step=1},
				},
			},
		},
		misc = {
			shortNumbers=1,
		},
	}
end

function module.OptionMenu(self,button,modName)
	if (tt~=nil) and (tt:IsShown()) then ns.hideTooltip(tt); end
	ns.EasyMenu:InitializeMenu();
	ns.EasyMenu:AddConfig(name);
	ns.EasyMenu:AddEntry({separator=true});
	ns.EasyMenu:AddEntry({ label = C("yellow",L["Reset session profit"]), func=function() module.onevent(nil,"PLAYER_LOGIN"); end, keepShown=false });
	ns.EasyMenu:ShowMenu(self);
end

function module.init()
	module.lockFirstUpdate = true
	if not ns.toon[name] then
		ns.toon[name] = {}
	end
	migrateData()
end

function module.onevent(self,event,arg1)
	if event=="BE_UPDATE_CFG" and arg1 and arg1:find("^ClickOpt") then
		ns.ClickOpts.update(name);
	else
		if event=="PLAYER_LOGIN" then
			C_Timer.After(0.5,function()
				ns.toon[name].money = GetMoney();
				if login_money==nil and ns.toon[name].money~=nil then
					login_money = ns.toon[name].money;
				end
				updateProfit();
				updateBroker();
				module.lockFirstUpdate = false;
			end);
		elseif ns.eventPlayerEnteredWorld and (not module.lockFirstUpdate) and login_money~=nil then
			ns.toon[name].money = GetMoney();
			updateBroker();
		end
	end
end

-- function module.optionspanel(panel) end
-- function module.onmousewheel(self,direction) end
-- function module.ontooltip(tt) end

function module.onenter(self)
	if (ns.tooltipChkOnShowModifier(false)) then return; end
	tt = ns.acquireTooltip({ttName, 3, "LEFT", "RIGHT","RIGHT"},{false},{self})
	createTooltip(tt);
end

-- function module.onleave(self) end
-- function module.onclick(self,button) end
-- function module.ondblclick(self,button) end


-- final module registration --
-------------------------------
ns.modules[name] = module;
