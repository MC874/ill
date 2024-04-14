require("Il2cppApi")
require("hh")
require("extr")

Il2cpp()

--declass0: unclasser(), declass1: unmethods(), declass2: unfields, declass3: none
--modes0: patch, modes1: memoize
--flags0: patch, flags1: reverts
--icon: game guardian floating icon state
cases = {current = "normal", memoize = {stores = {}, restores = {}}, flags = {['icon'] = false}}

------------------------------
---[ FIELDS PROCESSOR ]
------------------------------
function field_patch(ill, field, knx)
	if knx.patches[field.Access] ~= nil then
		valtype = types(knx.patches[field.Access][1])
		values = knx.patches[field.Access][2]
	else
		valtype = types(knx.patches[1])
		values = knx.patches[2]
	end
	local objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for i = 1, #object do
			if valtype == 'str' then
				local str = Il2cpp.String.From(object[i].address + tonumber(field.Offset, 16))
				if str then
					str:EditString(values)
				end
			else
				local changes_field = {{
					address = object[i].address + tonumber(field.Offset, 16),
					flags = valtype,
					value = values
				}}
				gg.setValues(changes_field)
			end
		end
	end
end

function field_memoize(ill, field, knx)
	if knx.patches[field.Access] ~= nil then
		valtype = types(knx.patches[field.Access][1])
		values = knx.patches[field.Access][2]
		original = knx.patches[field.Access][3]
	else
		valtype = types(knx.patches[1])
		values = knx.patches[2]
		original = knx.patches[3]
	end
	if cases.memoize.stores[cases.current] == nil then
		cases.memoize.stores[cases.current] = {}
		cases.memoize.restores[cases.current] = {}
		cases.memoize.restores[cases.current]['fields'] = {}
		cases.memoize.stores[cases.current]['fields'] = {}
	end
	local objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for i = 1, #object do 
			if original == nil then
				cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
					address = object[i].address + tonumber(field.Offset, 16),
					value = gg.getValues({{address = object[i].address + tonumber(field.Offset, 16), flags = valtype}})[1].value,
					flags = valtype
				}
			else
				cases.memoize.restores[cases.current]['fields'][#cases.memoize.restores[cases.current]['fields'] + 1] = {
					address = object[i].address + tonumber(field.Offset, 16),
					value = original,
					flags = valtype
				}
			end
			cases.memoize.stores[cases.current]['fields'][#cases.memoize.stores[cases.current]['fields'] + 1] = {
				address = object[i].address + tonumber(field.Offset, 16),
				value = values,
				flags = valtype
			}
		end
	end
	memoize_apply()
end

function field_enum(ill, field, knx)
	if knx.patches[field.Access] ~= nil then
		valtype = types(knx.patches[field.Access][1])
		values = knx.patches[field.Access][2]
		targets = knx.patches[field.Access[3]]
	else
		valtype = types(knx.patches[1])
		values = knx.patches[2]
		targets = knx.patches[3]
	end
	stores = {}
	objects = Il2cpp.FindObject({tonumber(ill.ClassAddress, 16)})
	for m, object in ipairs(objects) do
		for m, object in ipairs(object) do
			if valtype == 'str' then
				local il2cppstr = Il2cpp.String.From(object.address + tonumber(field.Offset, 16))
				if il2cppstr then
					for keys, value in ipairs(targets) do
						if il2cppstr:ReadString() == value then
							il2cppstr:EditString(values)
						end
					end
				end
			else
				stores[#stores + 1] = {
					address = object.address + tonumber(field.Offset, 16),
					flags = valtype,
					value = gg.getValues({{address = object.address + tonumber(field.Offset, 16), flags = valtype}})[1].value
				}
			end
		end
	end
	if stores ~= nil then
		for k, v in ipairs(targets) do
			gg.loadResults(stores)
			gg.refineNumber(v, valtype)
			gg.getResults(gg.getResultsCount())
			gg.editAll(values, valtype)
			gg.clearResults()
		end
	end
end

