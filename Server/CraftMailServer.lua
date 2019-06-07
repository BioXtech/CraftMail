modem = require("component").modem
event = require("event")
serialization = require("serialization")
dataCard = require("component").data

modem.open(32728)
accountTable={}
accountTable["test"] = "password"
accountMailTable= {}
accountMailTable["test"] = {"a","b","c"}

while true do 
  eventName, localAddress, remoteAddress, port, distance, protocol, data = event.pull("modem_message")
  print(eventName, localAddress, remoteAddress, port, distance, protocol, data)
  data = serialization.unserialize(data)
  if protocol == "getServerAddress" then --Craftmail looking for the server address
    modem.send(remoteAddress, 32728, "getServerAddress", localAddress)
  elseif protocol == "mailSendingService" then --Client send mail to someone
    table.insert(accountMailTable[data.recipient],1,{data.accountId,data.message})
    modem.send(remoteAddress,32728,"mailSendingService",true)
  elseif protocol == "mailRequestService" then --client wants to see his mails
    modem.send(remoteAddress,32728, "mailRequestService", serialization.serialize(accountMailTable[data.accountId]))
  elseif protocol == "userLogon" then -- Client wants to log in
      for key,value in pairs(accountTable) do
        if(data.accountId == key and data.password == value) then
          modem.send(remoteAddress,32728, "userlogon", true)
        else
          modem.send(remoteAddress,32728,"userlogon",false)
        end
      end
  end  
end