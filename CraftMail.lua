if peripheral.getType("top") ~= "modem" then
  printError("Pas de modem detecté au dessus")
elseif term.isColor() ~= true then
  printError("Ce n'est pas un Advanced Computer")
else
rednet.open("top")
term.clear()
contacts = {}
redmess = {}
term.setBackgroundColor(colors.blue)

for i = 1,2 do
  term.setCursorPos(14,9)
  term.clear()
  write("Initialisation. ")
  sleep(1)
  write(". ")
  sleep(1)
  write(". ")
  sleep(1)
end

term.clear()
term.setCursorPos(13,9)
write("Bienvenue !")
sleep(1)
term.clear()

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

function menu()
	term.clear()
	term.setCursorPos(1,1)
	print("CraftMail by BioXtech v2.0")
	print("[N] pour envoyer un message")
	print("[M] pour voir les messages")
	print("[C] pour ouvrir le carnet d'adresses")
	print("[Q] pour quitter")
	print("ID Computer: "..os.getComputerID())
	local event, char = os.pullEvent("char")
	if char == "n" then
		messageEnvoi()
	elseif char == "m" then
		messageRecep()
	elseif char == "c" then
		adresses()
	elseif char == "q" then
		term.clear()
		term.setCursorPos(14,9)
		write("Au revoir")
		sleep(1)
		term.setBackgroundColor(colors.black)
		term.clear()
		term.setCursorPos(1,1)
	end
end

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
menu()
end
