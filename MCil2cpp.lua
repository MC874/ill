require("Il2cppApi")

Il2cpp()

--declass0: unclasser(), declass1: unmethods(), declass2: unfields, declass3: none
--modes0: patch, modes1: memoize
--flags0: patch, flags1: reverts
--icon: game guardian floating icon state
cases = {current = "normal", memoize = {stores = {}, restores = {}}, flags = {icon = false, modes = 0, declass = 0, flags = 0}}

------------------------------
---[ FIELDS PROCESSOR ]
------------------------------
function fields_processor(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for k, v in ipairs(classes) do
		for k, v in ipairs(v) do
			if v.Fields == nil then
				break
			end
			local objects = Il2cpp.FindObject({tonumber(v.ClassAddress, 16)})
			for obj, field in ipairs(knx.fields) do
				for m, object in ipairs(objects) do
					if cases.flags.modes == 0 then
						fields_patch(object, v, field)
					else
						fields_memoize(object, v, field)
					end
				end
			end
		end
	end
end

function fields_patch(objects, cpp, knx)
	for key, value in ipairs(cpp.Fields) do
		if value.FieldName == knx.field_name then
			for i = 1, #objects do
				if cases.flags.flags == 0 then
					if knx.flags == 99 then
						local str = Il2cpp.String.From(objects[i].address + tonumber(value.Offset, 16))
						if str then
							if type(knx.patches) == 'table' then
								str:EditString(knx.patches[objects[i].Access])
							else
								str:EditString(knx.patches)
							end
						end
					else
						if type(knx.patches) == 'table' then
							local changes_field = {{
								address = objects[i].address + tonumber(value.Offset, 16),
								flags = knx.flags,
								value = knx.patches[objects[i].Access]
							}}
							gg.setValues(changes_field)
						else
							local changes_field = {{
								address = objects[i].address + tonumber(value.Offset, 16),
								flags = knx.flags,
								value = knx.patches
							}}
							gg.setValues(changes_field)
						end
					end
				else
					if knx.flags == 99 then
						local str = Il2cpp.String.From(objects[i].address + tonumber(value.Offset, 16))
						if str then
							if type(knx.original) == 'table' then
								str:EditString(knx.original[objects[i].Access])
							else
								str:EditString(knx.original)
							end
						end
					else
						if type(knx.original) == 'table' then
							local changes_field = {{
								address = objects[i].address + tonumber(value.Offset, 16),
								flags = knx.flags,
								value = knx.original[cpp[i].Access]
							}}
							gg.setValues(changes_field)
						else
							local changes_field = {{
								address = objects[i].address + tonumber(value.Offset, 16),
								flags = knx.flags,
								value = knx.original
							}}
							gg.setValues(changes_field)
						end
					end
				end
			end
		end
	end
end

function fields_memoize(objects, cpp, knx)
	cases.memoize.restores[cases.current]['fields'] = {}
	cases.memoize.stores[cases.current]['fields'] = {}
	for key, value in ipairs(cpp.Fields) do
		if value.FieldName == knx.field_name then
			for i = 1, #objects do
				if knx.flags == 99 then
					local str = Il2cpp.String.From(objects[i].address + tonumber(value.Offset, 16))
					if str then
						if knx.original == nil then
							cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
								address = objects[i].address + tonumber(value.Offset, 16),
								value = str:ReadString(),
								flags = knx.flags
							}
						elseif type(knx.original) == 'table' then
							cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
									address = objects[i].address + tonumber(value.Offset, 16),
									value = knx.original[objects[i].Access],
									flags = knx.flags
								}
						else
							cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
								address = objects[i].address + tonumber(value.Offset, 16),
								value = knx.original,
								flags = knx.flags
							}
						end
					end
				else
					if knx.original == nil then
						cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
							address = objects[i].address + tonumber(value.Offset, 16),
							value = gg.getValues({{address = objects[i].address + tonumber(value.Offset, 16), flags = knx.flags}})[1].value,
							flags = knx.flags
						}
					elseif type(knx.original) == 'table' then
						cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
							address = objects[i].address + tonumber(value.Offset, 16),
							value = knx.original[objects[i].Access],
							flags = knx.flags
						}
					else
						cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
							address = objects[i].address + tonumber(value.Offset, 16),
							value = knx.original,
							flags = knx.flags
						}
					end
				end
				if type(knx.patches) == 'table' then
					cases.memoize.stores[cases.current]['fields'][#cases.memoize.stores[cases.current]['fields'] + 1] = {
						address = objects[i].address + tonumber(value.Offset, 16),
						value = knx.patches[objects[i].Access],
						flags = knx.flags
					}
				else
					cases.memoize.stores[cases.current]['fields'][#cases.memoize.stores[cases.current]['fields'] + 1] = {
						address = objects[i].address + tonumber(value.Offset, 16),
						value = knx.patches,
						flags = knx.flags
					}
				end
			end
		end
	end
	apply_memo()
