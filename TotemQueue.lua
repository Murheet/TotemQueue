addon_name = "TotemQueue"
ToQuChar = string.lower(UnitName("player"))
ThisCharacter = string.lower(UnitName("player"))
ToQuRealm = string.lower(GetRealmName())
ToQu_variablesLoaded = false

Totem ={}
Totem["air"]={}
Totem["water"]={}
Totem["earth"]={}
Totem["fire"]={}

Totem["air"]["tframe"] = Totem_Air_Frame
Totem["air"]["texture"] = Totem_Air_Texture
Totem["air"]["totemlist"] = {25587, 25359, 3738,10601,8177,25908,15112, 0}
Totem["air"]["off"] = 136107

Totem["water"]["tframe"] = Totem_Water_Frame
Totem["water"]["texture"] = Totem_Water_Texture
Totem["water"]["totemlist"] = {25570, 38306, 25567,25563,8170, 0}
Totem["water"]["off"] = 134714

Totem["earth"]["tframe"] = Totem_Earth_Frame
Totem["earth"]["texture"] = Totem_Earth_Texture
Totem["earth"]["totemlist"] = {2484,10428,10408,25361,8143, 0}
Totem["earth"]["off"] = 134572

Totem["fire"]["tframe"] = Totem_Fire_Frame
Totem["fire"]["texture"] = Totem_Fire_Texture
Totem["fire"]["totemlist"] = {2894,	 25547, 25552, 25560,25533,30706, 0}
Totem["fire"]["off"] = 135805



OrderShort ={}
OrderShort["a"]="air"
OrderShort["w"]="water"
OrderShort["e"]="earth"
OrderShort["f"]="fire"

-- default config settings
TotemQueueConfig_defaultOn 		= true
TotemQueueConfig_defaultPosition	= {0, 0}
TotemQueueConfig_defaultSize = 32

function TotemQueueFrame_OnLoad(self)
	-- register events
	print("TotemQueue loaded")
	-- Globals
	self:RegisterEvent("ADDON_LOADED")
	TotemQueueFrame:Show()
	ToQu_ConfigChange()
end

function TotemQueue_VARIABLES_LOADED(self)
	-- initialize our SavedVariable

	if (not TotemQueueConfig) then TotemQueueConfig = {} end
	if (not TotemQueueConfig[ToQuRealm]) then TotemQueueConfig[ToQuRealm] = {} end
	if (not TotemQueueConfig[ToQuRealm][ToQuChar]) then TotemQueueConfig[ToQuRealm][ToQuChar] = {} end

	-- load each option, set default if not there
	if (not TotemQueueConfig[ToQuRealm][ToQuChar].on) then TotemQueueConfig[ToQuRealm][ToQuChar].on = TotemQueueConfig_defaultOn end	

	if (not TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem) then 
		TotemQueueConfig[ToQuRealm][ToQuChar]["currentTotem"] = {} 
		TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem["air"] = 1
		TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem["water"] = 1
		TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem["earth"] = 1
		TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem["fire"] = 1
	end

	if (not TotemQueueConfig[ToQuRealm][ToQuChar].order) then 
		TotemQueueConfig[ToQuRealm][ToQuChar]["order"] = {} 
		TotemQueueConfig[ToQuRealm][ToQuChar].order["air"] = 1
		TotemQueueConfig[ToQuRealm][ToQuChar].order["water"] = 2
		TotemQueueConfig[ToQuRealm][ToQuChar].order["earth"] = 3
		TotemQueueConfig[ToQuRealm][ToQuChar].order["fire"] = 4
	end

	if (not TotemQueueConfig[ToQuRealm][ToQuChar].position) then TotemQueueConfig[ToQuRealm][ToQuChar].position = TotemQueueConfig_defaultPosition end	
	if (not TotemQueueConfig[ToQuRealm][ToQuChar].size) then TotemQueueConfig[ToQuRealm][ToQuChar].size = TotemQueueConfig_defaultSize end

	ToQu_variablesLoaded = true
end

