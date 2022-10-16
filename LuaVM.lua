local ExecuteFile
local ExecuteString

coroutine.wrap(function()
	local Debug = false

	local VMExecute = function(Instructions, Constants, Execute)
		if Execute == nil then
			Execute = true
		end

		local VirtualFunction = function(UpValues, ...)
			print("Loaded", #Instructions, "Instructions and",#Constants, "Constants")

			local RealStack = {}
			local VarArg = {...}

			UpValues = (typeof(UpValues) == "table" and UpValues) or {}

			local Stack = newproxy(true)

			getmetatable(Stack).__newindex = function(self, index, value)
				if Debug then
					print("Stack __newindex:",index, value)
				end
				return rawset(RealStack, index, value)
			end
			getmetatable(Stack).__index = function(self, index)
				if Debug then
					print("Stack __index:",index)
				end
				return rawget(RealStack, index)
			end

			for i,v in pairs(Constants) do
				print(i,v)
				Stack[-i] = v
			end

			local Index = 1

			while true do
				local Instruction = Instructions[Index]

				if not Instruction then
					break
				end

				local OPCODE = Instruction["NAME"]
				local Args = Instruction["Arguments"]

				if Debug then
					warn(table.unpack(Args))
				end

				if OPCODE == "MOV" then
					local A, B = tonumber(Args[1]), tonumber(Args[2])
					Stack[A] = Stack[B]
				elseif OPCODE == "JMP" then
					local sBx = tonumber(Args[1])
					Index = Index + sBx
				elseif OPCODE == "LOADK" then
					local A, Bx = tonumber(Args[1]), tonumber(Args[2])
					Stack[A] = Stack[Bx]
				elseif OPCODE == "CALL" then
					local A, B, C = tonumber(Args[1]), tonumber(Args[2]), tonumber(Args[3])
					local args = {}
					for i = A + 1, A + B - 1 do
						table.insert(args, Stack[i])
					end
					local packed = {Stack[A](table.unpack(args))}
					local index = 1
					for i = A, A + C - 2 do
						Stack[i] = packed[index]
						index = index + 1
					end
				elseif OPCODE == "GETGLOBAL" then
					local A, Bx = tonumber(Args[1]), tonumber(Args[2])
					Stack[A] = getfenv(1)[Stack[Bx]]
				elseif OPCODE == "SELF" then
					local A, B, C = tonumber(Args[1]), tonumber(Args[2]), tonumber(Args[3])
					Stack[A + 1] = Stack[B]
					Stack[A] = Stack[B][Stack[C]]
				elseif OPCODE == "SETGLOBAL" then
					local A, Bx = tonumber(Args[1]), tonumber(Args[2])
					getfenv(1)[Stack[Bx]] = Stack[A]
				elseif OPCODE == "GETTABLE" then
					local A, B, C = tonumber(Args[1]), tonumber(Args[2]), tonumber(Args[3])
					Stack[A] = Stack[B][Stack[C]]
				elseif OPCODE == "FORLOOP" then
					local A, sBx = tonumber(Args[1]), tonumber(Args[2])
					Stack[A] = Stack[A] + Stack[A + 2]
					if Stack[A] <= Stack[A + 1] then
						Index = Index + sBx
						Stack[A + 3] = Stack[A]
					end
				elseif OPCODE == "FORPREP" then
					local A, sBx = tonumber(Args[1]), tonumber(Args[2])
					Stack[A] = Stack[A] - Stack[A + 2]
					Index = Index + sBx
				elseif OPCODE == "RETURN" then
					local Tb = {}
					for i = Args[1], Args[2] - 1 do
						table.insert(Tb, Stack[i])
					end

					return table.unpack(Tb)
				end

				Index = Index + 1
			end
		end
		if Execute then
			return VirtualFunction()
		end

		return VirtualFunction
	end

	local SupportedInstructions = {
		["MOV"] = 2,
		["JMP"] = 1,
		["LOADK"] = 2,
		["CALL"] = 3,
		["GETGLOBAL"] = 2,
		["SETGLOBAL"] = 2,
		["GETTABLE"] = 3,
		["FORLOOP"] = 2,
		["SELF"] = 3,
		["FORPREP"] = 2,
		["RETURN"] = 2
	}

	ExecuteString = function(String)
		local Tb = string.split(String, "\n")

		local ConstantsTb = {}
		local InstructionsTb = {}

		for i,v in pairs(Tb) do
			local IsString = v:match('%b""')
			if IsString then
				table.insert(ConstantsTb, IsString:sub(2, #IsString - 1))
			elseif tonumber(v) then
				table.insert(ConstantsTb, tonumber(v))
			else
				local OPCode = v:match("^%w+")
				if not OPCode then
					return error("Error on line: "..tostring(i).." Invalid syntax!")
				end

				local IsValidInstruction = SupportedInstructions[OPCode]
				if not IsValidInstruction then
					return error("Error on line: "..tostring(i)..", "..v.." This opcode does not exists!")
				end

				local RemovedComments = (v:gsub(";.+", ""))
				local Arguments = string.split(RemovedComments:sub(#OPCode + 1, 5000):gsub(" ", ""), ",")
				if #Arguments ~= IsValidInstruction then
					return error("Error on line: "..tostring(i)..", "..OPCode.." Accepts only "..tostring(IsValidInstruction).." arguments!")
				end
				table.insert(InstructionsTb, {
					["NAME"] = OPCode,
					["Arguments"] = Arguments
				})
			end


		end
		VMExecute(InstructionsTb, ConstantsTb)
	end

	ExecuteFile = function(FileName)
		ExecuteString(readfile(FileName))
	end
end)()

ExecuteString([[
"print"
"Hello, world!"
GETGLOBAL	0, -1
LOADK	1, -2
CALL	0, 2, 1]])