end

------------------------------
---[ METHODS PROCESSOR ]
------------------------------
function methods_processor(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for k, v in ipairs(classes) do
		for k, v in ipairs(v) do
			if v.Methods == nil then
				break
			end
			for obj, method in ipairs(knx.methods) do
				for key, val in ipairs(v.Methods) do
					if method.method_name == val.MethodName then
						if cases.flags.modes == 0 then
							methods_patch(val, method)
						else
							methods_memoize(val, method)
						end
					end
				end
			end
		end
	end
end

function methods_patch(cpp, knx)
	if cases.flags.flags == 0 then
		if knx.offset then
			if type(knx.patches) == 'table' then
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16), knx.patches[cpp.Access])
			else
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16), knx.patches)
			end
		else
			if type(knx.patches) == 'table' then
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16), knx.patches[cpp.Access])
			else
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16), knx.patches)
			end
		end
	elseif cases.flags.flags == 1 then
		if knx.offset then
			if type(knx.original) == 'table' then
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16), knx.original[cpp.Access])
			else
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16), knx.original)
			end
		else
			if type(knx.patches) == 'table' then
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16), knx.original[cpp.Access])
			else
				Il2cpp.PatchesAddress(tonumber(cpp.AddressInMemory, 16), knx.original)
			end
		end
	end
end

function methods_memoize(cpp, knx)
	cases.memoize.restores[cases.current]['methods'] = {}
	cases.memoize.stores[cases.current]['methods'] = {}
	if knx.original == nil then
		local strings, occurence = knx.patches:gsub('\\x', '')
		local buffers = #strings / 2
		if knx.offset then
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16),
				value = const(tonumber(cpp.AddressInMemory, 16), buffers)
			}
		else
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16),
				value = const(tonumber(cpp.AddressInMemory, 16), buffers)
			}
		end
	elseif type(knx.original) == 'table' then
		if knx.offset then
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16),
				value = knx.original[cpp.Access]
			}
		else
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16),
				value = knx.original[cpp.Access]
			}
		end
	else
		if knx.offset then
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16),
				value = knx.original
			}
		else
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16),
				value = knx.original
			}
		end
	end
	if type(knx.patches) == 'table' then
		if knx.offset then
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16),
				value = knx.patches[cpp.Access]
			}
		else
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16),
				value = knx.patches[cpp.Access]
			}
		end
	else
		if knx.offset then
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16) + tonumber(knx.offset, 16),
				value = knx.patches
			}
		else
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(cpp.AddressInMemory, 16),
				value = knx.patches
			}
		end
	end
	apply_memo()
end

