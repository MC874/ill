require("Il2cppApi")

Il2cpp()

--declass0: declasser(), declass1: unmethods(), declass2: unfields, declass3: none
--modes0: patch, modes1: memoize
--flags0: patch, flags1: reverts
local cases = {current = "normal", memoize = {stores = {}, replaces = {}}, flags{icon = 0, modes = 0, declass = 0, flags = 0}}

------------------------------
---[ FIELDS PROCESSOR ]
------------------------------
function fields_processor(cpp, knx)
	for obj, field in ipairs(knx.fields) do
	end
end

------------------------------
---[ METHODS PROCESSOR ]
------------------------------
function methods_processor(cpp, knx)
	for obj, method in ipairs(knx.methods) do
		local methods = cpp:GetMethodsWithName(method.method_name)
		if #methods > 0 then
			if cases.modes == false then
				methods_patch(methods, method)
			else
				methods_memoize(methods, method)
			end
		end
	end
end

function methods_patch(cpp, knx)
	for i = 1, #cpp do
		if cases.flags == 0 then
			if knx.offset then
				if type(knx.patches) == 'table' then
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16), knx.patches[cpp[i].Access])
				else
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16), knx.patches)
				end
			else
				if type(knx.patches) == 'table' then
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16), knx.patches[cpp[i].Access])
				else
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16), knx.patches)
				end
			end
		elseif cases.flags == 1 then
			if knx.offset then
				if type(knx.original) == 'table' then
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16), knx.original[cpp[i].Access])
				else
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16), knx.original)
				end
			else
				if type(knx.patches) == 'table' then
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16), knx.original[cpp[i].Access])
				else
					Il2cpp.PatchesAddress(tonumber(cpp[i].AddressInMemory, 16), knx.original)
				end
			end
		end
	end
end

function methods_memoize(cpp, knx)
	if cases.memoize.store[cases.current] == nil then
		for i = 1, #cpp do
			if knx.original == nil then
				local strings, occurence = knx.patches:gsub('\x', '')
				local buffers = #strings / 2
				if knx.offset then
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
						value = const(tonumber(cpp[i].AddressInMemory, 16), buffers)
					}
				else
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16),
						value = const(tonumber(cpp[i].AddressInMemory, 16), buffers)
					}
				end
			elseif type(knx.original) == 'table' then
				if knx.offset then
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
						value = knx.original[cpp[i].Access]
					}
				else
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16),
						value = knx.original[cpp[i].Access]
					}
				end
			else
				if knx.offset then
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
						value = knx.original
					}
				else
					cases.memoize.restore[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16),
						value = knx.original
					}
				end
			end
			if type(knx.patches) == 'table' then
				if knx.offset then
					cases.memoize.store[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
						value = knx.patches[cpp[i].Access]
					}
				else
					cases.memoize.store[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16),
						value = knx.patches[cpp[i].Access]
					}
				end
			else
				if knx.offset then
					cases.memoize.store[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
						value = knx.patches
					}
				else
					cases.memoize.store[cases.current] = {
						address = tonumber(cpp[i].AddressInMemory, 16),
						value = knx.patches
					}
				end
			end
		end
	else
		if cases.flags == 0 then
			for key, value in ipairs(cases.memoize.store[cases.current]) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		else
			for key, value in ipairs(cases.memoize.restore[cases.current]) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		end
	end
end

------------------------------
---[ DECLASSER ]
------------------------------
function unmethods(cpp)
	for key, value in ipairs(cpp.Methods) do
		local methods = cpp:GetMethodsWithName(value.MethodName)
		if #methods > 0 then
			for i = 1, #methods do
				if v.Type == "bool" then
					Il2cpp.PatchesAddress(tonumber(methods[i].AddressInMemory, 16), "\x00\x00\x00\xE3\x1E\xFF\x2F\xE1")
				elseif v.Type == "float" then
					Il2cpp.PatchesAddress(tonumber(methods[i].AddressInMemory, 16), "\x00\x00\x00\xE3\x10\x0A\x00\xEE\xC0\x0A\xB8\xEE\x10\x0A\x10\xEE\x1E\xFF\x2F\xE1")
				else
					Il2cpp.PatchesAddress(tonumber(methods[i].AddressInMemory, 16), "\x00\x00\xA0\xE1\x1E\xFF\x2F\xE1")
				end
			end
		end
	end