------------------------------
---[ METHODS PROCESSOR ]
------------------------------
function method_hex(ill, knx)
	for keys, value in ipairs(ill.Methods) do
		if value.MethodName == knx.hex then
			if type(knx.patches) == 'table' then
				values = knx.patches[value.Access]
				if knx.offset then
					offset = knx.offset[value.Access]
				end
			else
				values = knx.patches
				if knx.offset then
					offset = knx.offset
				end
			end
			if offset then
				Il2cpp.PatchesAddress(tonumber(value.AddressInMemory, 16) + tonumber(offset, 16), values)
			else
				Il2cpp.PatchesAddress(tonumber(value.AddressInMemory, 16), values)
			end
		end
	end
end

function method_return(ill, knx)
	for keys, value in ipairs(ill.Methods) do
		if value.MethodName == knx['return'] then
			if type(knx.patches[1]) == 'table' then
				valtype = knx.patches[value.Access][1]
				values = knx.patches[value.Access][2]
			else
				valtype = knx.patches[1]
				values = knx.patches[2]
			end
			if valtypes == 'float' then
				if tonumber(values) * 1.0 < 65535 then
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #' .. tostring(values),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'VCVT.F32.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				elseif tonumber(values) * 1.0 > 65535 and tonumber(values) * 1.0 < 131072 then
					arithmeth = tonumber(values) * 1.0 - 65535
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'MOVW R1, #' .. tostring(arithmeth),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'ADD R0, R0, R1',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'VCVT.F32.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x14,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x18,
						value = 'BX LR',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				elseif tonumber(values) * 1.0 > 131072 and tonumber(values) * 1.0 < 429503284 then
					arithmeth = tonumber(values) * 1.0 - 131072
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'MOVW R1, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'MUL R0, R0, R11',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'MOVW R1, #' .. tostring(arithmeth),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'ADD R0, R0, R1',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x14,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x18,
						value = 'VCVT.F32.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x1c,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x20,
						value = 'BX LR',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				end
			elseif valtypes == 'double' then
				if tonumber(values) * 1.0 < 65535 then
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #' .. tostring(values),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'VCVT.F64.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				elseif tonumber(values) * 1.0 > 65535 and tonumber(values) * 1.0 < 131072 then
					arithmeth = tonumber(values) * 1.0 - 65535
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'MOVW R1, #' .. tostring(arithmeth),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'ADD R0, R0, R1',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'VCVT.F64.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x14,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x18,
						value = 'BX LR',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				elseif tonumber(values) * 1.0 > 131072 and tonumber(values) * 1.0 < 429503284 then
					arithmeth = tonumber(values) * 1.0 - 131072
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'MOVW R1, #65535',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x8,
						value = 'MUL R0, R0, R11',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0xc,
						value = 'MOVW R1, #' .. tostring(arithmeth),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x10,
						value = 'ADD R0, R0, R1',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x14,
						value = 'VMOV S0, R0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x18,
						value = 'VCVT.F64.S32 S0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x1c,
						value = 'VMOV R0, S0',
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x20,
						value = 'BX LR',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				end
			elseif valtypes == 'int' then
				if tonumber(values) * 1.0 < 65535 then
					changes = {
					{
						address = tonumber(value.AddressInMemory, 16),
						value = 'MOVW R0, #' .. tostring(values),
						flags = gg.TYPE_DWORD
					},
					{
						address = tonumber(value.AddressInMemory, 16) + 0x4,
						value = 'BX LR',
						flags = gg.TYPE_DWORD
					}}
					gg.setValues(changes)
				end
			elseif valtypes == 'bool' then
				if values then
					values = 1
				else
					values = 0
				end
				changes = {
				{
					address = tonumber(value.AddressInMemory, 16),
					value = 'MOVW R0, #' .. tostring(values),
					flags = gg.TYPE_DWORD
				},
				{
					address = tonumber(value.AddressInMemory, 16) + 0x4,
					value = 'BX LR',
					flags = gg.TYPE_DWORD
				}}
				gg.setValues(changes)
			end
		end
	end
end

