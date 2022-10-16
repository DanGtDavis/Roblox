--This script detects vulnerable remotes

--## Settings ##--
local GetStringsFromMemory = true
local GetNumbersFromMemory = true

local MaxPingValue = 1000

local Output = false

local SleepTime = 1

--You can add more values to this table
local DefaultAttackTb = {
	2,
	1,
	0,
	true,
	false,
	Vector2.new(0,0),
	Vector2.new(500,500),
	UDim2.new(0,0,0,0),
	UDim2.new(0.5,0,0.5,0),
	999,
	666,
	555,
	9e9,
	Vector3.new(0,0,0),
	Vector3.new(500,500,500),
	Vector3.new(0/0,0/0,0/0),
	CFrame.new(Vector3.new(0,0,0)),
	CFrame.new(Vector3.new(500,500,500)),
	CFrame.new(Vector3.new(0/0,0/0,0/0)),
	Color3.new(0,0,0),
	Color3.new(1,1,1),
	game:GetService("Players").LocalPlayer,
	game:GetService("Players").LocalPlayer.Name,
	nil,
	100
}

local BlockedScripts = {
	"Util", --ClientChatModules script, displays messages
	"ChatMain", --Another chat script
	"PlayerModule",
	"CameraModule",
	"CameraUtils",
	"BaseCamera"
}


local RemotesBlacklist = {
	"TeleportPlayer",
	"CharacterSoundEvent",
	"ClickEvent",
	"CanChatWith",
	"SetPlayerBlockList",
	"UpdatePlayerBlockList",
	"NewPlayerGroupDetails",
	"NewPlayerCanManageDetails",
	"SetDialogInUse",
	"GetServerVersion",
	"IntegrityCheckProcessorKey_LocalizationTableEntryStatisticsSender_LocalizationService",
	"OnNewMessage",
	"OnMessageDoneFiltering",
	"OnNewSystemMessage",
	"OnChannelJoined",
	"OnChannelLeft",
	"OnMuted",
	"OnUnmuted",
	"OnMainChannelSet",
	"ChannelNameColorUpdated",
	"SayMessageRequest",
	"SetBlockedUserIdsRequest",
	"GetInitDataRequest",
	"MutePlayerRequest",
	"UnMutePlayerRequest",
}




--## CODE ##--

local TimesFired = 0
local function FireRemote(Remote, ...)
	TimesFired = TimesFired + 1

	local args = {...}

	if Remote:IsA("RemoteEvent") then
		Remote:FireServer(...)
	elseif Remote:IsA("RemoteFunction") then
		coroutine.wrap(function()
			pcall(function()
				Remote:InvokeServer(table.unpack(args))
			end)
		end)()
	end

	if game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() >= MaxPingValue  then
		repeat task.wait() until game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() <= MaxPingValue
	end

	if TimesFired % 200 == 0 then
		task.wait()
	end
end


if not isfile("KickRemotes.json") then
	writefile("KickRemotes.json", "[]")
end

