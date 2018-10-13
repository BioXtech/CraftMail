component = require("component")
term = require("term")
gpu = require("component").gpu
modem = require("component").modem
colors =require("colors")
event = require("event")
serialization = require("serialization")

if not component.isAvailable("modem") then
	  io.stderr("Pas de carte sans fil detecte")
elseif gpu.getDepth() == 1 then
	  io.stderr("Il faut une carte graphqie de Tier 2 min")
end
    -- declaration var
    local version = "4.0"
    local notif = 0
    local quit = false
    redmess = {}
    name = "contacts"
    --getServerAddress
    modem.open(32728)
    modem.broadcast(32728,"getServerAddress")
    eventName = nil
    local eventName,_,remoteAddress,_,_,protocol = event.pull("modem_message")
    if protocol == "getServerAddress" then
      serverAddress = remoteAddress
    end
    
    --load contact
    local file = io.open(name)
    local data = file:read("*a")
    file:close()
    contacts = serialization.unserialize(data)
    if contacts == nil then
      contacts = {}
    end

    function writeMid(text,y)
       local strLength = string.len(text)
       local xLength,yLength = term.getViewport()
       local start = math.floor(xLength/2)-math.floor(strLength/2)
       term.setCursor(start,y)
       term.write(text)
    end
    
    function box()
        xLength,yLength = term.getViewport()
       -- paintutils.drawBox(1,1,xLength,yLength,colors.black)
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
	end]]
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
    while true do    
    local eventName, arg1, arg2, _, _, message = event.pull()
			if eventName == "modem_message" then
				notif = notif + 1
				table.insert(redmess,message)
				term.setCursor(40,5)
				print("("..notif..")")
			elseif arg2 == 110 then
				messageEnvoi()
			elseif arg2 == 114 then
				messageRecep()
			elseif arg2 == 99 then
				adresses()
			elseif arg2 == 113 then
				quitter()
			end
		end
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
    local eventName, _, arg2 = event.pull("key_down")
		if arg2 == 110 then
			contact()
		elseif arg2 == 113 then
			menu()
		end
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
		local personne = io.read()
		print("Quel est le message ?")
		local messageEnvoi = io.read()
		modem.send(serverAddress,32728,protocol,messageEnvoi)
		print("Ok,message envoye !")
		os.sleep(1)
		term.clear()
		menu()
	end
    
    --reception message
	function messageRecep()
		term.clear()
		term.setCursor(14,1)
		io.write("Messages")
		term.setCursor(1,2)
		print("[Q] pour revenir au menu")
		print(" ")
    print("Messages :")
    eventName = nil
		for key, value in pairs(redmess) do
			print(value)
		end
    while arg3 ~= 113 do
      local eventName, _, arg2, _, _, data = event.pull()
			if eventName == "key_down" and arg2 == 113 then
					menu()
			elseif eventName == "modem_message" then
				table.insert(redmess,data)
				print(data)
			end
		end
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
        local file = io.open(name,"w")
        file:write(serialization.serialize(contacts))
        file:close()
os.exit()
	end
	menu()