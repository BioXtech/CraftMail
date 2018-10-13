if not peripheral.find("modem") then
	  printError("Pas de modem detecte")
elseif not term.isColor() then
	  printError("Ce n'est pas un Advanced Computer")
else
	
    -- declaration var
    local version = "4.0"
    local notif = 0
	local quit = false
    redmess = {}
	name = "contacts"
    --load contact
    local file = fs.open(name,"r")
    local data = file.readAll()
    file.close()
    contacts = textutils.unserialize(data)
    if contacts == nil then
        contacts = {}
    end
    rednet.open("top")
	
    function writeMid(text,y)
       local strLength = string.len(text)
       local xLength,yLength = term.getSize()
       local start = math.floor(xLength/2)-math.floor(strLength/2)
        term.setCursorPos(start,y)
        term.write(text)
    end
    
    function box()
        xLength,yLength = term.getSize()
        paintutils.drawBox(1,1,xLength,yLength,colors.black)
    end
        
    
    --Ecran init
    term.clear()
	term.setBackgroundColor(colors.blue)
	for i = 1,2 do
	  term.setCursorPos(15,9)
	  term.clear()
	  write("Initialisation.")
	  sleep(1)
	  write(".")
	  sleep(1)
	  write(".")
	  sleep(1)
	end
	term.clear()
	writeMid("Bienvenue !",9)
	sleep(1)
	term.clear()

	--Menu
    function menu()
		term.clear()
        box()
		writeMid("CraftMail by BioXtech v"..version,2)
        term.setBackgroundColor(colors.blue)
		writeMid(" [N]ouveau message",3)
		writeMid(" [R]eception messages",5)
		writeMid(" [C]arnet d'adresses",7)
		writeMid(" [Q]uitter",9)
        term.setCursorPos(2,10)
		print(" ID Computer: "..os.getComputerID())
		while quit ~= true do
			local event, char, message = os.pullEvent()
			if event == "rednet_message" then
				notif = notif + 1
				table.insert(redmess,message)
				term.setCursorPos(40,5)
				print("("..notif..")")
			elseif char == "n" then
				messageEnvoi()
			elseif char == "r" then
				messageRecep()
			elseif char == "c" then
				adresses()
			elseif char == "q" then
				quit = true
				quitter()
			end	
		end
	end

	--Carnet adresses
    function adresses()
		term.clear()
		term.setCursorPos(16,2)
		print("Carnet d'adresses")
		term.setCursorPos(1,3)
		print("[N] pour nouvelle adresse")
		print("[Q] pour revenir au menu")
		print(" ")
		for key, value in pairs(contacts) do
			print(value)
		end
		local event2, char2 = os.pullEvent("char")
		if char2 == "n" then
			contact()
		elseif char2 == "q" then
			menu()
		end
	end
    
    --Add contact
	function contact()
		print("Mettre le nom de la personne plus l'id de son computer")
		local new = read()
		table.insert(contacts,new)
		term.setCursorPos(14,9)
		print("Contact ajoute !")
		sleep(1)
		term.clear()
		adresses()
	end
    
    --Send message
	function messageEnvoi()
		term.clear()
		term.setCursorPos(1,2)
		print("A qui voulez vous envoyer un message ?")
		local personne = tonumber(read())
		print("Quel est le message ?")
		local messageEnvoi = read()
		rednet.send(personne,messageEnvoi)
		print("Ok,message envoye !")
		sleep(1)
		term.clear()
		menu()
	end
    
    --reception message
	function messageRecep()
		term.clear()
		term.setCursorPos(14,1)
		write("Messages")
		term.setCursorPos(1,2)
		print("[Q] pour revenir au menu")
		print(" ")
		print("Messages :")
		for key, value in pairs(redmess) do
			print(value)
		end
		while char3 ~= "q" do
			local event3, char3, arg3 = os.pullEvent()
			if event3 == "char" then  
				if char3 == "q" then
					menu()
				end
			elseif event3 == "rednet_message" then
				table.insert(redmess,arg3)
				print(arg3)
			end
		end
	end
    
    --quitter
	function quitter()
		term.clear()
		term.setCursorPos(14,9)
		write("Au revoir")
		sleep(1)
		term.setBackgroundColor(colors.black)
		term.clear()
		term.setCursorPos(1,1)
        local file = fs.open(name,"w")
        file.write(textutils.serialize(contacts))
        file.close()
	end
	menu()
end
