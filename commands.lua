function RFP.CLOSE(idBinding, strCommand)
    RELAY_STATE = "closed"

    CoverControl("close_cover")
end

function RFP.TOGGLE(idBinding, strCommand)
    if RELAY_STATE == "open" then
        RFP:CLOSE(strCommand)
    else
        RFP:OPEN(strCommand)
    end
end

function RFP.OPEN(idBinding, strCommand)
    RELAY_STATE = "open"

    CoverControl("open_cover")
end

function RFP.BUTTON_ACTION(idBinding, strCommand, tParams)
    if tParams.ACTION == "2" then
        if tParams.BUTTON_ID == "0" then
            RFP:CLOSE(strCommand)
        elseif tParams.BUTTON_ID == "1" then
            RFP:OPEN(strCommand)
        else
            RFP:TOGGLE(strCommand)
        end
    end
end

function RFP.DO_CLICK(idBinding, strCommand, tParams)
    local tParams = {
        ACTION = "2",
        BUTTON_ID = ""
    }

    if idBinding == 200 then
        tParams.BUTTON_ID = "0"
    elseif idBinding == 201 then
        tParams.BUTTON_ID = "1"
    elseif idBinding == 202 then
        tParams.BUTTON_ID = "2"
    end

    RFP:BUTTON_ACTION(strCommand, tParams)
end

function CoverControl(service)
    local switchServiceCall = {
        domain = "cover",
        service = service,

        service_data = {},

        target = {
            entity_id = EntityID
        }
    }

    local tParams = {
        JSON = JSON:encode(switchServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.RECEIEVE_STATE(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.response)

    local stateData

    if jsonData ~= nil then
        stateData = jsonData
    end

    Parse(stateData)
end

function RFP.RECEIEVE_EVENT(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.data)

    local eventData

    if jsonData ~= nil then
        eventData = jsonData["event"]["data"]["new_state"]
    end

    Parse(eventData)
end

function Parse(data)
    if data == nil then
        print("NO DATA")
        return
    end

    if data["entity_id"] ~= EntityID then
        return
    end

    local state = data["state"]

    if not Connected then
        Connected = true
    end

    if state ~= nil then
        if state == "open" then
            RELAY_STATE = state
            C4:SendToProxy(2, 'OPENED', {}, "NOTIFY")
            C4:SendToProxy(3, 'CLOSED', {}, "NOTIFY")
        elseif state == "closed" then
            RELAY_STATE = state
            C4:SendToProxy(2, 'CLOSED', {}, "NOTIFY")
            C4:SendToProxy(3, 'OPENED', {}, "NOTIFY")
        elseif state == "opening" or state == "closing" then
            C4:SendToProxy(2, 'OPENED', {}, "NOTIFY")
            C4:SendToProxy(3, 'OPENED', {}, "NOTIFY")
        end
    end
end
