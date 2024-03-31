require("Il2cppApi")
require("methods")

Il2cpp()

--declass0: unclasser(), declass1: unmethods(), declass2: unfields, declass3: none
--modes0: patch, modes1: memoize
--flags0: patch, flags1: reverts
--icon: game guardian floating icon state
cases = {current = "normal", memoize = {stores = {}, restores = {}}}

------------------------------
---[ FIELDS PROCESSOR ]
------------------------------
function field_patch(ill, field, knx)
	local objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for i = 1, #object do 
			if knx.patches[object[i].Access] then
				types = types(knx.patches[object[i].Access])
				values = knx.patches[object[i].Access][2]
			else
				types = types(knx.patches)
				values = knx.patches[2]
			end
			if types == 'str' then
				local str = Il2cpp.String.From(object[i].address + tonumber(field.Offset, 16))
				if str then
					str:EditString(values)
				end
			else
				local changes_field = {{
					address = objects[i].address + tonumber(field.Offset, 16),
					flags = types,
					value = values
				}}
				gg.setValues(changes_field)
			end
		end
	end
end

function field_memoize(ill, field, knx)
	cases.memoize.restores[cases.current]['fields'] = {}
	cases.memoize.stores[cases.current]['fields'] = {}
	local objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for i = 1, #object do 
			if knx.patches[object[i].Access] then
				types = types(knx.patches[object[i].Access])
				values = knx.patches[object[i].Access][2]
				original = knx.original[object[i].Access][2]
			else
				types = types(knx.patches)
				values = knx.patches[2]
				original = knx.original[2]
			end
			if knx.original == nil then
				cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
					address = object[i].address + tonumber(field.Offset, 16),
					value = gg.getValues({{address = object[i].address + tonumber(v.Offset, 16), flags = knx.flags}})[1].value,
					flags = types
				}
			else
				cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
					address = object[i].address + tonumber(field.Offset, 16),
					value = original,
					flags = types
				}
			end
			cases.memoize.stores[cases.current]['fields'][#cases.memoize.stores[cases.current]['fields'] + 1] = {
				address = object[i].address + tonumber(field.Offset, 16),
				value = values,
				flags = types
			}
		end
	end
	apply_memo()
end

function field_enum(ill, field, knx)
	local stores = {}
	local objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for i = 1, #object do 
			if types == 'str' then
				local il2cppstr = Il2cpp.String.From(object[i].address + tonumber(field.Offset, 16))
				if il2cppstr then
					for keys, value in ipairs(targets) do
						if il2cppstr:ReadString() == value then
							il2cppstr:EditString(knx.patches[2])
						end
					end
				end
			else
				stores[#stores + 1] = {
					address = object[i].address + tonumber(field.Offset, 16),
					flags = knx.patches[1],
					value = gg.getValues({{address = object[i].address + tonumber(field.Offset, 16), flags = knx.patches[1]}})[1].value
				}
			end
		end
	end
	if stores ~= nil and knx.patches[3] ~= nil then
		for k, v in ipairs(knx.patches[3]) do
			gg.loadResults(stores)
			gg.refineNumber(v, knx.patches[1])
			gg.getResults(gg.getResultsCount())
			gg.editAll(knx.patches[2], knx.patches[1])
			gg.clearResults()
		end
	end
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
		},
		{
			address = v + 0x4,
			value = '~A BX LR',
			flags = gg.TYPE_DWORD
		}}
		
		gg.setValues(change_method)
	end
end

------------------------------
---[ ENUMERATOR ]
------------------------------


------------------------------
---[ UNCLASSER ]
------------------------------
function unclasser(knx)
	unmethods(knx)
	unfields(knx)
end

