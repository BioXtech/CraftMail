-- only use with CraftMail 3.0
if debut then
	saveContacts = {}
	passe = true
else
	for i = 1, table.getn(contacts) do
		saveContacts[i] = contacts[i]
	end
	print("Contacts sauvegardés")
end