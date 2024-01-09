require("Il2cppApi")

Il2cpp()

--declass0: unclasser(), declass1: unmethods(), declass2: unfields, declass3: none
--modes0: patch, modes1: memoize
--flags0: patch, flags1: reverts
--icon: game guardian floating icon state
cases = {current = "normal", memoize = {stores = {}, restore = {}}, flags = {icon = 0, modes = 0, declass = 0, flags = 0}}

------------------------------
---[ FIELDS PROCESSOR ]
------------------------------
function fields_processor(cpp, knx)
	for obj, field in ipairs(knx.fields) do
		local objects = Il2cpp.FindObject({tonumber(knx.ClassAddress, 16)})
		for m, object in ipairs(objects) do
			if cases.flags.modes == false then
				fields_patch(field, object)
			else
				fields_memoize(field, object)
			end
		end
	end
end

function fields_patch(cpp, knx)
	for i = 1, #cpp do
		if cases.flags.flags == 0 then
			if knx.flags == 99 then
				local str = Il2cpp.String.From(cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16))
				if str then
					if type(knx.patches) == 'table' then
						str:EditString(knx.patches[cpp[i].Access])
					else
						str:EditString(knx.patches)
					end
				end
			else
				if type(knx.patches) == 'table' then
					local changes_field = {{
						address = object[i].address + tonumber(v:GetFieldWithName(field.field_name).Offset, 16),
						flags = knx.flags,
						value = knx.patches[cpp[i].Access]
					}}
					gg.setValues(changes_field)
				else
					local changes_field = {{
						address = object[i].address + tonumber(v:GetFieldWithName(field.field_name).Offset, 16),
						flags = knx.flags,
						value = knx.patches
					}}
					gg.setValues(changes_field)
				end
			end
		else
			if knx.flags == 99 then
				local str = Il2cpp.String.From(cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16))
				if str then
					if type(knx.original) == 'table' then
						str:EditString(knx.original[cpp[i].Access])
					else
						str:EditString(knx.original)
					end
				end
			else
				if type(knx.original) == 'table' then
					local changes_field = {{
						address = object[i].address + tonumber(v:GetFieldWithName(field.field_name).Offset, 16),
						flags = knx.flags,
						value = knx.original[cpp[i].Access]
					}}
					gg.setValues(changes_field)
				else
					local changes_field = {{
						address = object[i].address + tonumber(v:GetFieldWithName(field.field_name).Offset, 16),
						flags = knx.flags,
						value = knx.original
					}}
					gg.setValues(changes_field)
				end
			end
		end
	end
end

function fields_memoize(cpp, knx)
	for i = 1, #cpp do
		if knx.flags == 99 then
			local str = Il2cpp.String.From(cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16))
			if str then
				if knx.original == nil then
					cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
						address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16),
						value = str:ReadString(),
						flags = knx.flags
					}
				elseif type(knx.original) == 'table' then
					cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
							address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16),
							value = knx.original[cpp[i].Access],
							flags = knx.flags
						}
				else
					cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
						address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16),
						value = knx.original,
						flags = knx.flags
					}
				end
			end
		else
			if knx.original == nil then
				cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
					address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16),
					value = gg.getValues(cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16))[1].value,
					flags = knx.flags
				}
			elseif type(knx.original) == 'table' then
				cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
					address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16)),
					value = knx.original[cpp[i].Access],
					flags = knx.flags
				}
			else
				cases.memoize.restore[cases.current]['fields'][#cases.memoize.restore[cases.current]['fields'] + 1] = {
					address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16)),
					value = knx.original,
					flags = knx.flags
				}
			end
		if type(knx.patches) == 'table' then
			cases.memoize.store[cases.current]['fields'][#cases.memoize.store[cases.current]['fields'] + 1] = {
				address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16)),
				value = knx.patches[cpp[i].Access],
				flags = knx.flags
			}
		else
			cases.memoize.store[cases.current]['fields'][#cases.memoize.store[cases.current]['fields'] + 1] = {
				address = cpp[i].address + tonumber(v:GetFieldWithName(knx.field_name).Offset, 16)),
				value = knx.patches,
				flags = knx.flags
			}
		end
	end
end

