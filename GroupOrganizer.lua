local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:RegisterEvent("PLAYER_LOGIN")

SLASH_GO1, SLASH_GO2 = '/go', '/grouporganizer';

local waitTable = {};
local waitFrame = nil;
local userTable = {};
local globalToken = nil;
local dungeonDict = {}

local infight = false
local enabled = true

local lfgTab = {};
local lfgo_mtab = {};

local roletab = { "dps" , "heal", "tank", "rogue", "mage", "warlock", "warr", "hunt", "sham", "pala", "priest" }

local dungeonMinTab = {}
local dungeonMaxTab = {}

local maxMinutes = 10

function GROUPORGANIZER__wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

local function tconcat(t) 
	if #t == 1 then 
		return t[1]
	else 
		local res = ''
		for i=1,#t-1,1 do
			res = res..t[i]..', '
		end 
		res = res..t[#t]
		return res 
	end 
end

local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function stringsplit(s, sep)
	local res = {}
	for i in string.gmatch(s, "%S+") do
		local x,_ = string.gsub(i, ",", "")
		x,_ = string.gsub(x, "\\.","")
		table.insert(res, x)
	end
	return res
end

function getTableLength(t)
	local cnt = 0
	for k,v in ipairs(t) do 
		cnt = cnt + 1
	end
	return cnt
end

function filterName(name) 
	if string.find(name, "-") == nil then 
		return name
	else 
		return string.sub(name, 1, string.find(name, "-")-1)
	end
end

function frame:OnEvent(event,...)
	if event == "CHAT_MSG_CHANNEL" then 
		a,b,c,d,e,f = ...
		--ChatFrame1:AddMessage(a.." "..b.." "..c.." "..d)
		
		-- split string into words 
		splitString = stringsplit(a,nil)
		
		--ChatFrame1:AddMessage("aa")
		
		for k,v in pairs(dungeonDict) do 
			--ChatFrame1:AddMessage(k)
			--ChatFrame1:AddMessage(v)
			--search for dungeon appearance in string 
			for i=1,#splitString,1 do
				for j=1,#v,1 do
					--ChatFrame1:AddMessage("Compare "..string.lower(splitString[i]).." || "..v[j])
					if string.lower(splitString[i]) == v[j] then 
						--ChatFrame1:AddMessage("found dungeon: "..k)

						--extract role(s) 
						local role = ""
						
						for rk, rv in ipairs(roletab) do 
							if string.match(string.lower(a), rv) ~= nil then 
								role = role..string.upper(rv).." "
							end 
						end 
						
						if role == "" then
							role = "unknown"
						end
						
						local mode = nil 
						-- find out if LFM or LFG
						if(string.match(string.lower(a),"lfg") ~= nil) then 
							--ChatFrame1:AddMessage("found mode: LFG")
							mode = "lfg"
						elseif(string.match(string.lower(a),"lf.*m?") ~= nil) then 
							--ChatFrame1:AddMessage("found mode: LFM")	
							mode = "lfm"
						end
						
						if mode ~= nil then 
							

							-- dungeon is k
							-- mode is mode
	
							if go_mtab[k] == nil then 
								go_mtab[k] = {}
								go_mtab[k]["lfg"] = {}
								go_mtab[k]["lfm"] = {}
							end 
							
							
							go_mtab[k][mode][filterName(b)] = role
							
							--ChatFrame1:AddMessage(getTableLength(entry))
							--check if insert already in 
							
							go_ttab[k.."#"..mode.."#"..filterName(b).."#"..role] = time()
						end
						
					end
				end
			end
		end
		
		
	elseif event == "PLAYER_LOGIN" then 
		ChatFrame1:AddMessage("started")
		
		if go_mtab == nil then 
			go_mtab = {}
		end
		
		if go_ttab == nil then 
			go_ttab = {}
		end
		
		dungeonDict["Ragefire Chasm"] = { "ragefire", "rage", "rfc" }
		dungeonDict["Deadmines"] = { "dm","deadmines","vc" }
		dungeonDict["Wailing Caverns"] = { "wc", "wailing", "caverns" }
		dungeonDict["The Stockade"] = { "stock","stockades", "stockade"}
		dungeonDict["Blackfathom Deeps"] = {"bfd"} 
		dungeonDict["Scarlet Monestary"] = {"sm", "scarlet", "monestary", "monest"} 
		dungeonDict["Shadowfang Keep"] = {"sfk","shadowfang", "shadowfang keep"} 
		dungeonDict["Razorfen Kraul"] = {"rfk","razforen kral"} 
		dungeonDict["Gnomeregan"] = {"gnom", "gnomer", "gnomeregan"} 
		dungeonDict["Razorfen Downs"] = { "downs", "rfd"}
		dungeonDict["Uldaman"] = { "ulda", "ud", "uldaman"}
		dungeonDict["Maraudon"] = { "mara", "marau", "maraudon"}
		dungeonDict["Zul'Farrak"] = { "zf", "farrak", "zul"}
		dungeonDict["Sunken Temple"] = { "st", "sunken", "temple"}
		dungeonDict["Blackrock Depths"] = {"brd", "blackrock"}
		--dungeonDict["Dire Maul"] = {""}
		
		
		dungeonMinTab["Ragefire Chasm"] = 13
		dungeonMinTab["Deadmines"] = 16
		dungeonMinTab["Wailing Caverns"] = 17
		dungeonMinTab["Shadowfang Keep"] = 20
		dungeonMinTab["Blackfathom Deeps"] = 23
		dungeonMinTab["The Stockade"] = 24
		dungeonMinTab["Gnomeregan"] = 29
		dungeonMinTab["Razorfen Kraul"] = 29
		dungeonMinTab["Scarlet Monestary"] = 33
		dungeonMinTab["Razorfen Downs"] = 37
		dungeonMinTab["Uldaman"] = 38
		dungeonMinTab["Maraudon"] = 40
		dungeonMinTab["Zul'Farrak"] = 43
		dungeonMinTab["Sunken Temple"] = 44
		dungeonMinTab["Blackrock Depths"] = 48
		dungeonMinTab["Dire Maul"] = 56
		
		dungeonMaxTab["Ragefire Chasm"] = 20
		dungeonMaxTab["Deadmines"] = 26
		dungeonMaxTab["Wailing Caverns"] = 24
		dungeonMaxTab["Shadowfang Keep"] = 28
		dungeonMaxTab["Blackfathom Deeps"] = 30
		dungeonMaxTab["The Stockade"] = 32
		dungeonMaxTab["Gnomeregan"] = 38
		dungeonMaxTab["Razorfen Kraul"] = 38
		dungeonMaxTab["Scarlet Monestary"] = 44
		dungeonMaxTab["Razorfen Downs"] = 46
		dungeonMaxTab["Uldaman"] = 46
		dungeonMaxTab["Maraudon"] = 50
		dungeonMaxTab["Zul'Farrak"] = 50
		dungeonMaxTab["Sunken Temple"] = 52
		dungeonMaxTab["Blackrock Depths"] = 56
		dungeonMaxTab["Dire Maul"] = 60
		
		--ChatFrame1:AddMessage(dungeonDict["Deadmines"][2])
	end
end



local function handler(msg, editbox) 
	--ChatFrame1:AddMessage("test")
	
	
	if string.lower(msg) == "clear" then 
		go_mtab = {}
		go_ttab = {}
		return;
	end 
	
	
	local anything = false
	
	for k,v in pairs(go_mtab) do 
	
		if (msg ~= nil and string.lower(msg) == "all") or ( UnitLevel("player") >= dungeonMinTab[k] and UnitLevel("player") <= dungeonMaxTab[k] ) then 
			anything = true
			ChatFrame1:AddMessage(k.." ("..dungeonMinTab[k].."-"..dungeonMaxTab[k]..")")
			for k1,v1 in pairs(v) do 
				for k2,v2 in pairs(v1) do
					timePast = go_ttab[k.."#"..k1.."#"..k2.."#"..v2]
					
					if timepast == nil then 
						timepast = 9999
					end 
					
					timeDiff = time() - timePast
					
					local timeMessage = nil
					if timeDiff < 60 then 
						timeMessage = timeDiff.." seconds ago"
					else 
						timeMessage = math.floor(timeDiff/60).." minutes ago"
					end
					
					if timeDiff < maxMinutes * 60 then 
						ChatFrame1:AddMessage("  "..k1..": "..k2.." Role: "..v2.." "..timeMessage)
					end
				end
			end
		end
	end
	
	if anything == false then 
		ChatFrame1:AddMessage("GroupOrganizer: nothing to show. Try /go all")
	end
	
end

SlashCmdList["GO"] = handler;
frame:SetScript("OnEvent", frame.OnEvent)