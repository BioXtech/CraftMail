local component = require("component")
local term = require("term")
local gpu = require("component").gpu
local modem = require("component").modem
local colors = require("colors")
local event = require("event")
local serialization = require("serialization")
local dataCard = require("component").data


if not component.isAvailable("modem") then
  io.stderr("Pas de carte sans fil detecte")
elseif gpu.getDepth() == 1 then
  io.stderr("Il faut une carte graphique de Tier 2 min")
elseif not component.isAvailable("data") then
  io.stderr("Pas de  Data Card presente")
end
-- declaration var
local version = "5.0"
local redmess = {"Messages"}
--getServerAddress
modem.open(32728)
modem.broadcast(32728,"getServerAddress")
eventName = nil
local eventName,_,remoteAddress,_,_,protocol = event.pull("modem_message")
if protocol == "getServerAddress" then
  serverAddress = remoteAddress
end

function writeMid(text,y)
  local strLength = string.len(text)
  local xLength,yLength = term.getViewport()
  local start = math.floor(xLength/2)-math.floor(strLength/2)
  term.setCursor(start,y)
  term.write(text)
end

function login()
  term.clear()
  term.setCursor(4,2)
  io.write("Login")
  term.setCursor(4,4)
  io.write("ID : ")
  id = io.read()
  term.setCursor(4,8)
  io.write("Password : ")
  password = io.read()
  modem.send(serverAddress,32728,"userLogon",id,password)
  eventName,a,b,c,d,protocol,isSucessfull = event.pull("modem_message")
  return isSucessfull
end



repeat
  isSucessfull = login()
  if isSucessfull then
    term.clear()
    writeMid("Authentification reussie",8)
    os.sleep(2)
  else
    term.clear()
    writeMid("Authentification echouee",8)
    os.sleep(2)
  end
until isSucessfull

--load contact
local file = io.open("contacts")
local data = file:read("*a")
file:close()
contacts = serialization.unserialize(data)
if contacts == nil then
  contacts = {}
end



function box()
  xLength,yLength = term.getViewport()
  gpu.fill(1,1,xLength,1," ")
  gpu.fill(1,1,1,yLength," ")
  gpu.fill(xLength,1,1,yLength," ")
  gpu.fill(1,yLength,xLength,1," ")
end


--Ecran init
term.clear()
gpu.setBackground(0x0000FF)
--[[for i = 1,2 do
  term.setCursor(15,9)
  term.clear()
  io.write("Initialisation.")
  os.sleep(1)
  io.write(".")
  os.sleep(1)
  io.write(".")
  os.sleep(1)
  end]]--
  term.clear()
  writeMid("Bienvenue !",9)
  os.sleep(1)
  term.clear()

  --Menu
  function menu()
    term.clear()
    box()
    writeMid("CraftMail by BioXtech v"..version,2)
    gpu.setBackground(0x0000FF)
    writeMid(" [N]ouveau message",3)
    writeMid(" [R]eception messages",5)
    writeMid(" [C]arnet d'adresses",7)
    writeMid(" [Q]uitter",9)
    eventName = nil
    arg2 = nil
    os.sleep(2)
    arg2 = nil
    repeat
      local eventName, arg1, arg2, _, _, message = event.pull("key_down")
      if arg2 == 110 then
        messageEnvoi()
      elseif arg2 == 114 then
        messageRecep()
      elseif arg2 == 99 then
        adresses()
      elseif arg2 == 113 then
        quitter()
      end
    until (arg2 == 110 or arg2 == 114 or arg2 == 99 or arg2 == 113)
  end

  --Carnet adresses
  function adresses()
    term.clear()
    term.setCursor(16,2)
    print("Carnet d'adresses")
    term.setCursor(1,3)
    print("[N] pour nouvelle adresse")
    print("[Q] pour revenir au menu")
    print(" ")
    for key, value in pairs(contacts) do
      print(value)
    end
    eventName = nil
    repeat
    local eventName, _, arg2 = event.pull("key_down")
    if arg2 == 110 then
      contact()
    elseif arg2 == 113 then
      menu()
    end
    until (arg2 == 100 or arg2 == 113)
  end

  --Add contact
  function contact()
    print("Mettre le nom de la personne")
    local new = io.read()
    table.insert(contacts,new)
    term.setCursor(14,9)
    print("Contact ajoute !")
    os.sleep(1)
    term.clear()
    adresses()
  end

  --Send message
  function messageEnvoi()
    term.clear()
    term.setCursor(1,2)
    print("A qui voulez vous envoyer un message ?")
    local recipient = io.read()
    print("Quel est le message ?")
    local messageEnvoi = io.read()
    modem.send(serverAddress,32728,"mailSendingService",recipient,messageEnvoi)
    local event,_,_,_,_,protocol,isRecieved = event.pull("modem_message")
    if protocol == "mailSendingService" and isRecieved == true then
      print("Ok,message envoye !")
    else
      print("Le message n'a pas pu etre envoye")
    end
    os.sleep(1)
    term.clear()
    menu()
  end

  --reception message
  function messageRecep()
    modem.send(serverAddress, 32728, "mailRequestService",id)
    eventName = nil
    eventName, _, _, _, _, protocol, data = event.pull("modem_message")
    if protocol == "mailRequestService" then
      redmess = serialization.unserialize(data)
    end
    term.clear()
    term.setCursor(14,1)
    io.write("Messages")
    term.setCursor(1,2)
    print("[Q] pour revenir au menu")
    print(" ")
    print("Messages :")
    eventName = nil
    for i=1,10 do
      if redmess[i] == nil then
        print("")
      else
        print(redmess[i])
      end
    end
    repeat
      local eventName, _, arg2, _, _, data = event.pull()
      if eventName == "key_down" and arg2 == 113 then
        menu()
      --[[elseif eventName == "modem_message" then
        table.insert(redmess,data)
        print(data)]]
      end
    until (arg2 == 113)
  end

  --quitter
  function quitter()
    term.clear()
    term.setCursor(14,9)
    io.write("Au revoir")
    os.sleep(1)
    gpu.setBackground(0x00)
    term.clear()
    term.setCursor(1,1)
    local file = io.open("contacts","w")
    file:write(serialization.serialize(contacts))
    file:close()
    os.exit()
  end
  menu()