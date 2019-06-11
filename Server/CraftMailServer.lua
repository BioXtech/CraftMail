modem = require("component").modem
event = require("event")
serialization = require("serialization")
dataCard = require("component").data

modem.open(32728)
accountTable={}
accountTable["test"] = "password"
accountMailTable= {}
accountMailTable["test"] = {
  {from = "Lunix",message = "Hi, how are you ?"},
  {from = "MS-DOS",message = "Please come back"},
  {from = "PineApple",message = "Do you want our 6000$ cheese grate ?"}
}

while true do 
  eventName, localAddress, remoteAddress, port, distance, protocol, data = event.pull("modem_message")
  print(eventName, localAddress, remoteAddress, port, distance, protocol, data)
  if data ~= nil then
    data = serialization.unserialize(data)
  end
  if protocol == "getServerAddress" then --Craftmail looking for the server address
    modem.send(remoteAddress, 32728, "getServerAddress", localAddress)
  elseif protocol == "mailSendingService" then --Client send mail to someone
    table.insert(accountMailTable[data.to],1,{from = data.from,message = data.message})
    print(serialization.serialize(accountMailTable))
    modem.send(remoteAddress,32728,"mailSendingService",true)
  elseif protocol == "mailRequestService" then --client wants to see his mails
    modem.send(remoteAddress,32728, "mailRequestService", serialization.serialize(accountMailTable[data.accountID]))
  elseif protocol == "userLogon" then -- Client wants to log in
      for key,value in pairs(accountTable) do
        if(data.accountID == key and data.password == value) then
          modem.send(remoteAddress,32728, "userlogon", true)
        else
          modem.send(remoteAddress,32728,"userlogon",false)
        end
      end
  end  
end