function method_memoize(ill, knx)
	if cases.memoize.stores[cases.current] == nil then
		cases.memoize.stores[cases.current] = {}
		cases.memoize.restores[cases.current] = {}
		cases.memoize.restores[cases.current]['methods'] = {}
		cases.memoize.stores[cases.current]['methods'] = {}
	end
	for key, val in ipairs(ill.Methods) do
		if val.MethodName == knx.memoize then
			if type(knx.patches[1]) == 'table' then
				offset = knx.patches[val.Access][1]
				values = knx.patches[val.Access][2]
				original = knx.patches[val.Access][3]
			else
				offset = knx.patches[1]
				values = knx.patches[2]
				original = knx.patches[3]
			end
			if original == nil then
				local strings, occurence = values:gsub('\\x', '')
				local buffers = #strings / 2
				if offset then
					cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
						address = tonumber(val.AddressInMemory, 16) + tonumber(offset, 16),
						value = const(tonumber(val.AddressInMemory, 16), buffers)
					}
				else
					cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
						address = tonumber(val.AddressInMemory, 16),
						value = const(tonumber(val.AddressInMemory, 16), buffers)
					}
				end
			else
				if offset then
					cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
						address = tonumber(val.AddressInMemory, 16) + tonumber(offset, 16),
						value = original
					}
				else
					cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
						address = tonumber(val.AddressInMemory, 16),
						value = original
					}
				end
			end
			cases.memoize.restores[cases.current]['methods'][#cases.memoize.restores[cases.current]['methods'] + 1] = {
				address = tonumber(val.AddressInMemory, 16),
				value = values
			}
		end
	end
	memoize_apply()
end

