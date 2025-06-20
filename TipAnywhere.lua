-- ============================================================= --
-- TIP ANYWHERE MOD - loki_79
-- ============================================================= --
TipAnywhere = {}
addModEventListener(TipAnywhere)

TipAnywhere.CONTROLS = {}
TipAnywhere.tip = true
TipAnywhere.shovel = true
TipAnywhere.workAreas = {
	['BALER'] = true,
	['COMBINECHOPPER'] = false,
	['COMBINESWATH'] = false,
	['CULTIVATOR'] = false,
	['CUTTER'] = false,
	['FORAGEWAGON'] = true,
	['FRUITPREPARER'] = false,
	['MULCHER'] = false,
	['MOWER'] = false,
	['PLOW'] = false,
	['RIDGEMARKER'] = false,
	['ROLLER'] = false,
	['SALTSPREADER'] = false,
	['SOWINGMACHINE'] = false,
	['SPRAYER'] = false,
	['STONEPICKER'] = false,
	['STUMPCUTTER'] = false,
	['TEDDER'] = true,
	['WEEDER'] = false,
	['WINDROWER'] = true,
	['DEFAULT'] = false,
	['AUXILIARY'] = false,
	['HAULMDROP'] = false,
	['PLOWSHARE'] = false,
	['RIDGEFORMER'] = false,
}
TipAnywhere.menuItems = {
	[1] = 'BALER',
	[2] = 'FORAGEWAGON',
	[3] = 'TEDDER',
	[4] = 'WINDROWER',
	[5] = 'MOWER',
	[6] = 'COMBINECHOPPER',
	[7] = 'COMBINESWATH',
}

TipAnywhere.OPTION = {
	['default'] = 1,
	['values'] = {false, true},
	['strings'] = {
		g_i18n:getText("ui_off"),
		g_i18n:getText("ui_on")
	}
}


-- HELPER FUNCTIONS
local inGameMenu = g_gui.screenControllers[InGameMenu]
local settingsPage = inGameMenu.pageSettings
local settingsLayout = settingsPage.gameSettingsLayout

TipAnywhereControls = {}
TipAnywhereControls.name = settingsPage.name

function TipAnywhere.setValue(id, value)
	TipAnywhere.workAreas[id] = value
end

function TipAnywhere.getValue(id)
	return TipAnywhere.workAreas[id] or false
end

function TipAnywhere.getStateIndex(id)
	local value = TipAnywhere.getValue(id)
	local values = TipAnywhere.OPTION.values
	for i, v in pairs(values) do
		if value == v then
			return i
		end 
	end
	return TipAnywhere.OPTION.default
end

function TipAnywhere.addMenuOption(id, original)
	
	local function updateFocusIds(element)
		if not element then
			return
		end
		element.focusId = FocusManager:serveAutoFocusId()
		for _, child in pairs(element.elements) do
			updateFocusIds(child)
		end
	end
	
	local original = original or settingsPage.checkWoodHarvesterAutoCutBox
	local options = TipAnywhere.OPTION.strings
	local callback = "onMenuOptionChanged"

	local menuOptionBox = original:clone(settingsLayout)
	if not menuOptionBox then
		print("could not create menu option box")
		return
	end
	menuOptionBox.id = id .. "box"
	
	local menuOption = menuOptionBox.elements[1]
	if not menuOption then
		print("could not create menu option")
		return
	end
	
	menuOption.id = id
	menuOption.target = TipAnywhereControls

	menuOption:setCallback("onClickCallback", callback)
	menuOption:setDisabled(false)

	local toolTip = menuOption.elements[1]
	toolTip:setText(g_i18n:getText("tooltip_tipanywhere_" .. id))

	local setting = menuOptionBox.elements[2]
	setting:setText(g_i18n:getText("setting_tipanywhere_" .. id))
	
	menuOption:setTexts({unpack(options)})
	menuOption:setState(TipAnywhere.getStateIndex(id))
	
	TipAnywhere.CONTROLS[id] = menuOption
	
	-- Assign new focus IDs to the controls as clone() copies the existing ones which are supposed to be unique
	updateFocusIds(menuOptionBox)
	table.insert(settingsPage.controlsList, menuOptionBox)

	return menuOption
end

function TipAnywhere.insertMenuItem(id)

	local function tableContainsValue(container, id)
		for k, v in pairs(container) do
			if v == id then
				return true
			end
		end
		return false
	end
	
	if not tableContainsValue(TipAnywhere.menuItems, id) then
		--print("INSERTING MENU ITEM: " .. id)
		table.insert(TipAnywhere.menuItems, id)
		TipAnywhere.addMenuOption(id)
		settingsLayout:invalidateLayout()
	end
end

