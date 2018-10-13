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
  eventName, localAddress, remoteAddress, port, distance, protocol,username, data = event.pull("modem_message")
  print(eventName, localAddress, remoteAddress, port, distance, protocol, username, data)
  if protocol == "getServerAddress" then --Craftmail looking for the server address
    modem.send(remoteAddress, 32728, "getServerAddress", localAddress)
  elseif protocol == "mailSendingService" then --Client send mail to someone
    table.insert(accountMailTable[username],1,data)
    modem.send(remoteAddress,32728,"mailSendingService",true)
  elseif protocol == "mailRequestService" then --client wants to see his mails
    modem.send(remoteAddress,32728, "mailRequestService", serialization.serialize(accountMailTable[username]))
  elseif protocol == "userLogon" then -- Client wants to log in
      for key,value in pairs(accountTable) do
        if(username == key and value == data) then
          modem.send(remoteAddress,32728, "userlogon", true)
        else
          modem.send(remoteAddress,32728,"userlogon",false)
        end
      end
  end  
end