------------------------------
---[ HOOK PROCESSOR ]
------------------------------
function hook_methods_processor(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for key, value in ipairs(classes) do
		for key, value in ipairs(value) do
			for k, v in ipairs(knx.hook_methods) do
				if type(v.target) == 'table' then
					for key, val in ipairs(v.target) do
						local target = {}
						local jump = ''
						for obj, method in ipairs(value.Methods) do
							if method.MethodName == val then
								target[#target + 1] = '0x' .. tostring(method.AddressInMemory)
							end
							if method.MethodName == v.jump then
								jump = '0x' .. tostring(method.AddressInMemory)
							end
						end
						hook_methods(target, jump)
					end
				else
					local target = {}
					local jump = ''
					for obj, method in ipairs(value.Methods) do
						if method.MethodName == v.target then
							target[#target + 1] = '0x' .. tostring(method.AddressInMemory)
						end
						if method.MethodName == v.jump then
							jump = '0x' .. tostring(method.AddressInMemory)
						end
					end
					hook_methods(target, jump)
				end
			end
		end
	end
end

function hook_methods(target, jump)
	for k, v in ipairs(target) do
		offset = displace(v, jump)
		
		change_method = {{
			address = v,
			value = '~A B ' .. offset,
			flags = gg.TYPE_DWORD
		}}
		
		gg.setValues(change_method)
	end
end

------------------------------
---[ ENUMERATOR ]
------------------------------
function enumerator(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for k, v in ipairs(classes) do
		for k, v in ipairs(v) do
			if v.Fields == nil then
				break
			end
			local objects = Il2cpp.FindObject({tonumber(v.ClassAddress, 16)})
			for obj, field in ipairs(knx.fields) do
				for key, val in ipairs(v.Fields) do
					if val.FieldName == field.field_name then
						if field.flags == 99 then
							for keys, value in ipairs(objects) do
								for keys, value in ipairs(value) do
									local il2cppstr = Il2cpp.String.From(value.address + tonumber(val.Offset, 16))
									for keys, value in ipairs(field.targets) do
										if il2cppstr then
											if il2cppstr:ReadString() == value then
												il2cppstr:EditString(field.patches)
											end
										end
									end
								end
							end
						else
							local stores = {}
							for keys, value in ipairs(objects) do
								for keys, value in ipairs(value) do
									stores[#stores + 1] = {
										address = value.address + tonumber(val.Offset, 16),
										flags = field.flags,
										value = gg.getValues({{address = value.address + tonumber(val.Offset, 16), flags = field.flags}})[1].value
									}
								end
							end
							for k, v in ipairs(field.targets) do
								gg.loadResults(stores)
								gg.refineNumber(v, gg.TYPE_DWORD)
								gg.getResults(gg.getResultsCount())
								gg.editAll(field.patches, field.flags)
								gg.clearResults()
							end
						end
					end
				end
			end
		end
	end
end

------------------------------
---[ UNCLASSER ]
------------------------------
function unclass_processor(knx)
	if (knx.flags == 0) or (cases.flags.unclass == 0) then
		unclasser(knx)
	elseif (knx.flags == 1) or (cases.flags.unclass == 1) then
		unmethods(knx)
	elseif (knx.flags == 2) or (cases.flags.unclass == 2) then
		unfields(knx)
	elseif (knx.flags == 3) or (cases.flags.unclass == 3) then
		hook_methods_processor(knx)
	elseif (knx.flags == 4) or (cases.flags.unclass == 4) then
		enumerator(knx)
	else
		if knx.methods then
			methods_processor(knx)
		end
		if knx.fields then
			fields_processor(knx)
		end
	end
end

function unclasser(knx)
	unmethods(knx)
	unfields(knx)
end

function unmethods(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for k, v in ipairs(classes) do
		for k, cpp in ipairs(v) do
			if cpp.Methods == nil then
				break
			end
			for key, value in ipairs(cpp.Methods) do
				if value.Type == "bool" or value.Type == 'int' then
					Il2cpp.PatchesAddress(tonumber(value.AddressInMemory, 16), "\x00\x00\x00\xE3\x1E\xFF\x2F\xE1")
				elseif value.Type == "float" then
					Il2cpp.PatchesAddress(tonumber(value.AddressInMemory, 16), "\x00\x00\x00\xE3\x10\x0A\x00\xEE\xC0\x0A\xB8\xEE\x10\x0A\x10\xEE\x1E\xFF\x2F\xE1")
				else
					Il2cpp.PatchesAddress(tonumber(value.AddressInMemory, 16), "\x00\x00\xA0\xE1\x1E\xFF\x2F\xE1")
				end
			end
		end
	end
end

function unfields(knx)
	local classes = Il2cpp.FindClass( {{Class = knx.class_name,  MethodsDump = true, FieldsDump = true}} )
	for k, v in ipairs(classes) do
		for k, cpp in ipairs(v) do
			if cpp.Fields == nil then
				break
			end
			for key, value in ipairs(cpp.Fields) do
				local objects = Il2cpp.FindObject({tonumber(cpp.ClassAddress, 16)})
				if value.Type == 'string' then
					for m, object in ipairs(objects) do
						for i = 1, #object do
							local str = Il2cpp.String.From(object[i].address + tonumber(value.Offset, 16))
							if str then
								str:EditString('')
							end
						end
					end
				elseif value.Type == 'bool' or value.Type == 'int' then
					for m, object in ipairs(objects) do
						for i = 1, #object do
							local changes_field = {{
								address = object[i].address + tonumber(value.Offset, 16),
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
								address = object[i].address + tonumber(value.Offset, 16),
								flags = gg.TYPE_FLOAT,
								value = 0
							}}
							gg.setValues(changes_field)
						end
					end
				end
			end
		end
	end
end

------------------------------
---[ SCRIPT PROCESSOR ]
------------------------------
function processor(current, declass, mode, flag, reset)
	cases.current = current
	cases.flags = {unclass = declass, modes = mode, flags = flag}
	local flags = false
	if mode == 1 then
		if (cases.memoize.stores[cases.current] == nil) or (reset == 1) then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.flags.flags = 0
			flags = false
		elseif (cases.memoize.stores[cases.current] ~= nil) or (reset == 0) then
			if cases.flags.flags == 0 then
				cases.flags.flags = 1
			elseif cases.flags.flags == 1 then
				cases.flags.flags = 0
			end
			flags = true
		end
	end
	if flags == true then
		apply_memo()
	else
		for keys, value in ipairs(knx) do
			unclass_processor(value)
		end
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

function displace(target, jump)
	local calls
	if tonumber(target) > tonumber(jump) then
		local offset = tonumber(target) - tonumber(jump)
		if offset / 1002400 < 32 then
			calls = "-" .. "0x" .. string.upper(string.format("%x", offset))
		end
	else
		local offset = tonumber(jump) - tonumber(target)
		calls = "+" .. "0x" .. string.upper(string.format("%x", offset))
	end
	return calls
end

function apply_memo()
	if cases.flags.flags == 0 then
		if cases.memoize.stores[cases.current]['methods'] ~= nil then
			for key, value in ipairs(cases.memoize.stores[cases.current]['methods']) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		end
		if cases.memoize.stores[cases.current]['fields'] ~= nil then
			gg.setValues(cases.memoize.stores[cases.current]['fields'])
		end
	else
		if cases.memoize.restores[cases.current]['methods'] ~= nil then
			for key, value in ipairs(cases.memoize.restores[cases.current]['methods']) do
				Il2cpp.PatchesAddress(value.address, value.value)
			end
		end
		if cases.memoize.restores[cases.current]['fields'] ~= nil then
			gg.setValues(cases.memoize.restores[cases.current]['fields'])
		end
	end
end

------------------------------
---[ SCRIPT ]
------------------------------
function menus()
	lists = {"Emulator", "Recoil", "HeadShot", "AntiCheat", "Skill", "Rapid Fire", "Crosshair", "Speed", "Combine", "Experimental", "❌EXIT❌"}
	local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
	if choices == nil then
		cases.flags.icon = false
		gg.setVisible(false)
	else
		cases.flags.icon = false
		gg.setVisible(false)
		if choices == 1 then
			--current, unclass, mode, flag, reset
			so = gg.getRangesList('libanogs.so')[1].start
			setvalue(so + "0x114A28",32,"h 00 20 70 47")
			setvalue(so + "0x115334",32,"h 00 20 70 47")
			setvalue(so + "0x60522",32,"h 00 20 70 47")
			setvalue(so + "0x75eec",32,"h 00 20")
			setvalue(so + "0x9d47c",32,"h 00 20 70 47")
			setvalue(so + "0x116992",32,"h 00 20 70 47")
			setvalue(so + "0x38712",32,"h 09 00 09 00")
			setvalue(so + "0x38720",32,"h 09 00 09 00")
			dofile('./emulator.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 2 then
			dofile('./norecoil.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 3 then
			dofile('./autohs.cfg')
			processor(lists[choices], 4, 0, 0, 0)
		elseif choices == 4 then
			dofile('./magic.cfg')
			processor(lists[choices], 1, 0, 0, 0)
			dofile('./magic-hook.lua')
			processor(lists[choices], 3, 0, 0, 0)
		elseif choices == 5 then
			dofile('./skill.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 6 then
			dofile('./bullets.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 7 then
			dofile('./crosshair.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 8 then
			dofile('./speed.cfg')
			processor(lists[choices], 5, 0, 0, 0)
		elseif choices == 9 then
			dofile('./autohs.cfg')
			processor(lists[choices], 4, 0, 0, 0)
			dofile('./skill.cfg')
			processor(lists[choices], 5, 0, 0, 0)
			dofile('./bullets.cfg')
			processor(lists[choices], 5, 0, 0, 0)
			dofile('./crosshair.cfg')
			processor(lists[choices], 5, 0, 0, 0)
			dofile('./speed.cfg')
			processor(lists[choices], 5, 0, 0, 0)
			dofile('./playerid.cfg')
			processor(lists[choices], 4, 0, 0, 0)
			dofile('./uid.cfg')
			processor(lists[choices], 4, 0, 0, 0)
		elseif choices == 10 then
			dofile('./experimental.lua')
			processor(lists[choices], 5, 0, 0, 0)
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
