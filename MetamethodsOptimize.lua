local mt = getrawmetatable(game)
local tb = {}

local Newindex = mt.__newindex
local Index = mt.__index

setreadonly(mt, false)

--Using the old *hooks* because its faster than hookmetamethod. The most craziest move here.
--Dont worry this script is safe (As much as I know)

mt.__index = function(self, index)
	local Tb = tb[self]

	if not Tb then
		local NewTb = {
			["__index"] = {},
			["__namecall"] = {}
		}
		tb[self] = NewTb
		NewTb["__index"][index] = Index(self, index)
	else
		local a = Tb["__index"]
		local b = a[index]
		if b then
			return b
		else
			a[index] = Index(self, index)
		end
	end
	return Index(self, index)
end

mt.__newindex = function(self, index, value)
	local C = tb[self]
	if C then
		--Indexing tables for more optimization
		local __index = C["__index"]
		local SelfIndex = __index[index]

		if SelfIndex == value then
			return
		end

		__index[index] = value
	end

	return Newindex(self, index, value)
end


--Garbage collector
while task.wait() do
	local count = 0
	for i,v in pairs(tb) do
		for i2, v2 in pairs(v["__index"])  do
			if v[i2] ~= v2 then
				tb[i]["__index"][i2] = nil
				count = count + 1
			end
		end
	end
	--warn(count, "Items were garbage collected!")
end