end

function unfields(cpp)
	local objects = Il2cpp.FindObject({tonumber(cpp.ClassAddress, 16)})
	for key, value in ipairs(cpp.Fields) do
		if value.Type == 'string' then
			for m, object in ipairs(objects) do
				for i = 1, #object do
					local str = Il2cpp.String.From(object[i].address + tonumber(val:GetFieldWithName(value.FieldName).Offset, 16))
					if str then
						str:EditString('')
					end
				end
			end
		elseif value.Type == 'bool' or value.Type == 'int' then
			for m, object in ipairs(objects) do
				for i = 1, #object do
					local changes_field = {{
						address = object[i].address + tonumber(val:GetFieldWithName(value.FieldName).Offset, 16),
						flags = gg.TYPE_DWORD,
						value = 0
					}}
					gg.setValues(changes_field)
				end
			end
		elseif value.Type == 'float' then
			for m, object in ipairs(objects) do
				for i = 1, #object do
					local changes_field = {{
						address = object[i].address + tonumber(val:GetFieldWithName(value.FieldName).Offset, 16),
						flags = gg.TYPE_FLOAT,
						value = 0
					}}
					gg.setValues(changes_field)
				end
			end
		end
	end
end

function declasser(cpp)
	unmethods(cpp)
	unfields(cpp)
end

function declass_processor(cpp, knx)
	if ((knx.methods == nil) and (knx.fields == nil)) or (knx.flags == 0) or (cases.declass == 0) then
		declasser(cpp)
	elseif (knx.flags == 1) or (cases.declass == 1) then
		unmethods(cpp)
	elseif (knx.flags == 2) or (cases.declass == 2) then
		unfields(cpp)
	else
		if val.methods then
			methods_processor(cpp, knx)
		end
		if val.fields then
			fields_processor(cpp, knx)
		end
	end
end

------------------------------
---[ SCRIPT PROCESSOR ]
------------------------------
function const(addr, buffer)
	construct = ""
	current = {}
	for _ = 1, buffer do
		current[_] = {address = (addr - 1) + _, flags = gg.TYPE_BYTE}
	end
	for k, v in ipairs(gg.getValues(current)) do
		construct = construct .. string.format("%02X", v.value & 0xFF)
    end
	return construct
end

function hexdecode(hex)
   return (hex:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

function setvalue(address,flags,value) local tt={} tt[1]={} tt[1].address=address tt[1].flags=flags tt[1].value=value gg.setValues(tt) end

function processor()
	for keys, value in ipairs(knx) do
		local classes = Il2cpp.FindClass( {{ Class = value.class_name, MethodsDump = true, FieldsDump = true }} )
		for key, val in ipairs(classes) do
			declass_processor(val, value)
		end
	end
end

------------------------------
---[ SCRIPT ]
------------------------------
function menus()
	local firstMenu = gg.choice({"Auto Headshot", "❌EXIT❌"}, nil, "State: " .. tostring(cases.flags.modes))
	if firstMenu == nil then
		cases.icon = false
		gg.setVisible(false)
	else
		cases.icon = false
		gg.setVisible(false)
		if firstMenu == 1 then
			--dosomething
		else
			os.exit()
		end
	end
end

while true do
	if gg.isVisible(true) then
		cases.icon = true
	else
		cases.icon = false
	end
	if cases.icon == true then
		gg.showUiButton()
		menus()
		if gg.isClickedUiButton() then
			switcher()
			swapper()
		end
	else
		gg.hideUiButton()
	end
end