-- MENU CALLBACK
function TipAnywhereControls.onMenuOptionChanged(self, state, menuOption)
	
	local id = menuOption.id
	local value = TipAnywhere.OPTION.values[state]
	
	if value ~= nil then
		print("SET " .. id .. " = " .. tostring(value))
		TipAnywhere.setValue(id, value)
		ToggleSettingEvent.sendEvent(id, value)
	end

	TipAnywhere.writeSettings()
end

local sectionTitle = nil
for idx, elem in ipairs(settingsLayout.elements) do
	if elem.name == "sectionHeader" then
		sectionTitle = elem:clone(settingsLayout)
		break
	end
end
if sectionTitle then
	sectionTitle:setText(g_i18n:getText("menu_TipAnywhere_TITLE"))
else
	local title = TextElement.new()
	title:applyProfile("fs25_settingsSectionHeader", true)
	title:setText(g_i18n:getText("menu_TipAnywhere_TITLE"))
	title.name = "sectionHeader"
	settingsLayout:addElement(title)
end

sectionTitle.focusId = FocusManager:serveAutoFocusId()
table.insert(settingsPage.controlsList, sectionTitle)
TipAnywhere.CONTROLS[sectionTitle.name] = sectionTitle



for _, id in pairs(TipAnywhere.menuItems) do
	TipAnywhere.addMenuOption(id)
end
settingsLayout:invalidateLayout()


-- READ/WRITE SETTINGS
function TipAnywhere.writeSettings()

	local key = "TipAnywhere"
	local userSettingsFile = Utils.getFilename("modSettings/TipAnywhere.xml", getUserProfileAppPath())
	
	local xmlFile = createXMLFile("settings", userSettingsFile, key)
	if xmlFile ~= 0 then
	
		local function setXmlValue(id)
			local options = TipAnywhere.OPTION
			if options then
				local xmlValueKey = "TipAnywhere." .. id .. "#value"
				local value = TipAnywhere.getValue(id)
				setXMLBool(xmlFile, xmlValueKey, value)
			end
		end
		
		for _, id in pairs(TipAnywhere.menuItems) do
			setXmlValue(id)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end
end

function TipAnywhere.readSettings()

	local userSettingsFile = Utils.getFilename("modSettings/TipAnywhere.xml", getUserProfileAppPath())
	
	if not fileExists(userSettingsFile) then
		print("CREATING user settings file: "..userSettingsFile)
		TipAnywhere.writeSettings()
		return
	end
	
	local xmlFile = loadXMLFile("TipAnywhere", userSettingsFile)
	if xmlFile ~= 0 then
	
		local function getXmlValue(id)
			local options = TipAnywhere.OPTION
			if options then
				local xmlSettingKey = "TipAnywhere." .. id
				local value = getXMLBool(xmlFile, xmlSettingKey .. "#value") or false
				TipAnywhere.setValue(id, value)
				
				if g_currentMission:getIsServer() and hasXMLProperty(xmlFile, xmlSettingKey) then
					TipAnywhere.insertMenuItem(id)
					return true
				end
			end
		end
		
		print("TIP ANYWHERE SETTINGS")
		print("  TIP:    " .. tostring(TipAnywhere.tip))
		print("  SHOVEL: " .. tostring(TipAnywhere.shovel))
		for id, _ in pairs(TipAnywhere.workAreas) do
			if getXmlValue(id) then
				print("  ".. id ..":  " .. tostring(TipAnywhere.workAreas[id]))
			end
		end

		delete(xmlFile)
	end
	
end

-- DETECT PLACEABLES FROM TIPPING CALLBACK
function TipAnywhere:tipLocationCallback(hitObjectId, x, y, z, distance)

	if hitObjectId ~= 0 and hitObjectId ~= nil then
		if getHasClassId(hitObjectId, ClassIds.SHAPE) then
			if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
			
				local object = g_currentMission:getNodeObject(hitObjectId)
				if object and object:isa(Placeable) then
					local storeItem = g_storeManager:getItemByXMLFilename(object.configFileName)
					if storeItem and storeItem.categoryName == 'SILOS' then
						TipAnywhere.tipToSilo = true
					end
				end
				
			end
		end
	end
end

-- GAME FUNCTIONS
function TipAnywhere:shovelGetCanShovelAtPosition(superFunc, shovelNode)
	if shovelNode == nil then
		return false
	end
	return TipAnywhere.shovel
end

