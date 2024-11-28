-- ============================================================= --
-- TOGGLE SETTING EVENT
-- ============================================================= --
ToggleSettingEvent = {}
ToggleSettingEvent_mt = Class(ToggleSettingEvent, Event)

InitEventClass(ToggleSettingEvent, "ToggleSettingEvent")

function ToggleSettingEvent.emptyNew()
	--print("ToggleSetting - EMPTY NEW")
	local self = Event.new(ToggleSettingEvent_mt)
	return self
end

function ToggleSettingEvent.new(id, value)
	--print("ToggleSetting - NEW")
	local self = ToggleSettingEvent.emptyNew()
	self.id = id
	self.value = value
	return self
end

function ToggleSettingEvent:readStream(streamId, connection)
	--print("ToggleSetting - READ STREAM")
    local id = streamReadString(streamId)
    local value = streamReadBool(streamId)
    self.id = id
    self.value = value
	
	TipAnywhere.insertMenuItem(id)
	TipAnywhere.setValue(id, value)
	
	if connection:getIsServer() then
		--print("  APPLY SETTINGS")
		local menuOption = TipAnywhere.CONTROLS[id]
		local isAdmin = g_currentMission:getIsServer() or g_currentMission.isMasterUser
		menuOption:setState(TipAnywhere.getStateIndex(id))
		menuOption:setDisabled(not isAdmin)
	else
		--print("  RESEND EVENT")
		ToggleSettingEvent.sendEvent(id, value)
	end

end

function ToggleSettingEvent:writeStream(streamId, connection)
	--print("ToggleSetting - WRITE STREAM");
	streamWriteString(streamId, self.id)
	streamWriteBool(streamId, self.value)
end

function ToggleSettingEvent.sendEvent(id, value, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			--print("server: Toggle Setting Event")
			g_server:broadcastEvent(ToggleSettingEvent.new(id, value), false)
		else
			--print("client: Toggle Setting Event")
			g_client:getServerConnection():sendEvent(ToggleSettingEvent.new(id, value))
		end
	end
end