if not pcall(function() game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json")) end) then
	rconsoleprint("KickRemotes.json has been broken, creating a new file!\n")
	writefile("KickRemotes.json", "{}")
end

if not game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json"))[tostring(game.PlaceId)] then
	local old = game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json"))
	old[tostring(game.PlaceId)] = {}
	writefile("KickRemotes.json", game:GetService("HttpService"):JSONEncode(old))
end

local KickRemotes = game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json"))[tostring(game.PlaceId)]

rconsoleprint(string.format("%s Kick Remotes has been loaded!\n", tostring(#KickRemotes)))

local NewStrings = {}
local NewNumbers = {}

--Get values from memory
if GetStringsFromMemory or GetNumbersFromMemory then
	local StringBlacklist = {}
	local NumberBlacklist = {}

	local Strings = {}
	local Numbers = {}

	local old = {}

	local CheckTable;
	local CheckFunction;

	CheckFunction = function(Function,Index)
		if not getfenv(Function)["writefile"] and not table.find(BlockedScripts,tostring(getfenv(Function).script)) then
			for i, v in pairs(debug.getconstants(Function)) do
				if typeof(v) == "table" then
					if not table.find(old, v) then
						table.insert(old, v)
						CheckTable(v, Index + 2)
					end
				elseif typeof(v) == "function" then
					if not table.find(old, v) then
						table.insert(old, v)
						CheckFunction(v, Index + 2)
					end
				elseif typeof(v) == "number" and GetNumbersFromMemory then
					table.insert(Numbers, v)
				elseif typeof(v) == "string" and GetStringsFromMemory then
					table.insert(Strings, v)
				end
			end
			for i,v in pairs(debug.getupvalues(Function)) do
				if typeof(v) == "table" then
					if not table.find(old, v) then
						table.insert(old, v)
						CheckTable(v, Index + 2)
					end
				elseif typeof(v) == "function" then
					if not table.find(old, v) then
						table.insert(old, v)
						CheckFunction(v, Index + 2)
					end
				elseif typeof(v) == "number" and GetNumbersFromMemory then
					table.insert(Numbers, v)
				elseif typeof(v) == "string" and GetStringsFromMemory then
					table.insert(Strings, v)
				end
			end
			for i,v in pairs(debug.getprotos(Function)) do
				if typeof(v) == "function" then
					if not table.find(old, v) then
						table.insert(old, v)
						CheckFunction(v, Index + 2)
					end
				end
			end
		end	
	end

	CheckTable = function(Table, Index)
		for i,v in pairs(Table) do
			if typeof(v) == "table" then
				if not table.find(old, v) then
					table.insert(old, v)
					CheckTable(v, Index + 1)
				end
			elseif typeof(v) == "function" then
				if not table.find(old, v) then
					table.insert(old, v)
					CheckFunction(v, Index + 1)
				end
			elseif typeof(v) == "number" and GetNumbersFromMemory then
				table.insert(Numbers, v)
			elseif typeof(v) == "string" and GetStringsFromMemory then
				table.insert(Strings, v)
			end
		end

	end


	for i,v in pairs(debug.getregistry()) do
		if typeof(v) == "function" then
			pcall(function()
				CheckFunction(v,1 )
			end)
		elseif typeof(v) == "table" then
			if v ~= old then
				pcall(function()
					CheckTable(v,1 )
				end)
			end
		end	
	end


	for i,v in pairs(Strings) do
		if not table.find(NewStrings, v) and not table.find(StringBlacklist, v) then  
			table.insert(NewStrings, v)    
		end    
	end

	for i,v in pairs(Numbers) do
		if not table.find(NewNumbers, v) and not table.find(NumberBlacklist, v) then  
			table.insert(NewNumbers, v)    
		end    
	end 

	rconsoleprint("Content has been loaded from memory!\n")
end

for i,v in pairs(getconnections(game:GetService("Players").LocalPlayer.Idled)) do
	v:Disable()
end

local Remotes = {}

for i,v in pairs(game:GetDescendants()) do
	if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and not table.find(RemotesBlacklist, v.Name) and not table.find(KickRemotes, v.Name) then
		table.insert(Remotes, v)    
	end    
end    

rconsoleprint(tostring(#Remotes).. " Remotes found! Finding vulnerable remotes...\n")

local FiredRemotes = {}

--Kick detection
local Connection; Connection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
	local ErrorCode = game:GetService("GuiService"):GetErrorCode()
	if (ErrorCode == Enum.ConnectionError.DisconnectLuaKick) then
		local old = game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json"))

		table.insert(old[tostring(game.PlaceId)], Remotes[#FiredRemotes].Name)

		writefile("KickRemotes.json", game:GetService("HttpService"):JSONEncode(old))

		rconsoleprint(Remotes[#FiredRemotes].Name.." Has been saved as a kick remote! Rejoining...\n")

		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
		return Connection:Disconnect()
	end
end)

coroutine.wrap(function()
	while wait(0.5) do
		rconsolename(("Remotes checker || Remotes fired: %s, Remotes remaining: %s, Ping: %s"):
			format(tostring(#FiredRemotes), tostring(#Remotes - #FiredRemotes), tostring(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())))
	end
end)()


for i,v in pairs(Remotes) do
	if game:GetService("GuiService"):GetErrorCode() ~= Enum.ConnectionError.OK then
		return 
	end
	
	table.insert(FiredRemotes, v)
	rconsoleprint("Checking "..v:GetFullName().." ("..v.ClassName..")\n")

	if GetStringsFromMemory then
		for i1,v1 in pairs(NewStrings) do
			FireRemote(v, v1)
		end
	end

	if GetNumbersFromMemory then
		for i1,v1 in pairs(NewNumbers) do
			FireRemote(v, v1)
		end
	end

	for i1,v1 in pairs(DefaultAttackTb) do
		FireRemote(v, v1)
	end 


	wait(SleepTime)
	
	local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
	local NewPing = Ping

	if NewPing == Ping then
		local T_ = 0
		repeat task.wait()
			if T_ == 1200 then
				rconsoleprint("[Info]: You probably found a remote that crashes a server.\n")
				rconsoleprint(("[Info]: Remote path: %s [%s]\n"):format(v:GetFullName(), v.ClassName))
			elseif T_ == 3000 then
				rconsoleprint("Rejoining...\n")

				local Table = game:GetService("HttpService"):JSONDecode(readfile("KickRemotes.json"))
				table.insert(Table[tostring(game.PlaceId)], v.Name)
				writefile("KickRemotes.json", game:GetService("HttpService"):JSONEncode(Table))

				return game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
			end
			NewPing = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			T_ = T_ + 1	
		until NewPing ~= Ping
	end
end    