function TipAnywhere:dischargeableGetCanDischargeToLand(superFunc, dischargeNode)
	if dischargeNode == nil then
		return false
	end

	if g_densityMapHeightManager.tipCollisionMap ~= nil then

		local d = 5
		local info = dischargeNode.info
		local x, y, z = getWorldTranslation(info.node)
		TipAnywhere.tipToSilo = false
		
		if TipAnywhere.tip then
			local collisionMask = CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
			local hitCount = overlapBox(x, y-d, z, 0, 0, 0, d, d, d, "tipLocationCallback", TipAnywhere, collisionMask, true, true, true, true)
			-- DebugUtil.drawOverlapBox(x, y-d, z, 0, 0, 0, d, d, d)
		end
		
		if TipAnywhere.tip and not TipAnywhere.tipToSilo then
			g_densityMapHeightManager.tipCollisionMask = CollisionFlag.PLAYER
		else
			g_densityMapHeightManager.tipCollisionMask = CollisionFlag.GROUND_TIP_BLOCKING
		end
		
		g_densityMapHeightManager:updateCollisionMap(x-d, z-d, x+d, z+d)
		
	end
		
	return TipAnywhere.tip
end

function TipAnywhere:WorkAreaGetIsAccessibleAtWorldPosition(superFunc, farmId, x, z, workAreaType)

	local isAccessible, farmlandOwner, buyable = superFunc(self, farmId, x, z, workAreaType)
	
	local workAreaName = g_workAreaTypeManager:getWorkAreaTypeNameByIndex(workAreaType)
	-- print("workAreaName: " .. workAreaName)
	if TipAnywhere.workAreas[workAreaName] then
		isAccessible = true
	end
	
	return isAccessible, farmlandOwner, buyable
end

MissionManager.getIsMissionWorkAllowed = Utils.overwrittenFunction(MissionManager.getIsMissionWorkAllowed,
function(self, superFunc, farmId, x, z, workAreaType)

	local isAccessible = superFunc(self, farmId, x, z, workAreaType)

	local mission = self:getMissionAtWorldPosition(x, z)
	if mission ~= nil and mission.farmId == farmId then
		local workAreaName = g_workAreaTypeManager:getWorkAreaTypeNameByIndex(workAreaType)
		if TipAnywhere.workAreas[workAreaName] then
			isAccessible = true
		end
	end
	
	return isAccessible
end)

function TipAnywhere.registerTipAnywhereFunctions()
	for vehicleName, vehicleType in pairs(g_vehicleTypeManager.types) do
		if SpecializationUtil.hasSpecialization(Shovel, vehicleType.specializations) then
			SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanShovelAtPosition", TipAnywhere.shovelGetCanShovelAtPosition)
			-- print("Shovel Anywhere added to " .. vehicleName)
		end
		if SpecializationUtil.hasSpecialization(Dischargeable, vehicleType.specializations) then
			SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToLand", TipAnywhere.dischargeableGetCanDischargeToLand)
			-- print("Tip Anywhere added to " .. vehicleName)
		end
		if SpecializationUtil.hasSpecialization(WorkArea, vehicleType.specializations) then
			SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAccessibleAtWorldPosition", TipAnywhere.WorkAreaGetIsAccessibleAtWorldPosition)
			-- print("Work Anywhere ADDED to " .. vehicleName)
		end
	end
end

function TipAnywhere:loadMap(name)
	--print("Loaded Mod: 'TIP ANYWHERE'")
	TipAnywhere.readSettings()
	TipAnywhere.registerTipAnywhereFunctions()
end

InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
	
	local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser
	
	for _, id in pairs(TipAnywhere.menuItems) do
	
		local menuOption = TipAnywhere.CONTROLS[id]
		menuOption:setState(TipAnywhere.getStateIndex(id))
	
		menuOption:setDisabled(not isAdmin)

	end
end)

-- Allow keyboard navigation of menu options
FocusManager.setGui = Utils.appendedFunction(FocusManager.setGui, function(_, gui)
	if gui == "ingameMenuSettings" then
		-- Let the focus manager know about our custom controls now (earlier than this point seems to fail)
		for _, control in pairs(TipAnywhere.CONTROLS) do
			if not control.focusId or not FocusManager.currentFocusData.idToElementMapping[control.focusId] then
				if not FocusManager:loadElementFromCustomValues(control, nil, nil, false, false) then
					Logging.warning("Could not register control %s with the focus manager", control.id or control.name or control.focusId)
				end
			end
		end
		-- Invalidate the layout so the up/down connections are analyzed again by the focus manager
		local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
		settingsPage.generalSettingsLayout:invalidateLayout()
	end
end)


source(g_currentModDirectory .. 'ToggleSettingEvent.lua')

-- SEND SETTINGS TO CLIENT:
FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState,
function(self, connection, user, farm)

	for _, id in pairs(TipAnywhere.menuItems) do
	
		local value = TipAnywhere.getValue(id)
		if value ~= nil then
			ToggleSettingEvent.sendEvent(id, value)
		end
		
	end
	
end)
