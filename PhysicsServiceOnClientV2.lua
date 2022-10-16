--[[
	-** Physics service on client V.2 -**

	-----------------------------------------
	| Since it's almost a year since 
	| the official release on v3rmillion.net,
	| I decided to update this script and remember
	| the good old days of exploiting roblox.
	| I did not forget you guys
	----------------------------------------
	
	I've made the script more readable so
	that people can modify it and exploit
	developers can implement it in their exploits.
	
	=====================================
	
	
	Sorry for not explaining how this script works.
	Basically all collision groups have a negative
	number behind them, this number is responsible
	for collisions between collision groups.
	This number is called "Mask",	
	the smaller this number, the more collision
	groups it does not collide with.
	
	If a collision group collide with
	"Default" collision group then the mask
	will be always odd
	
	The default value of mask is -1.
	
	Collision group structure:
		<Name>^<Index>^<Mask>
	Example:
		Default^0^-1
	
	
	if you disable the collision with the collision group
	at index 1 and with	the collision group at index 2
	(starting from 0, actually the second and the third collision group),
	then the mask of the collision group at index 1 will
	change to -1 + -2^(index_2) = -1 + - 2^(2) = -5, 
	and the mask of the collision group with index 2 will
	сhange to -1 + -2^(index_1) = -1 + -2^(1) = -3
	
	index_1 = 1
	index_2 = 2
	
	
	Here the example:
		Given: 
			Default^0^-1\Test1^1^-1\Test2^2^-1
		
		We disable collision between Test1 and Test2,
		So we get:
		
			Default^0^-1\Test1^1^-5\Test2^2^-3
								  |          |
								  |          ^(Test2[Mask] + -2^(Test1[Index]))
								  |           [-1 + -2 = -3]
								  |
								  ^(Test1[Mask] + -2^(Test2[Index]))
								   [-1 + -4 = -5]
	
	Collision groups are separated by the "\" symbol.
]]


local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

local ArgCheckErrorMsg = "invalid argument #%d to '?' (%s expected, got %s)"

local function Calculate(Integer)
	Integer = tonumber(Integer)
	return -(2^(Integer))
end

local function GetCollisionGroups()
	return (gethiddenproperty(Workspace, "CollisionGroups"):split("\\"))		
end

local function FindCollisionGroup(Name)
	for Index,CollisionGroup in pairs(GetCollisionGroups()) do
		local Properties = CollisionGroup:split("^")

		--   Properties:
		--//   [1] - Collision group name
		--//   [2] - Collision group index
		--//   [3] - Collision group mask

		if Properties[1] == Name then
			return CollisionGroup
		end
	end

	return false
end

local function EditCollisionGroup(Name, NewName, Index, Mask)
	return sethiddenproperty(workspace, "CollisionGroups", (
		string.gsub(gethiddenproperty(workspace, "CollisionGroups"), "("..Name..")%^(%d+)%^(%-?%d+)", function(OldName, OldIndex, OldMask)
			return ("%s^%s^%s"):format(Name or OldName, Index or OldIndex, Mask or OldMask)
		end)
		)
	)
end