function TotemQueueFrame_OnEvent(self, event, ...)
	if(event == "ADDON_LOADED") then
		if not(ToQu_variablesLoaded) then TotemQueue_VARIABLES_LOADED() end

		ToQu_ConfigChange()
	end
end

function Totem_Frame_Click(self, btn,...)
	if not(UnitAffectingCombat("player")) then
		ClickedFrame = self:GetName()

		for key,value in pairs(Totem) do
			if ClickedFrame == value["tframe"]:GetName() then 
				
				local totCount = table.getn(Totem[key]["totemlist"])
				local currentIndex = TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem[key]
				local nextIndex = nil
				if btn == "LeftButton" then
					nextIndex = currentIndex+1
					if nextIndex > totCount then nextIndex = 1 end

				elseif btn == "RightButton" then
					nextIndex = currentIndex-1
					if nextIndex == 0  then nextIndex = totCount end
				end 

				TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem[key] = nextIndex
				ToQu_ConfigChange()
				--Totem[key]["texture"]:SetTexture(GetSpellTexture(Totem[key]["totemlist"][nextIndex]))
				break
			end
		end
	end
end

function Write_Macro()
	local initMacroText = "#showtooltip\n/castsequence reset=10 "
	local MacroText = initMacroText

	for x = 1, 4 do
		for key,value in pairs(Totem) do
			if x == TotemQueueConfig[ToQuRealm][ToQuChar].order[key] then 
				local listIndex = TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem[key]
				local TotID = Totem[key]["totemlist"][listIndex]
				if TotID ~= 0 then 
					local SpellName = select(1, GetSpellInfo(TotID))
					MacroText = MacroText .. SpellName  ..  ", " 
					-- if TotemQueueConfig[ToQuRealm][ToQuChar].order[key] < 4 then MacroText = MacroText ..  ", " end
				end
				break
			end
		end
	end
	MacroText=strsub(MacroText, 1, #MacroText-2)
	local macroIndex = GetMacroIndexByName("TotemQueue")
	
	if macroIndex == 0 then
		CreateMacro("TotemQueue", 136232, MacroText, 1)
	else
		EditMacro("TotemQueue",nil, nil, MacroText, 1)
	end
end

--###########################################################
--#					Configuration Change					#
--###########################################################

 function ToQu_ConfigChange(self)
	-- make sure that our profile has been loaded before allowing this function to be called
	if (not ToQu_variablesLoaded) then -- config not loaded
		TotemQueueFrame:Hide() -- turn our mod off
		return
	end
		
	local size = TotemQueueConfig[ToQuRealm][ToQuChar].size
	for key,value in pairs(Totem) do
		if Totem[key]["tframe"]:GetSize() ~= {size, size} then
			Totem[key]["tframe"]:SetSize(size, size)
			Totem[key]["texture"]:SetSize(size, size)
		end

		local order = TotemQueueConfig[ToQuRealm][ToQuChar].order[key]
		local xOfs = (order-1) * size
		local curxOfs = select(4, Totem[key]["tframe"]:GetPoint())
		if xOfs ~= curxOfs then
			Totem[key]["tframe"]:SetPoint("LEFT", xOfs, 0)
		end
	
		local curTexture = Totem[key]["texture"]:GetTexture()
		local currentTotem = TotemQueueConfig[ToQuRealm][ToQuChar].currentTotem[key]

		local Txture = GetSpellTexture(Totem[key]["totemlist"][currentTotem])
		if curTexture ~= Txture then
			if Totem[key]["totemlist"][currentTotem]==0 then
				Totem[key]["texture"]:SetTexture(Totem[key]["off"])
				Totem[key]["texture"]:SetDesaturated(1)
				Totem[key]["texture"]:SetSize(size*0.9, size*0.9)
			else
				Totem[key]["texture"]:SetTexture(Txture)
				Totem[key]["texture"]:SetDesaturated(nil)
			end
		end
	end

	TotemQueueFrame:SetPoint("CENTER", TotemQueueConfig[ToQuRealm][ToQuChar].position[1], TotemQueueConfig[ToQuRealm][ToQuChar].position[2])

	-- make sure to use the frame's name here, cannot rely on 'this' to mean the main frame
	if (TotemQueueConfig[ToQuRealm][ToQuChar].on) then
		TotemQueueFrame:Show() -- show our mod frame
	else
		TotemQueueFrame:Hide() -- hide our mod frame
	end

	Write_Macro()
 end
 


function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
  end

function has_value (tab, val)
    for index, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

--###########################################################
--#						Slash commands						#
--###########################################################
SLASH_ToQu1 = "/totemqueue"
SLASH_ToQu2 = "/tq"

SlashCmdList["ToQu"] = function(msg, editbox)
	if msg == "toggle" or msg == "" then
		local state =""
		 if TotemQueueFrame:IsShown() then state = "hidden" else state= "visible" end
		print("TotemQueue: " .. state)
		TotemQueueConfig[ToQuRealm][ToQuChar].on = not(TotemQueueFrame:IsShown())
		ToQu_ConfigChange()

	elseif strsub(msg, 1, #"set ") == "set " then
		local xy= strsub(msg, #"set ")
		local splitIndex = string.find(xy, ",")
		local x = tonumber(strsub(xy, 1, splitIndex-1))
		local y = tonumber(strsub(xy, splitIndex+1))

		print("TotemQueue position set: x:".. x ..", y:" ..  y)
		TotemQueueConfig[ToQuRealm][ToQuChar].position = {x, y}
		ToQu_ConfigChange()

	elseif msg == "position" then
		local _, _, _, xOfs, yOfs = TotemQueueFrame:GetPoint()
		print("TotemQueue position: x:".. xOfs ..", y:" .. yOfs)

	elseif strsub(msg, 1, #"move ") == "move " then
		local _, _, _, xOfs, yOfs = TotemQueueFrame:GetPoint()
		local xy= strsub(msg, #"move ")
		local splitIndex = string.find(xy, ",")
		local x = tonumber(strsub(xy, 1, splitIndex-1)) 
		local y = tonumber(strsub(xy, splitIndex+1)) 
		print("TotemQueue moved by: x:".. x ..", y:" .. y)

		TotemQueueConfig[ToQuRealm][ToQuChar].position = {x+ xOfs, y+ yOfs}
		ToQu_ConfigChange()

	elseif strsub(msg, 1, #"size ") == "size "then
		local sizemsg= strsub(msg, #"size ")
		TotemQueueConfig[ToQuRealm][ToQuChar].size = tonumber(sizemsg)
		ToQu_ConfigChange()
	
	elseif strsub(msg, 1, #"order ") == "order " then
		local orderStr = strlower(strsub(msg, #"order  "))
		local orderError = false
		local repeatCheck = {}

		if #orderStr == 4 then 	
			for i = 1, #orderStr do
				local c = strsub(orderStr, i, i)

				if not(has_value({"a","e","f","w"}, c)) then orderError = true end
				if has_value(repeatCheck, c) then orderError = true end
				repeatCheck[i] = c
			end
		end

		if orderError then 
			print("TotemQueue: Invalid order string :" .. orderStr)
		else 
			print("TotemQueue: Changing frame order:" .. orderStr)
			for index, value in pairs(repeatCheck) do
				TotemQueueConfig[ToQuRealm][ToQuChar].order[OrderShort[value]] = index
			end

			ToQu_ConfigChange()
		end

	elseif msg == "resist posse" then
		print("Jysk.")
	elseif msg == "help" then
		print("TotemQueue by Murhe")
		print("Chat commands:")
		print(" -toggle: show and hide Totem Queue frame.")
		print(" -position: get current position of Totem Queue frame.")
		print(" -set x, y: set a position of Totem Queue frame.")
		print(" -move x, y: offset position of Totem Queue frame.")
		print(" -size S: SxS size of each icon.")
	else 
		print("TotemQueue: command not recognized.")
		print("Chat commands:")
		print(" -toggle: show and hide Totem Queue frame.")
		print(" -position: get current position of Totem Queue frame.")
		print(" -set x, y: set a position of Totem Queue frame.")
		print(" -move x, y: offset position of Totem Queue frame.")
		print(" -size S: SxS size of each icon.")
	end
end