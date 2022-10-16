--Game: Rememed meme game (https://www.roblox.com/games/6031035699/rememed-meme-game)

if game.PlaceId ~= 6031035699 then return end
if getfenv()._H4X then
	return warn("Already running!")
end

getgenv()._H4X = true

game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()


repeat task.wait() until game:IsLoaded()

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")
local Chat = game:GetService("Chat")
local Stats = game:GetService("Stats")
local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")

local EmptyVector3 = Vector3.new()

local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local ShootEvent = ReplicatedStorage.visualBullets
local RespawnEvent = ReplicatedStorage.Respawn
local StartTauntEvent = ReplicatedStorage.startTaunt
local ServerHitReg = ReplicatedStorage.serverhitReg

local _GetPropertyChangedSignal = game.GetPropertyChangedSignal
local _FindFirstChild = game.FindFirstChild
local _WorldToScreenPoint = Workspace.CurrentCamera.WorldToScreenPoint

Workspace.FallenPartsDestroyHeight = 0/0
LocalPlayer.CameraMaxZoomDistance = 9999

--Read blacklist
if not (isfile("BlacklistedPpl.json")) then
	writefile("BlacklistedPpl.json", "[]")
end
--Read whitelist
if not isfile("WhitelistedPpl.json") then
	writefile("WhitelistedPpl.json", "[]")
end

local Blacklist = HttpService:JSONDecode(readfile("BlacklistedPpl.json"))
local Whitelist = HttpService:JSONDecode(readfile("WhitelistedPpl.json"))

local function SaveWhitelist()
	writefile("WhitelistedPpl.json", HttpService:JSONEncode(Whitelist))
end
local function SaveBlacklist()
	writefile("BlacklistedPpl.json", HttpService:JSONEncode(Blacklist))
end

local Events = newproxy(true)
local Toggles = newproxy(true)

do
	local EventsTb = {}
	
	local TogglesTb = {
		["god"] = {
			["Value"] = false,
			["Connection"] = nil
		},
		["god2"] = {
			["Value"] = false,
			["Connection"] = nil
		},
		["hide"] = {
			["Value"] = false,
			["Connection"] = nil
		},
		["aimbot"] = true,
		["hookchat"] = false,
		["fly"] = false,
		["AutoRefill"] = false,
		["autorespawn"] = true,
		["esp"] = true,
		["2DEsp"] = false,
		["AutoAim"] = true,
		["AntiFeClaim"] = false,
		["Range"] = 60
	}


	getmetatable(Toggles).__index = TogglesTb
	getmetatable(Events).__index = EventsTb

	getmetatable(Events).__newindex = function(_, index, value)
		if typeof(value) ~= "function" then
			return error("Events; Expected Function got "..typeof(value).."   "..debug.traceback())
		end
		return rawset(EventsTb, index, function(...)
			return coroutine.wrap(function(...)
				return value(...)
			end)(...)
		end)
	end

	getmetatable(Toggles).__newindex = function(self, index, value)
		if Events[index] then Events[index](self, index, value) end
		return rawset(TogglesTb, index, value)
	end
end

--// Esp settings
local _2DBoxEsp = true
local _3DBoxEsp = false

local Names = true
local Rainbow = false

--// Esp coloring settings
local PlayersColor = Color3.new(0,0.7,0.3)
local WhitelistedColor = Color3.new(0,0.5,1)
local Pvp_PlayersColor = Color3.new(0.9,0,0.3)
local Pvp_WhitelistedColor = Color3.new(0,1,1);


--// Esp
(coroutine.wrap(function()

	local CharactersEsp = {}
	local Checked = {}

	local Magic = {
		{0,1,0}, {1,1,0}, {0,0,0},
		{1,0,0}, {0,1,1}, {1,1,1},
		{0,0,1}, {1,0,1}
	}

	--// Index represents the base point
	--// and the value represents all connected dots to {index} point
	local Magic2 = {
		[1] = {2,3,5}, [4] = {2,3,8},
		[6] = {5,8,2}, [7] = {5,8,3}
	}

	--For 2D square
	local Magic3 = {
		[1] = {2,3},
		[4] = {2,3}
	}
	
	--3D box
	local function Calculate(Character, IgnoreList)
		IgnoreList = (typeof(IgnoreList) == "table" and IgnoreList) or {}

		local BaseCFrame = Character:FindFirstChild("HumanoidRootPart").CFrame

		local AlignedVectors = {}

		for i,v in pairs(Character:GetChildren()) do
			if not v:IsA("BasePart") then continue end
			if table.find(IgnoreList, v.Name) then continue end

			local PartSize = v.Size
			local PartCFrame =  v.CFrame

			for i,v in pairs(Magic) do
				local SizeX = (((v[1] == 0) and -1) or 1) * PartSize.X
				local SizeY = (((v[2] == 0) and -1) or 1) * PartSize.Y
				local SizeZ = (((v[3] == 0) and -1) or 1) * PartSize.Z

				local CurrentPos = (PartCFrame + Vector3.new(SizeX,SizeY,SizeZ)/2)

				local Aligned = AlignedVectors[i]

				if not Aligned then
					AlignedVectors[i] = CurrentPos
				else
					local X = (((v[1] == 1) and math.max) or math.min)(Aligned.X, CurrentPos.X)
					local Y = (((v[2] == 1) and math.max) or math.min)(Aligned.Y, CurrentPos.Y)
					local Z = (((v[3] == 1) and math.max) or math.min)(Aligned.Z, CurrentPos.Z)

					AlignedVectors[i] = Vector3.new(X,Y,Z)
				end

			end
		end
		return AlignedVectors
	end
	
	--2D Square
	local function Calculate2(Character, IgnoreList)
		if Character:FindFirstChild("RainPart") then
			Character.RainPart:Destroy()
		end

		local ModelSize = Character:GetExtentsSize()
		local BaseCFrame = Character:FindFirstChild("HumanoidRootPart").CFrame - Vector3.new(0,.3,0)

		local Angles = {
			BaseCFrame * (Vector3.new(-ModelSize.X,ModelSize.Y,0)/2),
			BaseCFrame * (Vector3.new(ModelSize.X,ModelSize.Y,0)/2),
			BaseCFrame * (Vector3.new(-ModelSize.X,-ModelSize.Y,0)/2),
			BaseCFrame * (Vector3.new(ModelSize.X,-ModelSize.Y,0)/2)
		}

		return Angles
	end
	

	local RGBIndex = 0

	while task.wait() do
		RGBIndex += 1

		local LinesColor =  Color3.fromHSV(math.acos(math.cos(RGBIndex/1000 * (math.pi/2)))/(math.pi), 1, 1)

		local Mouse = LocalPlayer:GetMouse()
		local MousePosition = Vector2.new(Mouse.X, Mouse.Y)

		for i,v in pairs(Checked) do
			Checked[i] = false
		end

		for _,Plr in pairs(Players:GetPlayers()) do
			if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") and Plr.Character:FindFirstChild("Humanoid") and Plr.Character:FindFirstChild("Humanoid").Health > 0 then
				if not Plr:FindFirstChild("pvp") then continue end
				if not _2DBoxEsp and not _3DBoxEsp then continue end

				local IsWhitelisted = (table.find(Whitelist, Plr.Name) or Plr == LocalPlayer and true)
				local PvpIsOn = Plr.pvp.Value

				local EspColor = ((Rainbow and LinesColor) or (PvpIsOn and 
					(IsWhitelisted and Pvp_WhitelistedColor or Pvp_PlayersColor))
					or (IsWhitelisted and WhitelistedColor) or PlayersColor
				)

				Checked[Plr.Character] = true

				if not CharactersEsp[Plr.Character] then
					CharactersEsp[Plr.Character] = {}
				end

				local Positions = (_3DBoxEsp and Calculate(Plr.Character, {"RainPart"})) or Calculate2(Plr.Character) 

				for i = 1, (_2DBoxEsp and 4) or 12 do
					if not CharactersEsp[Plr.Character][i] then
						CharactersEsp[Plr.Character][i] = Drawing.new("Line")
					end
				end

				local LineIndex = 1

				for Index, Table in pairs((_2DBoxEsp and Magic3) or Magic2) do
					local From, FromIsVisible = workspace.CurrentCamera:WorldToScreenPoint(Positions[Index])
					From = Vector2.new(From.X, From.Y)

					for Index2, Value in pairs(Table) do
						local Line = CharactersEsp[Plr.Character][LineIndex]

						local To, ToIsVisible = workspace.CurrentCamera:WorldToScreenPoint(Positions[Value])
						To = Vector2.new(To.X, To.Y)

						Line.Transparency = 1
						Line.From = From + Vector2.new(0, 38)
						Line.To = To + Vector2.new(0, 38)
						Line.Visible = (FromIsVisible or ToIsVisible) or false
						Line.Color = EspColor
						Line.Thickness = 3

						LineIndex = LineIndex + 1
					end
				end

				if Plr.Character:FindFirstChild("Head") then
					if not CharactersEsp[Plr.Character]["Name"] then
						CharactersEsp[Plr.Character]["Name"] = Drawing.new("Text")
					end

					local _2DHeadPosition, IsHeadVisible = workspace.CurrentCamera:WorldToScreenPoint(Plr.Character.Head.Position)
					_2DHeadPosition = Vector2.new(_2DHeadPosition.X,_2DHeadPosition.Y + 16)

					local NameText = CharactersEsp[Plr.Character]["Name"]
					NameText.Visible = (Names and IsHeadVisible) or false
					NameText.Text = Plr.Name
					NameText.OutlineColor = Color3.new(0,0,0)
					NameText.Outline = true
					NameText.Size = 14
					NameText.Center = true
					NameText.Font = 3
					NameText.Color = EspColor
					NameText.Position = _2DHeadPosition
				end
			end
		end

		for i,v in pairs(CharactersEsp) do
			if not Checked[i] then
				for i,v in pairs(v) do
					v:Remove()
				end
				CharactersEsp[i] = nil
			end
		end
	end
end))()


local WeaponList = {
	["Glock 17"] = {
		Ammo = 17,
		Damage = 13.5,
		ReloadingTime = 1.7
	},
	["Revolver"] = {
		Ammo = 6,
		Damage = 52.5,
		ReloadingTime = 1.7
	},
	["Shaggy's Shotgun"] = {
		Ammo = 40,
		Damage = 37.5,
		ReloadingTime = 0.4
	}
}

local WeaponBuyList = {
	["grenade"] = Vector3.new(-28, 4, -20),
	["Shaggy's Shotgun"] = Vector3.new(-26, 7, -27),
	["Glock 17"] = Vector3.new(-29, 5, -27),
	["Revolver"] = Vector3.new(-24, 5, -27),
	["rocket launcher"] = Vector3.new(-19, 6, -27)
}

local function FindTb(tb, value) 
	for i,v in pairs(tb) do 
		if v == value then 
			return i,v 
		end
	end
end

Workspace:WaitForChild("danweaponry"):WaitForChild("GunStorage"):WaitForChild("buy", 999)
wait(.1)

for i,v in pairs(Workspace.danweaponry.GunStorage:GetChildren()) do
	if v.Name == "buy" then
		local Vector = Vector3.new(math.floor(v.Position.X), math.floor(v.Position.Y), math.floor(v.Position.Z))
		local Value = FindTb(WeaponBuyList, Vector)
		print(Value)
		WeaponBuyList[Value] = v
	end
end

WeaponBuyList["Flamethrower"] = Workspace:WaitForChild("sewer", 999):WaitForChild("undergroundShop"):WaitForChild("clicktobuy")

local FoodTb = {
	"hamburger", "cheeseburger", "cheemsburger", "Fatburger",
	"booger", "milk", "orange juice", "Bonk! Atomic punch!"
}

local function BuyTool(Name)
	if not table.find(FoodTb, Name) then
		warn(Name)
		local Inst = WeaponBuyList[Name]
		if not Inst then return warn("Not found") end
		fireclickdetector(Inst.ClickDetector, 0)
		fireclickdetector(Inst.ClickDetector, 1)
	else
		ReplicatedStorage.mcdonald:FireServer(table.find(FoodTb, Name))	
	end
	local Tool;
	local Connection; Connection = LocalPlayer.Backpack.ChildAdded:Connect(function(obj)
		if obj.Name == Name then
			Tool = obj
		end
	end)
	repeat task.wait() until Tool

	Connection:Disconnect()
	return Tool
end

--Autorefill
do
	local Connections = {}

	local function LocalCharacterAdded(Character)
		Character.ChildAdded:Connect(function(obj)
			if obj:IsA("Tool") and obj.Name == "grenade" and not table.find(Connections, obj) then
				table.insert(Connections, obj)
				obj.Activated:Connect(function()
					if Toggles["AutoRefill"] then
						obj:GetPropertyChangedSignal("Parent"):Wait()
						local Tool = BuyTool("grenade")
						Tool.Parent = LocalPlayer.Character
					end
				end)
			end
		end)
	end

	LocalPlayer.CharacterAdded:Connect(LocalCharacterAdded)

	if LocalPlayer.Character then
		LocalCharacterAdded(LocalPlayer.Character)
	end	
end

local AmmoLeft;
local Reload;
local ServerIsDown = false

task.spawn(function()
	local Debounce = 0
	local IsReloading = false

	Reload = function(Weapon)
		if tick() - Debounce >= .2 then
			if ServerIsDown then repeat task.wait() until not ServerIsDown end

			Debounce = tick()

			local LastAmmo = Weapon.ammo.Value
			if LastAmmo == WeaponList[Weapon.Name]["Ammo"] then return end
			IsReloading = true
			Weapon.Parent = LocalPlayer.Backpack
			fireclickdetector(Workspace.danweaponry["Meshes/aaPile"].ClickDetector, 0)
			fireclickdetector(Workspace.danweaponry["Meshes/aaPile"].ClickDetector, 1)
			Weapon.ammo:GetPropertyChangedSignal("Value"):Wait()
			IsReloading = false
			Weapon.Parent = LocalPlayer.Character
		end
	end

	--Leaderboard stats
	do
		task.spawn(function()
			local NewTb = {};
			(coroutine.wrap(function()

				xpcall(function()
					NewTb = HttpService:JSONDecode(readfile("PlayerStats.json"))
					while task.wait(.3) do
						local Tb = HttpService:JSONDecode(readfile("PlayerStats.json"))
						for i,v in pairs(NewTb) do
							Tb[i] = v
						end
						writefile("PlayerStats.json", HttpService:JSONEncode(Tb))
					end
				end, function(...)
					return rconsoleprint(({...})[1].."\n\n\n"..debug.traceback())
				end)
			end))();
			local function NewPlayerAdded(Plr)
				local Stats = Plr:WaitForChild("Stats")

				local LeaderboardStats = {
					Stats:WaitForChild("Kills"),
					Stats:WaitForChild("Deaths"),
					Stats:WaitForChild("MaxKillstreak"),
					Stats:WaitForChild("Money"),
				}

				local NewFolder = Instance.new("Folder")
				NewFolder.Name = "leaderstats"
				NewFolder.Parent = Plr

				for Index,Stat in pairs(LeaderboardStats) do
					if not NewTb[Plr.Name] then NewTb[Plr.Name] = {} end
					NewTb[Plr.Name][Stat.Name] = Stat.Value
					local StatInstance = Stat
					local Cloned = StatInstance:Clone()
					Cloned.Parent = NewFolder
					Cloned.Name = Stat.Name

					local Connection; Connection = StatInstance:GetPropertyChangedSignal("Value"):Connect(function()
						NewTb[Plr.Name][Stat.Name] = Stat.Value
						Cloned.Value = StatInstance.Value
					end)
				end

			end


			Players.PlayerAdded:Connect(NewPlayerAdded)

			for i,v in pairs(Players:GetPlayers()) do
				task.spawn(NewPlayerAdded, v)
			end

		end)
	end

	--Players nicknames
	do
		StarterPlayer.NameDisplayDistance = 9999

		local function NewCharacter(Character)
			wait(.2)
			local Humanoid = Character:WaitForChild("Humanoid")
			Humanoid.NameDisplayDistance = 9999
			Humanoid.DisplayName = Character.Name
		end

		local function NewPlayer(Player)
			if Player.Character then
				NewCharacter(Player.Character)    
			end
			Player.CharacterAdded:Connect(NewCharacter)
		end

		local function NewCorpseAdded(Object)
			if Object.Name == "Corpse" then
				local Humanoid = Object:WaitForChild("Humanoid")
				Humanoid.DisplayName = ""
			end
		end

		Workspace.ChildAdded:Connect(NewCorpseAdded)
		Players.PlayerAdded:Connect(NewPlayer)

		for i,v in pairs(Players:GetPlayers()) do
			task.spawn(NewPlayer,v)    
		end

		for i,v in pairs(Workspace:GetChildren()) do
			task.spawn(NewCorpseAdded,v)    
		end
	end

	--Fly
	do
		local RenderConnection;
		local BodyVelocity;

		Events["fly"] = function(self, index, value)
			if value == true then
				BodyVelocity = Instance.new("BodyVelocity")
				BodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
				BodyVelocity.Velocity = Vector3.new()

				local NewVector = Vector3.new()
				local OldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

				RenderConnection = RunService.RenderStepped:Connect(function()
					local Character = LocalPlayer.Character
					local HumanoidRootPart = Character.HumanoidRootPart

					local PressedKeys = UserInputService:GetKeysPressed()

					for i,Input in pairs(PressedKeys) do
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							if Input.KeyCode == Enum.KeyCode.W  then
								NewVector = NewVector + Vector3.new(0, 0, -1)
							elseif Input.KeyCode == Enum.KeyCode.S then
								NewVector = NewVector + Vector3.new(0, 0, 1)
							elseif Input.KeyCode == Enum.KeyCode.A then
								NewVector = NewVector + Vector3.new(-1, 0, 0)
							elseif Input.KeyCode == Enum.KeyCode.D then
								NewVector = NewVector + Vector3.new(1, 0, 0)
							end
						end
					end

					Character.Humanoid.PlatformStand = true

					local LookVector = Workspace.CurrentCamera.CFrame.LookVector
					HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + (Workspace.CurrentCamera.CFrame.Rotation * NewVector)
					HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, Workspace.CurrentCamera.CFrame * Vector3.new(0, 0, -9e9))
					NewVector = Vector3.new()
				end)
				for i = 1,10 do
					for i,v in pairs(LocalPlayer.Character:GetChildren()) do
						if not v:IsA("BasePart") then continue end

						v.RotVelocity = Vector3.new()
						v.Velocity = Vector3.new()
					end
					task.wait()
				end
			else
				if RenderConnection then
					RenderConnection:Disconnect()
				end
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and BodyVelocity then
					LocalPlayer.Character.Humanoid.PlatformStand = false
					BodyVelocity:Destroy()
				end
			end
		end

		game:GetService("ContextActionService"):BindAction("CamFly", function(Name, State, Object)
			if State ~= Enum.UserInputState.Begin then return end

			if UserInputService:IsKeyDown(Enum.KeyCode.F) then
				LocalPlayer.Character.HumanoidRootPart.Anchored = false
			else
				LocalPlayer.Character.HumanoidRootPart.Anchored = not Toggles["fly"]
			end

			Toggles["fly"] = not Toggles["fly"]
		end, false, Enum.KeyCode.C, Enum.KeyCode.F)
	end

	--Exploiter protection
	do
		do --Anti fe claim
			local DangerousTools = {}

			local function CharacterAdded(Character, Plr)
				if not Plr then Plr = Players:FindFirstChild(Character.Name) end
				if Plr == LocalPlayer then
					local RightArm = Character:WaitForChild("Right Arm")
					local Connection1; Connection1 = RightArm.ChildAdded:Connect(function(obj)
						local OldPlrPos = Character.HumanoidRootPart.CFrame
						if obj.Name == "RightGrip" and obj.Part1 and obj.Part1.Parent and obj.Part1.Parent:IsA("Tool") then
							local NewTool = obj.Part1.Parent
							if DangerousTools[NewTool] then
								if Toggles["AntiFeClaim"] == false then return end
								obj.Part1:Destroy()
								obj.Part0 = nil
								obj.Part1 = nil
								task.spawn(function()
									for i = 1,10  do
										LocalPlayer.Character.HumanoidRootPart.CFrame = OldPlrPos + Vector3.new(0, 1, 0)
										task.wait()
									end
								end)
								task.wait()
								obj:Destroy()
							end
						end
					end)
					local Connection2; Connection2 = Character:GetPropertyChangedSignal("Parent"):Connect(function()
						Connection1:Disconnect()
						Connection2:Disconnect()
					end)
				else
					local Connection; Connection = Character.ChildRemoved:Connect(function(obj)
						if obj.Name == "Humanoid" then
							for i,v in pairs(Character:GetChildren()) do
								if v:IsA("Tool") then
									DangerousTools[v] = Plr
								end
							end
							for i,v in pairs(Plr.Backpack:GetChildren()) do
								if v:IsA("Tool") then
									DangerousTools[v] = Plr
								end
							end
						end	
					end)

					local Connection2; Connection2 = Character:GetPropertyChangedSignal("Parent"):Connect(function()
						Connection:Disconnect()
						Connection2:Disconnect()
					end)
				end

			end

			local function PlayerAdded(Player)
				if Player.Character then
					CharacterAdded(Player.Character, Player)
				end

				Player.CharacterAdded:Connect(CharacterAdded)
			end

			for i,v in pairs(Players:GetPlayers()) do
				PlayerAdded(v)   
			end

			Players.PlayerAdded:Connect(PlayerAdded)
		end
	end

	--Animation skipper
	do
		local BlacklistedAnimations = {
			["rbxassetid://6363853424"] = "reload1",
			["rbxassetid://6363813017"] = "reload2",
			["rbxassetid://6363837728"] = "reload3",
			["rbxassetid://6423737928"] = "reload4",
			["rbxassetid://5267014967"] = "Bonk sniper juice",
			["rbxassetid://5264760260"] = "Fatburger",
			["rbxassetid://6363789118"] = "shot",
		}


		local function CharacterAdded(Character)
			local Humanoid = Character:WaitForChild("Humanoid")
			Humanoid.AnimationPlayed:Connect(function(Anim)
				local Animation = Anim.Animation
				if BlacklistedAnimations[Animation.AnimationId] then
					Anim:AdjustSpeed(1300)
				end
			end)
		end

		LocalPlayer.CharacterAdded:Connect(CharacterAdded)

		if LocalPlayer.Character then
			CharacterAdded(LocalPlayer.Character)
		end
	end

	--Leaderboard extra buttons
	do
		local CurrentSpectating = nil

		local function Spectate(Plr)
			CurrentSpectating = Plr
			local Connection; Connection = Plr.CharacterAdded:Connect(function(Char)
				if CurrentSpectating ~= Plr then
					Connection:Disconnect()
					return
				else
					local Humanoid = Char:WaitForChild("Humanoid")
					Workspace.CurrentCamera.CameraSubject = Humanoid
				end
			end)
			if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
				Workspace.CurrentCamera.CameraSubject = Plr.Character.Humanoid
			end
		end

		local function PlayerDropDownAdded(PlayerDropDown)
			PlayerDropDown:WaitForChild("InnerFrame")
			PlayerDropDown.InnerFrame:WaitForChild("BlockButton")

			local SpectateButton = PlayerDropDown.InnerFrame.BlockButton:Clone()
			SpectateButton.Name = "SpectateButton"
			SpectateButton.HoverBackground.Text.Text = "Spectate"
			SpectateButton.HoverBackground.Icon.Image = ""
			SpectateButton.HoverBackground.Icon.ImageRectOffset = Vector2.new(380, 340)
			SpectateButton.HoverBackground.Icon.ImageRectSize = Vector2.new(36, 36)
			SpectateButton.Parent = PlayerDropDown.InnerFrame

			local Connection1; Connection1 = SpectateButton.MouseEnter:Connect(function()
				SpectateButton.HoverBackground.BackgroundTransparency = 0.9
			end)
			local Connection2; Connection2 = SpectateButton.MouseLeave:Connect(function()
				SpectateButton.HoverBackground.BackgroundTransparency = 1
			end)

			local Connection3; Connection3 = SpectateButton.MouseButton1Down:Connect(function()
				local CurrentPlr = PlayerDropDown.InnerFrame.PlayerHeader.Background.TextContainerFrame.PlayerName.Text
				CurrentPlr = game.Players:FindFirstChild(CurrentPlr:sub(2, #CurrentPlr))
				Spectate(CurrentPlr)
			end)
			local OldParent = PlayerDropDown.Parent

			local Sizo = PlayerDropDown.Size + UDim2.new(0, 304, 0, PlayerDropDown.Size.Y.Offset + (304/4))

			repeat task.wait()
				if Sizo ~= PlayerDropDown.Size then
					PlayerDropDown.Size = UDim2.new(0, 304, 0, PlayerDropDown.Size.Y.Offset + (304/4))
					Sizo = UDim2.new(0, 304, 0, PlayerDropDown.Size.Y.Offset + (304/4))
				end
			until PlayerDropDown.Parent ~= OldParent

			Connection1:Disconnect(); Connection2:Disconnect(); Connection3:Disconnect()	
		end

		local UserIds = {}
		for i,v in pairs(game.Players:GetPlayers()) do
			UserIds[v.UserId] = v.Name
		end
		game.Players.PlayerAdded:Connect(function(Plr)
			UserIds[Plr.UserId] = Plr.Name
		end)

		local function ScrollingFrameClippingFrameAdded(ScrollingFrameClippingFrame)
			local ScollingFrame = ScrollingFrameClippingFrame:WaitForChild("ScollingFrame")
			local OffsetUndoFrame = ScollingFrame:WaitForChild("OffsetUndoFrame")
			local function NewPlrAdded(Frame)
				local UserId = string.match(Frame.Name, "p_(%d+)")
				local PlayerName = Frame:WaitForChild("ChildrenFrame").NameFrame.BGFrame.OverlayFrame.PlayerName.PlayerName
				PlayerName.Text = UserIds[tonumber(UserId)]
			end
			for i,v in pairs(OffsetUndoFrame:GetChildren()) do
				task.spawn(NewPlrAdded, v)
			end
			OffsetUndoFrame.ChildAdded:Connect(NewPlrAdded)
		end

		if CoreGui.PlayerList.PlayerListMaster.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer:FindFirstChild("PlayerDropDown") then
			PlayerDropDownAdded(CoreGui.PlayerList.PlayerListMaster.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.PlayerDropDown)    
		end
		if CoreGui.PlayerList.PlayerListMaster.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer:FindFirstChild("ScrollingFrameClippingFrame") then
			ScrollingFrameClippingFrameAdded(CoreGui.PlayerList.PlayerListMaster.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ScrollingFrameClippingFrame)
		end

		CoreGui.PlayerList.PlayerListMaster.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ChildAdded:Connect(function(obj)
			if obj.Name == "PlayerDropDown" then
				PlayerDropDownAdded(obj)    
			elseif obj.Name == "ScrollingFrameClippingFrame" then
				ScrollingFrameClippingFrameAdded(obj)
			end
		end)
	end

	--// I was forced to add this because stupid dev
	--// Added useless feature to kick anybody whoever
	--// Uses negative value of ammo

	task.spawn(function()
		local Combo = -1
		local Last = -1

		while wait(.1) do
			local DataRecieveKbps = Stats.DataReceiveKbps

			if DataRecieveKbps ~= Last then
				Combo = (Combo <= 0 and Combo - 1) or -1
			else
				Combo = (Combo <= 0 and 1) or Combo + 1
			end
			Last = DataRecieveKbps
			if Combo >= 13 then
				print("The server is down!")
				ServerIsDown = true
			elseif Combo <= -13 then
				ServerIsDown = false
			end
		end
	end)

	local Dead = {}

	local function Shoot(Weapon,Character)
		if Weapon.ammo.value <= 0 then Reload(Weapon) end
		if ServerIsDown then repeat task.wait() until not ServerIsDown end

		ServerHitReg:FireServer(Vector3.new(), Vector3.new())

		local Arguments = {
			LocalPlayer.Character.Head.Position - Vector3.new(0,100000,0),
			Character.Head.Position,

			--//* A small trick used to fool the remote event handling script
			--//* To make it think we give it an actual instance
			{
				Position = LocalPlayer.Character.HumanoidRootPart.Position+Vector3.new(0,1,0),
				Parent = Character,
				Name = "Head"
			},

			Character.Head.Position,
			Enum.Material.Plastic,
			Vector3.new(),
			true,
			1, --Ammo value
			LocalPlayer.Character.HumanoidRootPart.CFrame
		}

		ShootEvent:FireServer(table.unpack(Arguments))
		return true
	end

	--Aimbot
	task.spawn(function()
		while task.wait() do
			if Toggles["aimbot"] and not ServerIsDown then
				if LocalPlayer.Character then
					local Range = Toggles["Range"]
					local Gun, Statistics;
					for i,v in pairs(LocalPlayer.Character:GetChildren()) do
						if WeaponList[v.Name] then
							Gun, Statistics = v, WeaponList[v.Name]
						end
					end

					if Gun then
						xpcall(function()
							for i,v in pairs(Players:GetPlayers()) do
								if v == LocalPlayer or table.find(Whitelist, v.Name) or 
									not v:FindFirstChild("pvp") or Gun.ammo.Value <= 0 or 
									LocalPlayer.pvp.Value == false or v.pvp.Value == false 
								then continue end
								if not v.Character:FindFirstChild("Head") then continue end

								if v.Character and not v.Character:FindFirstChild("ForceField") then
									if (v.Character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude <= Range then
										if v.Character:FindFirstChild("Humanoid") and (v.Character.Humanoid.Health > 0 and v.Character.Humanoid.Health < 9999) and (not Dead[v.Character] or tick() - Dead[v.Character] >= 1) then
											if not v.Character:FindFirstChild("snowchecker") then continue end
											Dead[v.Character] = tick()

											for i = 1, math.ceil(v.Character.Humanoid.Health/Statistics["Damage"]) do
												if v.Character:FindFirstChild("Head") then
													Shoot(Gun, v.Character)
												end
											end
										end
									end
								end
							end
						end, function(...)
							warn("Aimbot error", debug.traceback(), "\n"..(...))
						end)	
					end
				end
			end

			local Total = 0
			for i,v in pairs(Dead) do
				if i.Parent ~= Workspace then
					Dead[i] = nil
					Total = Total + 1
				end
			end
		end
	end)

	--Autoreload
	task.spawn(function()
		while task.wait() do
			if LocalPlayer.Character and not IsReloading then
				local Character = LocalPlayer.Character
				local Weapon = (_FindFirstChild(Character, "Glock 17") or _FindFirstChild(Character, "Revolver") or _FindFirstChild(Character, "Shaggy's Shotgun"));
				if not Weapon then continue end

				local Ammo, ReserveAmmo = Weapon.ammo.Value, Weapon.reserveAmmo.Value
				local Statistics = WeaponList[Weapon.Name]

				if Ammo <= 1 and ReserveAmmo >= 1 then
					IsReloading = true
					local A_1 = ReserveAmmo
					local A_2 = true
					local Event = Weapon.reloadScript.reloadEvent
					Event:FireServer(A_1, A_2)
					IsReloading = false
				elseif Ammo <= 1 and ReserveAmmo <= 1 then
					Reload(Weapon)
				end
			end
		end
	end)

	local Mouse = LocalPlayer:GetMouse()

	--Infinity jump
	UserInputService.JumpRequest:Connect(function()
		LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
	
	--Disable collisions with part on Z
	local CanCollide = {}
	Mouse.Button1Down:Connect(function()
		if UserInputService:IsKeyDown(Enum.KeyCode.Z) then
			local Target = Mouse.Target
			Target.Transparency =  ((CanCollide[Target] and -.4) or .4)
			Target.CanCollide = (CanCollide[Target] and true) or false
			CanCollide[Target] = (CanCollide[Target] == nil and false) or not CanCollide[Target]
		end
	end)

	do --Autorespawn
		task.spawn(function()
			--Destroy useless stuff
			local _	=	(LocalPlayer.PlayerGui:FindFirstChild("deathgui") and LocalPlayer.PlayerGui:FindFirstChild("deathgui"):Destroy())
			_ 		= 	(StarterGui:FindFirstChild("deathgui") and StarterGui:FindFirstChild("deathgui"):Destroy())
			_		=   (LocalPlayer.PlayerScripts:FindFirstChild("screenShaker") and LocalPlayer.PlayerScripts:FindFirstChild("screenShaker"):Destroy())
			_		=	(StarterPlayer.StarterPlayerScripts:FindFirstChild("screenShaker") and StarterPlayer.StarterPlayerScripts:FindFirstChild("screenShaker"):Destroy())

			local function NewChar(Char)
				Char:WaitForChild("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead, false)

				local Connection; Connection = Char.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
					if Char.Humanoid.Health > 0 then return end

					if Toggles["autorespawn"] then
						local CurrentPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

						LocalPlayer.Character:ClearAllChildren()

						local Event = ReplicatedStorage.Respawn
						Event:FireServer()
						LocalPlayer.CharacterAdded:Wait()
						LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = CurrentPosition


					end
					Connection:Disconnect()
				end)
			end

			if LocalPlayer.Character then
				NewChar(LocalPlayer.Character)
			end
			LocalPlayer.CharacterAdded:Connect(NewChar)
		end)
	end
	
	--Check chat filter
	task.spawn(function()

		local ChatGUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Chat")
		local MessageToSend = ChatGUI.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar

		local debounce = 0

		while task.wait() do
			if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.F1) then
				if (tick()-debounce) >= 0.2 then
					print(MessageToSend.Text)
					debounce = tick()
					pcall(function()
						local FilteredString = Chat:FilterStringForBroadcast(MessageToSend.Text, game:GetService("Players").LocalPlayer)
						game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
							["Text"] = FilteredString,
							["Color"] = Color3.new(0,0.9,0.3)
						})
					end)
				end
			end
		end
	end)
end)

local CommandList;
local Aliases = {}

CommandList = setmetatable({},{})

local function ErrorFunction(Command, ...)
	warn(Command, ..., debug.traceback())
end

local function RegisterCommand(Command,Function,CommandAliases)
	assert(typeof(Command) == "string", "RegisterCommand error, typeof(Command) == \"\"string\" expected")
	assert(typeof(Function) == "function", "RegisterCommand error, typeof(Function) == \"function\" expected")

	Command = Command:lower()
	CommandList[Command] = function(...)
		local Result,Return = xpcall(Function, function(...) ErrorFunction(Command, ...) end, ...)
		return Return
	end

	if typeof(CommandAliases) == "table" then
		for i,v in pairs(CommandAliases) do
			if typeof(v) ~= "string" then continue end
			Aliases[v:lower()] = Command
		end	
	end
end

local function FindPlayer(Str)
	if typeof(Str) ~= "string" then return end

	Str = Str:lower()

	if Str == "all" then
		return Players:GetPlayers()
	elseif Str == "others" then
		local Players = Players:GetPlayers()

		return {select(-(#Players - 1),table.unpack(Players))}
	elseif Str == "me" then
		return {Players.LocalPlayer}
	else
		local TempTb = {}
		for i,v in pairs(Players:GetPlayers()) do
			if v.Name:sub(1, #Str):lower() == Str then
				table.insert(TempTb, v)
			end
		end

		return TempTb
	end
end

--// The second prefix just in case if user wants to
--// use silently commands

local Prefix = "/"
local SafePrefix = ":" 

LocalPlayer.Chatted:Connect(function(msg)
	local PrefixLen = (((msg:sub(1, #Prefix) == Prefix) and #Prefix) or ((msg:sub(1, #SafePrefix) == SafePrefix) and #SafePrefix)) or nil
	if not PrefixLen then return end

	local split = string.split(msg, " ")
	local FormatedMessage = split[1]:lower():sub(PrefixLen + 1, #split[1])
	local CommandFunction = CommandList[FormatedMessage]

	if CommandFunction then
		CommandFunction(select(2,table.unpack(split)))
	elseif not CommandFunction and Aliases[FormatedMessage] then
		CommandList[Aliases[FormatedMessage]](select(2, table.unpack(split)))
	end
end)

do
	local DefaultChatSystemChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
	local SayMessageRequest = DefaultChatSystemChatEvents:WaitForChild("SayMessageRequest")

	local TypeBackpack = Enum.CoreGuiType.Backpack

	local Namecall; Namecall = hookmetamethod(game, "__namecall", function(self, ...)
		local namecallmethod = getnamecallmethod()

		--Chat event hook
		if self == SayMessageRequest  and namecallmethod == "FireServer" then
			local Message = ({...})[1]
			if typeof(Message) ~= "string" then return Namecall(self, ...) end


			if Message:sub(1, #SafePrefix) == SafePrefix then return end

			if Toggles["hookchat"] then
				local FormatedMessage = (Message:split(" ")[1]):sub(#Prefix + 1, #Message):lower()

				if Message:sub(1, #Prefix) == Prefix and CommandList[FormatedMessage] then
					return
				elseif Aliases[FormatedMessage] then
					return	
				end
			end
			--Prevents backpack from hiding
		elseif self == StarterGui and not checkcaller() then
			local args = {...}

			if args[1] == TypeBackpack then
				return Namecall(self, TypeBackpack, true)    
			end
			--Anti cheat bypass
		elseif namecallmethod == "FireServer" and self.Name == "banMePls" then
			return
		end


		return Namecall(self, ...)
	end)

end

local function FeClaim(PlayerInstance, Tool, TP_Pos1, TP_Pos2, Reset, WaitTime, TP_Tries)
	if not PlayerInstance.Character:FindFirstChild("Humanoid") then return end
	if PlayerInstance.Character.Humanoid.Health <= 0 or PlayerInstance.Character.Humanoid.Sit then return end

	if not Tool then
		Tool = (LocalPlayer.Backpack:FindFirstChild("Fists") or LocalPlayer.Character:FindFirstChild("Fists"))
	end
	if not Tool then return error "No tool!" end
	Tool.Parent = LocalPlayer.Character
	local OldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

	LocalPlayer.Character.HumanoidRootPart.CFrame = TP_Pos1 or LocalPlayer.Character.HumanoidRootPart.CFrame
	task.wait(WaitTime or .1)

	local Humanoid = LocalPlayer.Character.Humanoid
	local FakeHumanoid = Humanoid:Clone()
	FakeHumanoid.Parent = LocalPlayer.Character
	Humanoid:Destroy()
	Tool.Parent = LocalPlayer.Character
	Tool.Parent = LocalPlayer.Backpack
	Tool.Parent = LocalPlayer.Character
	local Tries = 0

	repeat task.wait()
		Tries = Tries + 1
		LocalPlayer.Character.HumanoidRootPart.CFrame = TP_Pos1 or LocalPlayer.Character.HumanoidRootPart.CFrame
		firetouchinterest(PlayerInstance.Character.HumanoidRootPart, Tool.Handle, 1)
		firetouchinterest(PlayerInstance.Character.HumanoidRootPart, Tool.Handle, 0)
	until (Tool.Parent == PlayerInstance.Character or Tool.Parent == PlayerInstance.Backpack or Tries >= 130)

	if TP_Pos2 then
		for i = 1,TP_Tries do
			LocalPlayer.Character.HumanoidRootPart.CFrame = TP_Pos2
			task.wait()
		end
	end

	if Reset then
		LocalPlayer.Character:ClearAllChildren()
		task.wait()
		RespawnEvent:FireServer()

		LocalPlayer.CharacterAdded:Wait()
		LocalPlayer.Character:WaitForChild("Head") 
		LocalPlayer.Character:WaitForChild("Humanoid")
	else
		Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Head
	end

	return OldPosition
end

do
	RegisterCommand("crash", function(Power)
		for i = 1,(tonumber(Power) or 222) do
			RespawnEvent:FireServer()
		end
	end)
	
	RegisterCommand("hookchat", function()
		Toggles["hookchat"] = not Toggles["hookchat"]
	end)
	
	RegisterCommand("crash2", function(Power)
		Power = tonumber(Power) or 35000

		LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame - Vector3.new(0, 50, 0)
		task.wait(.1)
		LocalPlayer.Character.Parent = LocalPlayer
		for i2 = 1,Power do
			StartTauntEvent:FireServer(2)
		end
	end)
	
	RegisterCommand("crash3", function(Target, Power)
		Target = FindPlayer(Target)[1]
		if not Target then return end
		Power = tonumber(Power) or 100

		local Items = {}
		local Connection; Connection = LocalPlayer.Backpack.ChildAdded:Connect(function(obj)
			if obj.Name == "heart" then
				task.wait()
				obj.Parent = LocalPlayer.Character
				obj.Parent = workspace
				table.insert(Items, obj)
				if #Items >= Power then return Connection:Disconnect() end
				fireclickdetector(Workspace.House1.Inside.Fridge.heart.ClickDetector, 0)
				fireclickdetector(Workspace.House1.Inside.Fridge.heart.ClickDetector, 1)
			end
		end)

		fireclickdetector(Workspace.House1.Inside.Fridge.heart.ClickDetector, 0)
		fireclickdetector(Workspace.House1.Inside.Fridge.heart.ClickDetector, 1)

		repeat task.wait() until #Items >= Power

		for i = 1,20 do
			LocalPlayer.Character.HumanoidRootPart.CFrame = Target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
			task.wait()
		end

		local Old = LocalPlayer.Character.Humanoid
		local Cloned = Old:Clone()
		Old:Destroy()
		Cloned.Parent = LocalPlayer.Character

		for i,v in pairs(Items) do
			v.Parent = LocalPlayer.Character
			v.Parent = LocalPlayer
		end
	end)
	
	RegisterCommand("crash4", function(Power)
		Power = tonumber(Power) or 500

		local Artifact;

		for i,v in pairs(Workspace:GetChildren()) do
			if v:FindFirstChild("ClickDetector") then
				Artifact = v.ClickDetector    
			end
		end

		local Items = {
			["heart"] = Workspace.House1.Inside.Fridge.heart.ClickDetector,
			["cheese"] = Workspace.House1.Inside.Fridge.Handle.ClickDetector,
			["Artifact"] = Artifact,
			["Janitor Keycard"] = Workspace.sewer.Handle.ClickDetector
		}

		local Connection; Connection = LocalPlayer.Backpack.ChildAdded:Connect(function(obj)
			if obj.Name == "heart" or obj.Name == "cheese" or obj.Name == "Artifact" or obj.Name == "Janitor Keycard" then
				task.wait()
				obj.Parent = LocalPlayer.Character
				obj.Parent = workspace
				table.insert(Items, obj)
				rconsoleprint(tostring(#Items).."\n")
				if #Items >= Power then return Connection:Disconnect() end
				fireclickdetector(Items[obj.Name], 0)
				fireclickdetector(Items[obj.Name], 1)
			end
		end)

		for i,v in pairs(Items) do
			fireclickdetector(v, 0)
			fireclickdetector(v, 1)
		end

		repeat task.wait() until #Items >= Power

		LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 9e6, 0)
		wait(.1)
		LocalPlayer.Character.Humanoid:Destroy()


		for i,v in pairs(Items) do
			v.Parent = game.Players.LocalPlayer.Character
			v.Parent = LocalPlayer
		end
	end)
	
	RegisterCommand("blacklist", function(Player)
		local Tb = FindPlayer(Player)
		for i,v in pairs(Tb) do
			table.insert(Blacklist, v.Name)
		end
		if #Tb == 0 then
			table.insert(Blacklist, Player)
		end
		SaveBlacklist()
	end)
	
	RegisterCommand("crj", function(Power)
		for i = 1,(tonumber(Power) or 85) do
			RespawnEvent:FireServer()
		end
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
	end,{"crashrejoin", "freezemoney", "freeze_money"})
	
	RegisterCommand("re", function()
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local CurrentCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
			RespawnEvent:FireServer()
			LocalPlayer.CharacterAdded:Wait()
			LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = CurrentCFrame
		else
			RespawnEvent:FireServer()
		end	
	end)
	
	RegisterCommand("re2", function()
		LocalPlayer.Character:ClearAllChildren()
		RespawnEvent:FireServer()
	end)
	
	RegisterCommand("reload", function()
		LocalPlayer.Character.Humanoid:UnequipTools()
		wait()
		fireclickdetector(Workspace.danweaponry["Meshes/aaPile"].ClickDetector, 0)
		fireclickdetector(Workspace.danweaponry["Meshes/aaPile"].ClickDetector, 1)
	end)
	
	RegisterCommand("autorefill", function()
		Toggles["AutoRefill"] = not Toggles["AutoRefill"]
	end)
	
	RegisterCommand("god", function()
		local Pee = BuyTool("Bonk! Atomic punch!")
		local Character = LocalPlayer.Character

		if Character:FindFirstChild("ForceField") then
			Character.ForceField:Destroy()    
		end

		local OldPos = Character.HumanoidRootPart.CFrame
		local OldHp = Character.Humanoid.Health

		repeat task.wait()
			Character.HumanoidRootPart.Velocity = Vector3.new(0, -215, 0)
			Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
		until Character.Humanoid.Health ~= OldHp

		task.wait()
		Character.HumanoidRootPart.Velocity = Vector3.new()
		Character.HumanoidRootPart.CFrame = OldPos

		Pee.Parent = Character
		Pee.Handle.NANI:Destroy()
		Pee.Handle.LocalScript:Destroy()
		Pee:Activate()
		Character.falldamage:Destroy()
		Pee:Destroy()
		wait(3)
		Character.sprintV.Value = true
	end)
	
	RegisterCommand("god2", function()
		if Toggles["god"]["Value"] == false then
			local ToDestroy = {"snowchecker", "exploded", "burn"}

			local function CharAdded(Character)
				for i,v in pairs(LocalPlayer.Character:GetChildren()) do
					if table.find(ToDestroy, v.Name) then
						v:Destroy()
					end
				end

				Character.ChildAdded:Connect(function(obj)
					if table.find(ToDestroy, obj.Name) then
						wait()
						obj:Destroy()
					end
				end)
			end

			if LocalPlayer.Character then
				for i,v in pairs(LocalPlayer.Character:GetChildren()) do
					if table.find(ToDestroy, v.Name) then
						v:Destroy()
					end
				end

				CharAdded(LocalPlayer.Character)
			end

			local Connection; Connection = LocalPlayer.CharacterAdded:Connect(CharAdded)
			Toggles["god"]["Value"] = true
			Toggles["god"]["Connection"] = Connection
		else
			Toggles["god"]["Value"] = false
			Toggles["god"]["Connection"]:Disconnect()
		end
	end)
	
	RegisterCommand("god3",function()
		if not Toggles["god2"]["Value"] then
			local function CharAdded(Character)
				Character.ChildAdded:Connect(function(obj)
					if obj.Name == "bulletProofVest" then
						task.wait()
						obj.vest1.Health:Destroy()
						obj.vest1.brea:Destroy()
					end
				end)

				fireclickdetector(Workspace.danweaponry["1stFloor"].vest1.ClickDetector, 0)
				fireclickdetector(Workspace.danweaponry["1stFloor"].vest1.ClickDetector, 1)
			end

			if LocalPlayer.Character then
				for i,v in pairs(LocalPlayer.Character:GetChildren()) do
					if v.Name == "bulletProofVest" then
						v:Destroy()
					end
				end

				CharAdded(LocalPlayer.Character)
			end
			Toggles["god2"]["Connection"] = LocalPlayer.CharacterAdded:Connect(CharAdded)
			Toggles["god2"]["Value"] = true
		else
			Toggles["god2"]["Connection"]:Disconnect()
			Toggles["god2"]["Value"] = false
		end
	end)
	
	RegisterCommand("antiafk", function()
		for i,v in pairs(getconnections(LocalPlayer.Idled)) do
			v:Disable()
		end
	end)
	
	RegisterCommand("hide", function()
		if Toggles["hide"]["Value"] == false then
			local function CharAdded(Char)
				Char.DescendantAdded:Connect(function(obj)
					if obj.Name == "pvp" or obj.Name == "pvp2" then
						wait()
						obj:Destroy()
					end
				end)
			end
			if LocalPlayer.Character then
				for i,v in pairs(LocalPlayer.Character:GetDescendants()) do
					if v.Name == "pvp" or v.Name == "pvp2" then
						v:Destroy()
					end
				end

				CharAdded(LocalPlayer.Character)
			end

			local Connection; Connection = LocalPlayer.CharacterAdded:Connect(CharAdded)

			Toggles["hide"]["Connection"] = Connection
			Toggles["hide"]["Value"] = true
		else
			Toggles["hide"]["Connection"]:Disconnect()
			Toggles["hide"]["Value"] = false
		end
	end)
	
	RegisterCommand("rejoin",function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
	end, {"rj"})
	
	RegisterCommand("jobid",function()
		setclipboard(game.JobId)
	end)
	
	RegisterCommand("2desp", function()
		_2DBoxEsp = not _2DBoxEsp
		_3DBoxEsp = not _2DBoxEsp
	end)
	
	RegisterCommand("range", function(integer)
		Toggles["Range"] = (tonumber(integer) or 60)
	end)
	
	RegisterCommand("heal", function()
		local Milk = BuyTool("milk")
		Milk.Parent = LocalPlayer.Character
		Milk:Activate()
		task.wait()
		Milk:Destroy()
		LocalPlayer.Character.Humanoid.WalkSpeed = 16
	end)
	
	RegisterCommand("buy", function(ToolName, Ammount)
		assert(typeof(ToolName) == "string", "Exception in 'buy', expected string at arg[1]")
		ToolName = string.lower(ToolName)
		local Aliases = {
			["grenade"] = {"grenade"},
			["Shaggy's Shotgun"] = {"shotgun"},
			["Glock 17"] = {"glock", "pistola", "gun"},
			["Revolver"] = {"revolver"},
			["Flamethrower"] = {"flamethrower"},
			["rocket launcher"] = {"rocket_launcher", "rocketlauncher"},
			["hamburger"] = {"hamburger", "burger"},
			["cheeseburger"] = {"cheeseburger"},
			["cheemsburger"] = {"cheemsburger"},
			["Fatburger"] = {"fatburger"},
			["booger"] = {"booger"},
			["milk"] = {"milk"},
			["orange juice"] = {"orangejuice"},
			["Bonk! Atomic punch!"] = {"bonksniperstyle","bonk_sniper_style","pee"}
		}
		
		local CorrectName;

		for i,v in pairs(Aliases) do
			if table.find(v, ToolName) then
				CorrectName = i
			end
		end
		if not CorrectName then return print("Not found") end
		local Weapon = BuyTool(CorrectName)

		return Weapon
	end,{"buytool", "tool"})
	
	RegisterCommand("givegod", function(Target)
		local Players = FindPlayer(Target)

		for i, Player in pairs(Players) do
			local Pee = BuyTool("Bonk! Atomic punch!")
			Pee.Parent = LocalPlayer.Character

			Pee.Handle.NANI:Destroy()
			Pee.Handle.LocalScript:Destroy()

			local Pos = FeClaim(Player, Pee, Player.Character.HumanoidRootPart.CFrame, false, true)
			LocalPlayer.Character.HumanoidRootPart.CFrame = Pos
		end
	end)
	
	RegisterCommand("givetool", function(PlayerName,ToolName)
		local Players = FindPlayer(PlayerName)

		for i,Player in pairs(Players) do
			local Tool = CommandList["buy"](ToolName)

			local Pos = FeClaim(Player, Tool, Player.Character.HumanoidRootPart.CFrame, false, true)
			LocalPlayer.Character.HumanoidRootPart.CFrame = Pos
		end
	end, {"give"})
	
	RegisterCommand("kill", function(PlayerName)
		for i,v in pairs(workspace:GetChildren()) do
			if v.Name == "train" then
				v:Destroy()
			end
		end
		for i,Target in pairs(FindPlayer(PlayerName)) do
			local TargetCharacter = Target.Character
			if TargetCharacter and LocalPlayer.Character and TargetCharacter:FindFirstChild("Humanoid") then
				local OldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
				local TargetHumanoid = TargetCharacter.Humanoid

				local Tries2 = 0
				repeat task.wait()
					Tries2 = Tries2 + 1
					if Tries2 >= 4 then break end

					local Character = LocalPlayer.Character
					Character:WaitForChild("Humanoid");Character:WaitForChild("HumanoidRootPart")

					if TargetCharacter:FindFirstChild("HumanoidRootPart") and Character:FindFirstChild("HumanoidRootPart") then
						FeClaim(Target, nil, nil, CFrame.new(1618, 4.45, -248.75), true, false, 100)
					end
				until TargetHumanoid.Health == 0

				wait(.3)
				LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = OldPosition
			end

		end
	end)
	
	RegisterCommand("antifeclaim", function()
		Toggles["AntiFeClaim"] = not Toggles["AntiFeClaim"]
	end, {"anticlaim", "antibring","anti_bring","anti_fe_claim"})
	
	RegisterCommand("fly", function()
		Toggles["fly"] = not Toggles["fly"]	
	end)
	
	RegisterCommand("bring", function(PlayerName)
		for i,Target in pairs(FindPlayer(PlayerName)) do
			if Target.Character and LocalPlayer.Character then
				for i = 1,2 do
					local OldPosition = FeClaim(Target, false, LocalPlayer.Character.HumanoidRootPart.CFrame, false, true, nil, 100)
					LocalPlayer.Character.HumanoidRootPart.CFrame = OldPosition
				end
			end
		end
	end)
	
	RegisterCommand("flywith", function(PlayerName)
		local Target = FindPlayer(PlayerName)[1]
		if not Target then return end
		for i = 1, 2 do
			local OldPosition = FeClaim(Target, false, LocalPlayer.Character.HumanoidRootPart.CFrame, false, i == 1, nil, 100)
			LocalPlayer.Character.HumanoidRootPart.CFrame = OldPosition
		end

		for i,v in pairs(Target.Character:GetChildren()) do
			if not v:IsA("BasePart") then continue end

			local BodyForce = Instance.new("BodyVelocity")
			BodyForce.Velocity = Vector3.new()
			BodyForce.Parent = v
		end

		Toggles["fly"] = true
	end)
	
	RegisterCommand("changeprefix", function(NewPrefix)
		Prefix = (NewPrefix or Prefix)
	end)
	
	RegisterCommand("aimbot", function()
		Toggles["aimbot"] = not Toggles["aimbot"]
	end)
	
	RegisterCommand("whitelist", function(Player)
		local WhitelistedFolks = {}
		for i,v in pairs(FindPlayer(Player)) do
			table.insert(WhitelistedFolks, v.Name)
		end
		if #WhitelistedFolks == 0 then
			table.insert(WhitelistedFolks, Player)
		end

		for i,v in pairs(WhitelistedFolks) do
			table.insert(Whitelist, v)
		end

		SaveWhitelist()
	end)
	
	RegisterCommand("tp", function(Player)
		local Plrs = FindPlayer(Player)
		for i,v in pairs(Plrs) do
			if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
				end
			end
		end
	end)
end

local function NewPlayerAdded(Plr)
	if table.find(Blacklist, Plr.Name) then
		StarterGui:SetCore("ChatMakeSystemMessage", {
			["Text"] = "Blacklisted player joined the game: "..Plr.Name,
			["Color"] = Color3.new(0,0.6,1)
		})
	end
end

Players.PlayerAdded:Connect(NewPlayerAdded)

for i,v in pairs(Players:GetPlayers()) do
	if v == LocalPlayer then continue end
	NewPlayerAdded(v)
end
      
--[[
      Prefix is "/"
      'Silent' prefix is ":"
      Example:
        /god 
        :kill <player name>
--]]