function unfield(ill)
	for keys, value in ipairs(ill) do
		for key, val in ipairs(value) do
			local objects = Il2cpp.FindObject({tonumber(val.ClassAddress, 16)})
			for k, v in ipairs(val.Fields) do
				for m, object in ipairs(objects) do
					for i = 1, #object do 
						if v.Type == 'string' then
							local str = Il2cpp.String.From(object[i].address + tonumber(v.Offset, 16))
							if str then
								str:EditString('')
							end
						elseif v.Type == 'bool' then
								local changes_field = {{
									address = object[i].address + tonumber(v.Offset, 16),
									flags = gg.TYPE_BYTE,
									value = 0
								}}
								gg.setValues(changes_field)
						elseif v.Type == 'int' then
							local changes_field = {{
								address = object[i].address + tonumber(v.Offset, 16),
								flags = gg.TYPE_DWORD,
								value = 0
							}}
							gg.setValues(changes_field)
						elseif v.Type == 'float' then
							local changes_field = {{
								address = object[i].address + tonumber(v.Offset, 16),
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

------------------------------
---[ SCRIPT PROCESSOR ]
------------------------------
function processor()
	for keys, value in ipairs(knx) do
		if value.class then
			local classes = Il2cpp.FindClass(  {{Class = value.class, MethodsDump = true, FieldsDump = true}} )
			if value.fields then
				for key, val in ipairs(value.fields) then
					for k, v in ipairs(classes) do
						for g, h in ipairs(v) do
							for i, j in ipairs(h.Fields) do
								if j.FieldName == val.memoize then
									field_memoize(h, j, value)
								elseif j.FieldName == val.patch then
									field_patch(h, j, value)
								elseif j.FieldName == val.enum then
									field_enum(h, j, value)
								end
							end
						end
					end
				end
			end
			if value.methods then
				for key, val in ipairs(value.methods) then
					if val.auto then
						method_auto(classes, val)
					elseif val.hook then
						method_hook(classes, val)
					elseif val.hex then
						method_hex(classes, val)
					elseif val.return then
						method_return(classes, val)
					else
						method_patch(classes, val)
					end
				end
			end
		else
			if value.unfield then
				local classes = Il2cpp.FindClass(  {{Class = value.unfield, FieldsDump = true}} )
				unfield(classes)
			unclasser(value)
		end
	end
end

function types(knx)
	if knx[1].int64 or knx[1].long or knx[1].qword or knx[1].ulong or knx[1].['long int'] then
		return gg.TYPE_QWORD
	elseif knx[1].int or knx[1].int32 or knx[1].dword then
		return gg.TYPE_DWORD
	elseif knx[1].str or knx[1].string then
		return 'str'
	elseif knx[1].double then
		return gg.TYPE_DOUBLE
	elseif knx[1].bool then
		return gg.TYPE_BYTE
	else
		return gg.TYPE_FLOAT
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
	function anticheats()
		lists = {"AntiCheat", "Emulator", "Spoofer", "Spoofer Runtime", "Download", "Menus"}
		local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
		if choices == nil then
			cases.flags.icon = false
			gg.setVisible(false)
		else
			cases.flags.icon = false
			gg.setVisible(false)
			if choices == 1 then
				dofile('./magic.cfg')
				processor(lists[choices], 1, 0, 0, 0)
				dofile('./magic-hook.cfg')
				processor(lists[choices], 3, 0, 0, 0)
			elseif choices == 2 then
				so = gg.getRangesList('libanogs.so')[1].start
				setvalue(so + "0x129fc4",32,"h 00 20 70 47")
				setvalue(so + "0x12a8d0",32,"h 00 20 70 47")
				setvalue(so + "0x72326",32,"h 00 20 70 47")
				setvalue(so + "0x90734",32,"h 00 20")
				setvalue(so + "0xba9e0",32,"h 00 20 70 47")
				setvalue(so + "0x12bf96",32,"h 00 20 70 47")
				setvalue(so + "0x3e6f0",32,"h 09 00 09 00")
				setvalue(so + "0x3e6fe",32,"h 09 00 09 00")
				dofile('./emulator.lua')
				processor(lists[choices], 5, 0, 0, 0)
				dofile('./emulator-hook.lua')
				processor(lists[choices], 0, 0, 0, 0)
			elseif choices == 3 then
				dofile('./ids.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 4 then
				dofile('./ids-runtime.cfg')
				processor(lists[choices], 4, 0, 0, 0)
			elseif choices == 5 then
				dofile('./download.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			else
				main()
			end
		end
	end
	
	function speeds()
		lists = {"Run Speed", "Walk Speed", "Crouch Speed", "Prone Speed", "Snake Speed", "Overall Speed", "Fly Speed", "Instant Land", "Fast Loot"}
		local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
		if choices == nil then
			cases.flags.icon = false
			gg.setVisible(false)
		else
			if choices == 1 then
				dofile('./speed-run.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 2 then
				dofile('./speed-walk.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 3 then
				dofile('./speed-crouch.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 4 then
				dofile('./speed-prone.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 5 then
				dofile('./speed-snake.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 6 then
				dofile('./speed-overall.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 7 then
				dofile('./speed-fly.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 8 then
				dofile('./speed-land.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			else
				dofile('./fast-loot.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			end
		end
	end

	function glider()
		lists = {"Flyable", "Fly Stay", "Fly Hack", "Menus"}
		local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
		if choices == nil then
			cases.flags.icon = false
			gg.setVisible(false)
		else
			if choices == 1 then
				dofile('./glider-free.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 2 then
				dofile('./glider-stay.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 3 then
				dofile('./glider-up.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			else
				main()
			end
		end
	end
	
	function cheats()
		lists = {"Recoil", "HeadShot", "Skill", "Rapid Fire", "Crosshair", "Passive Bot", "Combine", "Menus"}
		local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
		if choices == nil then
			cases.flags.icon = false
			gg.setVisible(false)
		else
			if choices == 1 then
				dofile('./norecoil.cfg')
				processor(lists[choices], 5, 0, 0, 0)
				HackersHouse.hijackParameters({
					{
						['libName'] = "libil2cpp",
						['offset'] = 0x31212b0,
						['parameters'] ={{"bool", true}}, 
						['libIndex'] = 'auto'
					},
					{
						['libName'] = "libil2cpp",
						['offset'] = 0x78ea5352b0,
						['parameters'] = {{"bool", true}}, 
						['libIndex'] = 'auto'
					}
				})
			elseif choices == 2 then
				dofile('./autohs.cfg')
				processor(lists[choices], 4, 0, 0, 0)
			elseif choices == 3 then
				dofile('./skill.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 4 then
				dofile('./bullets.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 5 then
				dofile('./crosshair.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 6 then
				dofile('./passive.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			elseif choices == 7 then
				dofile('./autohs.cfg')
				processor(lists[choices], 4, 0, 0, 0)
				dofile('./skill.cfg')
				processor(lists[choices], 5, 0, 0, 0)
				dofile('./bullets.cfg')
				processor(lists[choices], 5, 0, 0, 0)
				dofile('./speed-overall.cfg')
				processor(lists[choices], 5, 0, 0, 0)
			else
				main()
			end
		end
	end

	function main()
		lists = {"Cheats", "Speeds", "Glider", "AntiCheat", "Experimental", "❌EXIT❌"}
		local choices = gg.choice(lists, nil, "State: " .. tostring(cases.flags.flags))
		if choices == nil then
			cases.flags.icon = false
			gg.setVisible(false)
		else
			cases.flags.icon = false
			gg.setVisible(false)
			if choices == 1 then
				--current, unclass, mode, flag, reset
				cheats()
			elseif choices == 2 then
				speeds()
			elseif choices == 3 then
				glider()
			elseif choices == 4 then
				anticheats()
			elseif choices == 5 then
				dofile('./experimental.lua')
				processor(lists[choices], 5, 0, 0, 0)
			else
				os.exit()
			end
		end
	end

	main()
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
