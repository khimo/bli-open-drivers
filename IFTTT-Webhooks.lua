driver_label= "IFTTT - Webhooks"
driver_min_blgw_version= "1.5.0"
driver_version= "0.1"
driver_help= [[ 
IFTTT through the Webhooks
=======================
This driver makes it simpler for the BLI user to fire IFTTT actions through the Webhooks trigger system.

To trigger an Event this driver makes a POST web request to: https://maker.ifttt.com/trigger/{BLIresourceAddress}/with/key/{SystemKey}

An optional body ({ "value1" : "", "value2" : "", "value3" : "" }) is sent, and these values can be set in the Macro configuration.

The data is completely optional, and you can also pass value1, value2, and value3 as query parameters or form variables. This content will be passed on to the Action in your Recipe. 

Connecting to the system
-------------------------
Communication with Webhooks is HTTP RESTful. 

Channel settings are:

* _Key_ : The key is specific to each IFTTT user and can be found in the documentation (https://ifttt.com/maker_webhooks)

Available resources
--------------------------------
The available resource type is:

* **FIRE**: Fire an action.

Resource Address
-------------------
Resource Address should be exactly the name of the Webhooks event you wish to call.

Commands, Events and States
-------------------------------
Commands are the same for both resource types:

* Commands:
  - **SEND**: Send POST to Webhooks without values.
  - **SEND WITH VALUES**: Send POST to Webhooks with three required values.

**Value arguments are Optional for Webhooks.**

]]


local custom_arguments= {
   stringArgument("_Key", "", { context_help= "Webhooks key"})
}

driver_channels= {
   CUSTOM("Webhooks connection", "Connection to IFTTT through Webhooks", custom_arguments)
}

local sendCmd = {
  SEND = {
      code= "_SEND",
      context_help = "Send the HTTP request without values.",
      arguments = {}
   },
   SEND_WITH_VALUES = {
      code= "_SEND_WITH_VALUES",
      context_help = "Send the HTTP request WITH three required values.",
      arguments = {
        stringArgument("_value1", " ", { context_help= 'Required', disallow_empty=true}),
        stringArgument("_value2", " ", { context_help= 'Required', disallow_empty=true}),
        stringArgument("_value3", " ", { context_help= 'Required', disallow_empty=true})
       }
   }
}

local add = {
    hugeStringArgumentRegEx("address", "MakerEventName", ".*", { context_help= 'The address should contain the Maker Event name ' })
}

resource_types= {
  ["FIRE"] = {
        standardResourceType = "_FIRE",
        address = add,
        events = {},
        commands = sendCmd,
        states = {},
        context_help = "Fire POST HTTP request resource."
  }
}

local baseUrl="https://maker.ifttt.com/trigger/"

function process()
  local key=channel.attributes("_Key")
  --Trace("process starting")
  local success = urlGet("https://maker.ifttt.com/trigger/{event}/with/key/" .. key)
  if success and key~="" then
    driver.setOnline()
    return CONST.POLLING
  else
    driver.setError()
    Error("Connection failed, check your channel settings.", true)
    channel.retry("Retrying in 30 seconds.", 30)
    return CONST.INVALID_CREDENTIALS
  end
end -- process

function executeCommand(command, resource, commandArgs)
  local key=channel.attributes("_Key")
  local event=resource.address
  local success, msg, body, commandUrl
  if command=="_SEND" then
    body="-"
    commandUrl = baseUrl .. event .. "/with/key/" .. key

    success, msg = urlPost(commandUrl)

  elseif command=="_SEND_WITH_VALUES"  then
    --body should be as: { "value1" : "", "value2" : "", "value3" : "" } 
    local v1=commandArgs["_value1"]
    local v2=commandArgs["_value2"]
    local v3=commandArgs["_value3"]
    body='{ "value1" : "'..v1..'", "value2" : "'..v2..'", "value3" : "'..v3..'" }'
    commandUrl = baseUrl .. event .. "/with/key/" .. key

    success, msg = urlPost(commandUrl,body,{ ["Content-Type"]= "application/json" })
  end

  if success then
    Trace("HTTP POST sent to: " .. commandUrl .. " with body: " .. body,true)
    Trace("RESPONSE: " .. msg, true)
  else
    Error("Failed to execute command on resource "..resource.name.." with address "..resource.address .. " - HTTP POST ERROR.", true)
  end
end

function onResourceDelete(resource)
  Trace("Resource was deleted")
end

function onResourceUpdate(resource)
  Trace("Resource was updated")
end

function onResourceAdd(resource)
  Trace("Resource was added")
end