------------------------------
---[ METHODS PROCESSOR ]
------------------------------
function methods_processor(cpp, knx)
	for obj, method in ipairs(knx.methods) do
		local methods = cpp:GetMethodsWithName(method.method_name)
		if #methods > 0 then
			if cases.flags.modes == false then
				methods_patch(methods, method)
			else
				methods_memoize(methods, method)
			end
		end
	end
end

function methods_patch(cpp, knx)
	for i = 1, #cpp do
		if cases.flags.flags == 0 then
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
	for i = 1, #cpp do
		if knx.original == nil then
			local strings, occurence = knx.patches:gsub('\x', '')
			local buffers = #strings / 2
			if knx.offset then
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
					value = const(tonumber(cpp[i].AddressInMemory, 16), buffers)
				}
			else
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16),
					value = const(tonumber(cpp[i].AddressInMemory, 16), buffers)
				}
			end
		elseif type(knx.original) == 'table' then
			if knx.offset then
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
					value = knx.original[cpp[i].Access]
				}
			else
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16),
					value = knx.original[cpp[i].Access]
				}
			end
		else
			if knx.offset then
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
					value = knx.original
				}
			else
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16),
					value = knx.original
				}
			end
		end
		if type(knx.patches) == 'table' then
			if knx.offset then
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
					value = knx.patches[cpp[i].Access]
				}
			else
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16),
					value = knx.patches[cpp[i].Access]
				}
			end
		else
			if knx.offset then
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16) + tonumber(knx.offset, 16),
					value = knx.patches
				}
			else
				cases.memoize.restore[cases.current]['methods'][#cases.memoize.restore[cases.current]['methods'] + 1] = {
					address = tonumber(cpp[i].AddressInMemory, 16),
					value = knx.patches
				}
			end
		end
	end
end

------------------------------
---[ UNCLASSER ]
------------------------------
function unclass_processor(cpp, knx)
	if ((knx.methods == nil) and (knx.fields == nil)) or (knx.flags == 0) or (cases.flags.unclass == 0) then
		unclasser(cpp)
	elseif (knx.flags == 1) or (cases.flags.unclass == 1) then
		unmethods(cpp)
	elseif (knx.flags == 2) or (cases.flags.unclass == 2) then
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

function unclasser(cpp)
	unmethods(cpp)
	unfields(cpp)
end

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

------------------------------
---[ SCRIPT PROCESSOR ]
------------------------------
function processor()
	if cases.memoize.store[cases.current] == nil then
		for keys, value in ipairs(knx) do
			local classes = Il2cpp.FindClass( {{ Class = value.class_name, MethodsDump = true, FieldsDump = true }} )
			for key, val in ipairs(classes) do
				unclass_processor(val, value)
			end
		end
	else
		switcher()
		apply_memo()
	end
end

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

function switcher()
end

function apply_memo()
	if cases.flags.flags == 0 then
		if cases.memoize.store[cases.current]['methods'] ~= nil then
			for key, value in ipairs(cases.memoize.store[cases.current]['methods']) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		end
		if cases.memoize.store[cases.current]['fields'] ~= nil then
			for key, value in ipairs(cases.memoize.store[cases.current]['fields']) do
				if value.flags == 99 then
					local str = Il2cpp.String.From(value.address)
					if str then
						str:EditString(value.value)
					end
				else
					local changes_field  = {
						address = value.address,
						value = value.value,
						flags = value.flags
					}
					gg.setValues(changes_field)
				end
			end
		end
	else
		if cases.memoize.restore[cases.current]['methods'] ~= nil then
			for key, value in ipairs(cases.memoize.restore[cases.current]['methods']) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		end
		if cases.memoize.restore[cases.current]['fields'] ~= nil then
			for key, value in ipairs(cases.memoize.restore[cases.current]['fields']) do
				if value.flags == 99 then
					local str = Il2cpp.String.From(value.address)
					if str then
						str:EditString(value.value)
					end
				else
					local changes_field  = {
						address = value.address,
						value = value.value,
						flags = value.flags
					}
					gg.setValues(changes_field)
				end
			end
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
			dofile('./autohs.cfg')
			cases.current['autohs']
			processor()
		else
			os.exit()
		end
	end
end

while true do
	if gg.isVisible(true) then
		cases.flags.icon = true
	else
		cases.flags.icon = false
	end
	if cases.flags.icon == true then
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