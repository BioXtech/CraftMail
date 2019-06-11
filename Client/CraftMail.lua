--librairies
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
local version = "6.0"
local accountID = ""
local password = ""
local messages = {}
local xRes, yRes = gpu.getViewport()
local listMailPart = {["xMin"] = 3, ["yMin"] = 9, ["xMax"] = 32, ["yMax"] = yRes - 3}
local editMailPart = {["xMin"] = 36, ["yMin"] = 5, ["xMax"] = xRes - 3, ["yMax"] = yRes - 3}
local yBlockStart = {9, 14, 19, 24, 29, 34, 39}

function writeMid(text, y)
  local strLength = string.len(text)
  local xLength, yLength = term.getViewport()
  local start = math.floor(xLength / 2) - math.floor(strLength / 2)
  term.setCursor(start, y)
  term.write(text)
end

function box()
  xLength, yLength = term.getViewport()
  gpu.fill(1, 1, xLength, 1, " ")
  gpu.fill(1, 1, 1, yLength, " ")
  gpu.fill(xLength, 1, 1, yLength, " ")
  gpu.fill(1, yLength, xLength, 1, " ")
end

function initInterface()
  gpu.setDepth(8)
  term.clear()
  --frame
  gpu.setBackground(0xABABAB)
  gpu.fill(1, 1, xRes, yRes, " ")
  gpu.setBackground(0x000000)
  gpu.fill(2, 2, xRes - 2, yRes - 2, " ")
  gpu.setBackground(0xABABAB)
  gpu.fill(1, 4, xRes, 1, " ")
  --end frame

  --top screen bar
  gpu.setBackground(0x666666)
  gpu.fill(1, 1, xRes, 3, " ")
  term.setCursor(3, 2)
  term.write("CraftMail - Version: " .. version)
  term.setCursor(xRes-7-string.len( accountID )-string.len( "Logged as: " ),2)
  term.write("Logged as: "..accountID)

  gpu.setBackground(0xFF0000)
  gpu.fill(xRes - 4, 1, 5, 3, " ")

  gpu.setForeground(0x000000)
  term.setCursor(xRes - 2, 2)
  term.write("X")
  --end top screen bar

  --separator
  gpu.setBackground(0xABABAB)
  gpu.fill(34, 4, 1, yRes, " ")
  --end separator
end

function drawBlock(x, y, sender, object)
  term.setCursor(x, y)
  gpu.setForeground(0x000000)
  gpu.setBackground(0xFFFFFF)
  gpu.fill(x, y, 30, 4, " ")
  term.setCursor(x + 1, y + 1)
  term.write(sender .. "\n")
  term.setCursor(x + 1, y + 2)
  if (string.len(object) > 28) then
    term.write(string.sub(object, 1, 25) .. "...")
  else
    term.write(object)
  end
end

function sendToServer(protocol, dataTable)
  modem.send(serverAddress, 32728, protocol, serialization.serialize(dataTable))
end

function login()
  term.clear()
  term.setCursor(4, 2)
  io.write("Login")
  term.setCursor(4, 4)
  io.write("ID : ")
  accountID = io.read()
  term.setCursor(4, 8)
  io.write("Password : ")
  password = io.read()
  sendToServer("userLogon", {accountID = accountID, password = password})
  eventName, a, b, c, d, protocol, isSucessfull = event.pull("modem_message")
  return isSucessfull
end

function getMailFromServer()
  sendToServer("mailRequestService", {accountID = accountID})
  local try = 5
  repeat
    eventName, _, _, _, _, protocol, data = event.pull("modem_message") --localAddress,remoteAddress,port,distance
    if protocol == "mailRequestService" then
      message = serialization.unserialize(data)
    end
    try = try - 1
  until #message ~= 0 or try == 0
  return message
end

--Menu
function menu()
  initInterface()
  messages = getMailFromServer()
  for i = 1, #messages do
    drawBlock(listMailPart.xMin, yBlockStart[i], messages[i]["from"], messages[i]["message"])
  end
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
  term.setCursor(16, 2)
  print("Carnet d'adresses")
  term.setCursor(1, 3)
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
  table.insert(contacts, new)
  term.setCursor(14, 9)
  print("Contact ajoute !")
  os.sleep(1)
  term.clear()
  adresses()
end

--Send message
function messageEnvoi()
  term.clear()
  term.setCursor(1, 2)
  print("A qui voulez vous envoyer un message ?")
  local recipient = io.read()
  print("Quel est le message ?")
  local messageEnvoi = io.read()
  sendToServer("mailSendingService", {from = accountID, to = recipient, message = messageEnvoi})
  local event, _, _, _, _, protocol, isRecieved = event.pull("modem_message")
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
  messages = getMailFromServer()
  term.clear()
  term.setCursor(14, 1)
  io.write("Messages")
  term.setCursor(1, 2)
  print("[Q] pour revenir au menu")
  print(" ")
  print("Messages :")
  for i = 1, 10 do
    if messages[i] == nil then
      print("")
    else
      print(messages[i])
    end
  end
  repeat
    local eventName, _, arg2, _, _, data = event.pull()
    if eventName == "key_down" and arg2 == 113 then
      menu()
    --[[elseif eventName == "modem_message" then
        table.insert(messages,data)
        print(data)]]
    end
  until (arg2 == 113)
end

--quitter
function quitter()
  term.clear()
  term.setCursor(14, 9)
  io.write("Au revoir")
  os.sleep(1)
  gpu.setBackground(0x00)
  term.clear()
  term.setCursor(1, 1)
  local file = io.open("contacts", "w")
  file:write(serialization.serialize(contacts))
  file:close()
  os.exit()
end

--getServerAddress
modem.open(32728)
modem.broadcast(32728, "getServerAddress")
local try = 10
local eventName, _, remoteAddress, _, _, protocol = event.pull("modem_message")
repeat
  if protocol == "getServerAddress" then
    serverAddress = remoteAddress
  end
  os.sleep(1)
  try = try - 1
until serverAddress ~= nil or try == 0

--login screen
repeat
  isSucessfull = login()
  if isSucessfull then
    term.clear()
    writeMid("Authentification reussie", 8)
    os.sleep(2)
  else
    term.clear()
    writeMid("Authentification echouee", 8)
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

menu()