function method_hook(ill, knx)
	local target = {}
	local jump = ''
	for keys, value in ipairs(ill.Methods) do
		if type(knx.hook[1]) == 'table' then
			targets = knx.hook[value.Access][1]
			ends = knx.hook[value.Access][2]
		else
			targets = knx.hook[1]
			ends = knx.hook[2]
		end
		if value.MethodName == ends then
			jump = "0x" .. tostring(value.AddressInMemory)
		end
		if type(targets) == 'table' then
			for key, val in ipairs(targets) do
				if value.MethodName == val then
					target[#target + 1] = '0x' .. tostring(value.AddressInMemory)
				end
			end
		else
			if value.MethodName == targets then
				target[#target + 1] = '0x' .. tostring(value.AddressInMemory)
			end
		end
	end
	if target and jump then
		hook_method(target, jump)
	end
end

function hook_method(target, jump)
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
---[ UNCLASSER ]
------------------------------
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

function unmethod(ill)
	for keys, value in ipairs(ill) do
		for key, val in ipairs(value) do
			if val.Methods == nil then
				break
			end
			for k, v in ipairs(val.Methods) do
				if v.Type == "bool" or value.Type == 'int' then
					Il2cpp.PatchesAddress(tonumber(v.AddressInMemory, 16), "\x00\x00\x00\xE3\x1E\xFF\x2F\xE1")
				elseif v.Type == "float" then
					Il2cpp.PatchesAddress(tonumber(v.AddressInMemory, 16), "\x00\x00\x00\xE3\x10\x0A\x00\xEE\xC0\x0A\xB8\xEE\x10\x0A\x10\xEE\x1E\xFF\x2F\xE1")
				else
					Il2cpp.PatchesAddress(tonumber(v.AddressInMemory, 16), "\x00\x00\xA0\xE1\x1E\xFF\x2F\xE1")
				end
			end
		end
	end
end

------------------------------
---[ Hacker House Method Patching Library ]
------------------------------

function methode(ill)
	if ill.voidHook then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['voidHook'] = {}
			cases.memoize.restores[cases.current]['voidHook'] = {}
		end
		cases.memoize.stores[cases.current]['voidHook'][#cases.memoize.stores[cases.current]['voidHook'] + 1] = ill.voidHook
		cases.memoize.restores[cases.current]['voidHook'][#cases.memoize.restores[cases.current]['voidHook'] + 1] = ill.voidHook
		HackersHouse.voidHook(ill.voidHook)
	elseif ill.hijackParameters then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['hijackParameters'] = {}
			cases.memoize.restores[cases.current]['hijackParameters'] = {}
		end
		cases.memoize.stores[cases.current]['hijackParameters'][#cases.memoize.stores[cases.current]['hijackParameters'] + 1] = ill.hijackParameters
		cases.memoize.restores[cases.current]['hijackParameters'][#cases.memoize.restores[cases.current]['hijackParameters'] + 1] = ill.hijackParameters
		HackersHouse.hijackParameters(ill.hijackParameters)
	elseif ill.disableMethod then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['disableMethod'] = {}
			cases.memoize.restores[cases.current]['disableMethod'] = {}
		end
		cases.memoize.stores[cases.current]['disableMethod'][#cases.memoize.stores[cases.current]['disableMethod'] + 1] = ill.disableMethod
		cases.memoize.restores[cases.current]['disableMethod'][#cases.memoize.restores[cases.current]['disableMethod'] + 1] = ill.disableMethod
		HackersHouse.disableMethod(ill.disableMethod)
	elseif ill.returnValue then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['returnValue'] = {}
			cases.memoize.restores[cases.current]['returnValue'] = {}
		end
		cases.memoize.stores[cases.current]['returnValue'][#cases.memoize.stores[cases.current]['returnValue'] + 1] = ill.returnValue
		cases.memoize.restores[cases.current]['returnValue'][#cases.memoize.restores[cases.current]['returnValue'] + 1] = ill.returnValue
		HackersHouse.returnValue(ill.returnValue)
	elseif ill.callAnotherMethod then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['callAnotherMethod'] = {}
			cases.memoize.restores[cases.current]['callAnotherMethod'] = {}
		end
		cases.memoize.stores[cases.current]['callAnotherMethod'][#cases.memoize.stores[cases.current]['callAnotherMethod'] + 1] = ill.callAnotherMethod
		cases.memoize.restores[cases.current]['callAnotherMethod'][#cases.memoize.restores[cases.current]['callAnotherMethod'] + 1] = ill.callAnotherMethod
		HackersHouse.callAnotherMethod(ill.callAnotherMethod)
	elseif ill.hexPatch then
		if cases.memoize.stores[cases.current] == nil then
			cases.memoize.stores[cases.current] = {}
			cases.memoize.restores[cases.current] = {}
			cases.memoize.stores[cases.current]['hexPatch'] = {}
			cases.memoize.restores[cases.current]['hexPatch'] = {}
		end
		cases.memoize.stores[cases.current]['hexPatch'][#cases.memoize.stores[cases.current]['hexPatch'] + 1] = ill.hexPatch
		cases.memoize.restores[cases.current]['hexPatch'][#cases.memoize.restores[cases.current]['hexPatch'] + 1] = ill.hexPatch
		HackersHouse.hexPatch(ill.hexPatch)
	end
end

------------------------------
---[ SCRIPT PROCESSOR ]
------------------------------
function processor(knx, choice)
	cases.current = choice
	if cases.memoize.stores[cases.current] then
		flags = screens()
		if flags then
			return
		end
	end
	for keys, value in ipairs(knx) do
		if value.class then
			classes = Il2cpp.FindClass(  {{Class = value.class, MethodsDump = true, FieldsDump = true}} )
			if value.fields then
				for key, val in ipairs(value.fields) do
					for k, v in ipairs(classes) do
						for g, h in ipairs(v) do
							if h.Fields == nil then
								break
							end
							for i, j in ipairs(h.Fields) do
								if j.FieldName == val.memoize then
									field_memoize(h, j, val)
								elseif j.FieldName == val.patch then
									field_patch(h, j, val)
								elseif j.FieldName == val.enum then
									field_enum(h, j, val)
								end
							end
						end
					end
				end
			end
			if value.methods then
				for key, val in ipairs(value.methods) do
					for k, v in ipairs(classes) do
						for g, h in ipairs(v) do
							if not h.Methods then
								break
							end
							if val.hook then
								method_hook(h, val)
							elseif val.hex then
								method_hex(h, val)
							elseif val['return'] then
								method_return(h, val)
							elseif val.patch then
								method_patch(h, val)
							elseif val.memoize then
								method_memoize(h, val)
							end
						end
					end
				end
			end
		elseif value.unclass then
			classes = Il2cpp.FindClass(  {{Class = value.unclass, MethodsDump = true, FieldsDump = true}} )
			unfield(classes)
			unmethod(classes)
		elseif value.unfield then
			unfield(Il2cpp.FindClass(  {{Class = value.unfield, MethodsDump = true, FieldsDump = true}} ))
		elseif value.unmethod then
			unmethod(Il2cpp.FindClass(  {{Class = value.unmethod, MethodsDump = true, FieldsDump = true}} ))
		elseif value.methode then
			methode(value.methode)
		end
	end
end

function memoize_apply()
	if cases.memoize.stores[cases.current]['methods'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['methods']) do
			Il2cpp.PatchesAddress(value.address, value.value)
		end
	end
	if cases.memoize.stores[cases.current]['fields'] ~= nil then
		gg.setValues(cases.memoize.stores[cases.current]['fields'])
	end
	if cases.memoize.stores[cases.current]['voidHook'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['voidHook']) do
			HackersHouse.voidHook(value)
		end
	end
	if cases.memoize.stores[cases.current]['voidHook'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['voidHook']) do
			HackersHouse.voidHook(value)
		end
	end
	if cases.memoize.stores[cases.current]['hijackParameters'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['hijackParameters']) do
			HackersHouse.hijackParameters(value)
		end
	end
	if cases.memoize.stores[cases.current]['disableMethod'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['disableMethod']) do
			HackersHouse.disableMethod(value)
		end
	end
	if cases.memoize.stores[cases.current]['returnValue'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['returnValue']) do
			HackersHouse.returnValue(value)
		end
	end
	if cases.memoize.stores[cases.current]['callAnotherMethod'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['callAnotherMethod']) do
			HackersHouse.callAnotherMethod(value)
		end
	end
	if cases.memoize.stores[cases.current]['hexPatch'] ~= nil then
		for key, value in ipairs(cases.memoize.stores[cases.current]['hexPatch']) do
			HackersHouse.hexPatch(value)
		end
	end
end

function memoize_revert()
	if cases.memoize.restores[cases.current]['methods'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['methods']) do
			Il2cpp.PatchesAddress(value.address, value.value)
		end
	end
	if cases.memoize.restores[cases.current]['fields'] ~= nil then
		gg.setValues(cases.memoize.restores[cases.current]['fields'])
	end
	if cases.memoize.restores[cases.current]['voidHook'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['voidHook']) do
			HackersHouse.voidHook(value)
		end
	end
	if cases.memoize.restores[cases.current]['voidHook'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['voidHook']) do
			HackersHouse.voidHook(value)
		end
	end
	if cases.memoize.restores[cases.current]['hijackParameters'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['hijackParameters']) do
			HackersHouse.hijackParameters(value)
		end
	end
	if cases.memoize.restores[cases.current]['disableMethod'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['disableMethod']) do
			HackersHouse.disableMethod(value)
		end
	end
	if cases.memoize.restores[cases.current]['returnValue'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['returnValue']) do
			HackersHouse.returnValue(value)
		end
	end
	if cases.memoize.restores[cases.current]['callAnotherMethod'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['callAnotherMethod']) do
			HackersHouse.callAnotherMethod(value)
		end
	end
	if cases.memoize.restores[cases.current]['hexPatch'] ~= nil then
		for key, value in ipairs(cases.memoize.restores[cases.current]['hexPatch']) do
			HackersHouse.hexPatch(value)
		end
	end
end

function screens()
	lists = { cases.current .. ' On', cases.current .. ' Off', cases.current .. ' Reset', 'Exit'}
	local choices = gg.choice(lists, nil, nil)
	if choices == nil then
		cases.flags.icon = false
		gg.setVisible(false)
		return
	else
		cases.flags.icon = false
		gg.setVisible(false)
		if choices == 1 then
			memoize_apply()
			return true
		elseif choices == 2 then
			memoize_revert()
			return true
		elseif choices == 3 then
			cases.memoize.stores[cases.current] = nil
			cases.memoize.restores[cases.current] = nil
			return false
		else
			return true
		end
	end
end

function types(knx)
	if knx == 'int64' or knx == 'long' or knx == 'qword' or knx == 'ulong' or knx == 'long int' then
		return gg.TYPE_QWORD
	elseif knx == 'int' or knx == 'int32' or knx == 'dword' then
		return gg.TYPE_DWORD
	elseif knx == 'str' or knx == 'string' then
		return 'str'
	elseif knx == 'double' then
		return gg.TYPE_DOUBLE
	elseif knx == 'bool' then
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