local Functions;
Functions = {
	--Making it all a C function because I'm still paranoid
	
	CreateCollisionGroup = newcclosure(function(self, Name)
		
		--I actually debugged Roblox to find error messages
		assert(self == PhysicsService, "Expected ':' not '.' calling member function CreateCollisionGroup")
		assert(FindCollisionGroup(Name) == false, "Could not create collision group, one with that name already exists.")
		assert(#Name <= 100, "Collision group name length cannot exceed 100 chars")
		--The original message contains '', instead of '\',
		--they just forgot about the properties of the escape character
		assert(not Name:find("%^") and not Name:find("\\"), "Collision group name must not contain a '\\' or a '^'.")
		assert(#Name >= 1, "Collision group requires a valid name.")
		
		local CollisionGroupIndex = 0
		for i,v in pairs(GetCollisionGroups()) do
			local Properties = v:split("^")
			if CollisionGroupIndex == tonumber(Properties[2]) then
				CollisionGroupIndex += 1
			else
				break
			end
		end
		
		sethiddenproperty(Workspace, "CollisionGroups", gethiddenproperty(Workspace, "CollisionGroups")..
			"\\"..table.concat({Name, CollisionGroupIndex, "-1"}, "^")
		)

		return true	
	end),
	CollisionGroupSetCollidable = newcclosure(function(self, Name1, Name2, Boolean)
		
		assert(self == PhysicsService, "Expected ':' not '.' calling member function CollisionGroupSetCollidable")

		assert(typeof(Name1) == "string",    ArgCheckErrorMsg:format(1, "string", typeof(Name1)))
		assert(typeof(Name2) == "string",    ArgCheckErrorMsg:format(2, "string", typeof(Name2)))
		assert(typeof(Boolean) == "boolean", ArgCheckErrorMsg:format(3, "boolean", typeof(Boolean)))

		assert(FindCollisionGroup(Name1) and FindCollisionGroup(Name2), "Both collision groups must be registered.")

		local CollisionGroup1 = FindCollisionGroup(Name1)
		local CollisionGroup2 = FindCollisionGroup(Name2)

		local Properties1 = CollisionGroup1:split("^")
		local Properties2 = CollisionGroup2:split("^")

		if PhysicsService:CollisionGroupsAreCollidable(Name1, Name2) ~= Boolean then
			if Name1 == Name2 then
				EditCollisionGroup(Name1, nil, nil, (
					Properties1[3] + (Boolean and -1 or 1) * Calculate(Properties1[2])
				))
			else
				EditCollisionGroup(Name1, nil, nil, (
					Properties1[3] + (Boolean and -1 or 1) * Calculate(Properties2[2])
				))
				EditCollisionGroup(Name2, nil, nil, (
					Properties2[3] + (Boolean and -1 or 1) * Calculate(Properties1[2])
				))
			end
		end
	end),
	RemoveCollisionGroup = newcclosure(function(self, CollisionGroupName)
		assert(self == PhysicsService, "Expected ':' not '.' calling member function RemoveCollisionGroup")
		assert(typeof(CollisionGroupName) == "string", ArgCheckErrorMsg:format(1, "string", typeof(CollisionGroupName)))

		local String = ""
		for Index,CollisionGroup in pairs(GetCollisionGroups()) do
			if CollisionGroup:split("^")[1] ~= CollisionGroupName then
				String = String..(Index ~= 1 and "\\" or "")..CollisionGroup
			end
		end
		String:gsub("\\$", "")
		
		sethiddenproperty(Workspace, "CollisionGroups", String)
	end),
	RenameCollisionGroup = newcclosure(function(self, CollisionGroup, NewName)
		assert(self == PhysicsService, "Expected ':' not '.' calling member function RenameCollisionGroup")

		assert(typeof(CollisionGroup) == "string", ArgCheckErrorMsg:format(1, "string", typeof(CollisionGroup)))
		assert(typeof(NewName) == "string", ArgCheckErrorMsg:format(2, "string", typeof(NewName)))

		EditCollisionGroup(CollisionGroup, NewName, nil, nil)
	end),
}

--New names for functions in PhysicsService (Just for future),
--https://devforum.roblox.com/t/updates-to-collision-groups/1990215
Functions.RegisterCollisionGroup = Functions.CreateCollisionGroup
Functions.UnregisterCollisionGroup = Functions.RemoveCollisionGroup


local __NameCall
__NameCall = hookmetamethod(game, "__namecall" ,function(self, ...)
	if not checkcaller() then return __NameCall(self, ...) end

	local NameCallMethod = getnamecallmethod()

	if self == PhysicsService and Functions[NameCallMethod] then
		return Functions[NameCallMethod](self, ...)
	end

	return __NameCall(self, ...)
end)

local __Index
__Index = hookmetamethod(game, "__index", function(self, Index)
	if not checkcaller() then return __Index(self, Index) end

	if self == PhysicsService and Functions[Index] then
		return Functions[Index]
	end

	return __Index(self, Index)
end)
