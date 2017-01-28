import socket, random, time, os.path, sys
from threading import Thread, Lock
import xml.etree.ElementTree as ET
import select

TCP_IP = 'localhost'
TCP_PORT = 5752
BUFFER_SIZE = 1024
MSG_TYPE = []


class ClientRegistrationThread(Thread):

	def __init__(self,ip,port,sock,connections,users,hubs,lock):
		Thread.__init__(self) 
		self.ip = ip 
		self.port = port 
		self.sock = sock
		self.connections = connections
		self.users = users
		self.lock = lock
		self.hubs = hubs
		self.username="Unknown"
		print " New registration started for "+ip+":"+str(port)
		
	def run(self): 	
		try:
			data = self.sock.recv(65000)
			msg_type, msg_content = data.split("|")

			if msg_type == "Register":
				self.username, hub, passwordIn, passwordOut = msg_content.split("/")
				new_user = dict()
				new_user["username"]=self.username
				new_user["hub"] = hub
				new_user["In"] = True
				new_user["Out"] = True
				new_user["connection"] = conn
				new_user["transferred"] = 200000
				new_user["ip"] = self.ip
				new_user["port"] = self.port
				hub_ok = True
				if hub != "global":
					if hub in self.hubs:
						if self.hubs[hub]["passwordIn"] != passwordIn:
							new_user["In"] = False
						if self.hubs[hub]["passwordOut"] != passwordOut:
							new_user["Out"] = False
					else:
						xmlFileName = 'economy_data_server_%s.xml' % hub
						tree = None
						lock.acquire()
						if os.path.isfile(xmlFileName):
							#print("xml file exists")
							with open(xmlFileName, 'rb') as xml_file:
								try:
									tree = ET.parse(xml_file)
									root = tree.getroot()
									hub_PasswordIn = root.find("hubPasswordIn")
									hub_PasswordOut = root.find("hubPasswordOut")
									new_hub = dict()
									new_hub["name"] = hub
									new_hub["passwordIn"] = hub_PasswordIn
									new_hub["passwordOut"] = hub_PasswordOut
									self.hubs[hub] = new_hub
								except:
									hub_ok = False
									self.sock.send("Nack|UnexpectedMessage")
									self.removeConnection()

						else:
							with open('economy_data_server_init.xml', 'rb') as xml_file:
								tree = ET.parse(xml_file)
								root = tree.getroot()
								root.find("hubPasswordIn").text = passwordIn
								root.find("hubPasswordOut").text = passwordOut
								root.find("hub").text = hub
								tree.write("economy_data_server_%s.xml" % hub)
							new_hub = dict()
							new_hub["name"] = hub
							new_hub["passwordIn"] = passwordIn
							new_hub["passwordOut"] = passwordOut
							self.hubs[hub] = new_hub

						self.lock.release()

				if hub_ok:
					self.lock.acquire()
					id = random.randint(1,10000)
					while id in self.users:
						id = random.randint(1,10000)
						new_user["Id"] = id
					self.users[id] = new_user
					self.lock.release()

					self.sock.send("Ack|registered")

					updateOneClient = ClientUpdater(self.connections, new_user, "", lock)
					updateOneClient.start()
			else:
				self.sock.send("Nack|UnexpectedMessage")
				print "Wrong protocol or wrong state: remove"
				self.removeConnection()

		except socket.error:
			#Probably wrong client. Remove from list
			e = sys.exc_info()[0]
			print "Error %s" % e
			self.removeConnection()

	def removeConnection(self):
		self.lock.acquire()
		if self.conn is not None:
			if self.conn in self.connections:
				print "Connection closed"
				self.conn.close()
				self.connections.remove(self.conn)
			for userID in self.users.keys():
				if self.users[userID]["connection"] == conn:
					print "User removed: ID: %s Name: %s" % (userID, self.users[userID]["username"])
					del self.users[userID]
		self.lock.release()

class ClientUpdater(Thread):

	def __init__(self, connections, user, chatMessage, lock):
		Thread.__init__(self)
		self.connections = connections
		self.user = user
		self.lock = lock
		self.chatMessage = chatMessage

	def run(self):
		xmlFileName = 'economy_data_server_%s.xml' % self.user["hub"]
		tree = None
		lock.acquire()

		if os.path.isfile(xmlFileName):
			#print("xml file exists")
			with open(xmlFileName, 'rb') as xml_file:
				tree = ET.parse(xml_file)
		else:
			with open('economy_data_server_init.xml', 'rb') as xml_file:
				tree = ET.parse(xml_file)
		root = tree.getroot()
		lock.release()

		data = ET.tostring(root, encoding="us-ascii", method="xml")

		try:
			if self.chatMessage == "":
				msg = "Update|%s//transmissionComplete" % data
			else:
				msg = "Chat|%s//transmissionComplete" % self.chatMessage
			self.user["connection"].send(msg)
		except socket.error:

			if "Id" in self.user:
				if self.user["Id"] in self.users:
					print "User removed: ID %s Name: %s" % (self.user["Id"],self.user["username"])
					lock.acquire()
					del users[self.user["Id"]]
					lock.release()
			print "Connection closed while updating"
			self.user["connection"].close()
			lock.acquire()
			if self.user["connection"] in self.connections:
				print "Connection closed"
				self.user["connection"].close()
				self.connections.remove(self.user["connection"])
			lock.release()

class ClientListener(Thread):

	def __init__(self,connections,users,hubs,lock):
		Thread.__init__(self)
		self.connections = connections
		self.users = users
		self.hubs = hubs
		self.lock = lock
		self.dt = 3000
		self.hourlyLimit = 500000
		self.maxLimit = 200000

	def run(self):
		while True:
			lock.acquire()
			ready_to_read = []
			ready_to_write = []
			in_error = []
			if self.connections != []:
				ready_to_read,ready_to_write,in_error = select.select(self.connections,[],[],0)

			lock.release()
			for incoming in ready_to_read:
				try:
					# receiving data from the socket.
					data = incoming.recv(BUFFER_SIZE)
					if data:
						current_user = None
						lock.acquire()
						for user in self.users:
							if self.users[user]["connection"] == incoming:
								current_user = self.users[user]
						lock.release()
						if user is not None:
							xmlFileName = 'economy_data_server_%s.xml' % current_user["hub"]
							tree = None
							lock.acquire()
							if os.path.isfile(xmlFileName):
								tree = ET.parse(xmlFileName)
							else:
								print("xml file does not exist. Reading init file")
								tree = ET.parse('economy_data_server_init.xml')

							root = tree.getroot()
							lock.release()
							messageType, message = data.split("|")
							if messageType == "Update":
								commodity, bought, sold = message.split("/")
								commodityTransferred = commodity
								bought = int(bought)
								sold = int(sold)

								if self.validityCheck(current_user, commodity, bought, sold):
									lock.acquire()
									print "Update for hub %s: %s bought: %s sold: %s" % (current_user["hub"], commodity, bought, sold)
									current_user["transferred"] -= abs(bought+sold)

									commidityList = root.find('commodities')
									for commodity in commidityList:
										serverName = commodity.find('name').text
										if serverName == commodityTransferred:
											serverAmount = int(commodity.find('amount').text)
											serverAmount = serverAmount + sold - bought

											if serverAmount < 0:
												serverAmount = 0
											commodity.find('amount').text = "%s" % serverAmount
											self.saveTree(tree, root, current_user["hub"])
									lock.release()
									incoming.send("Ack|Ok//transmissionComplete")
									time.sleep(2)
									self.updateClients(current_user["hub"])

								else:
									incoming.send("Nack|Update not accepted//transmissionComplete")
							elif messageType == "Chat":
								username, chatMessage = message.split("/")
								messageOut = "%s: %s" % (username, chatMessage)
								self.updateClients(current_user["hub"], messageOut)
						else:
							print "Dont know the client - Sending Nack"
							incoming.send("Nack|Unknown Client//transmissionComplete")

					else:
						print "remove the socket that's broken"
						self.removeConnection(incoming)
				except:
					print "Connection closed because recv failed"
					self.removeConnection(incoming)
					continue
			time.sleep(self.dt*0.001)

			for user in self.users:
				self.users[user]["transferred"] += (self.hourlyLimit * 1.0 * ((self.dt*1.0)/(1000.0*60*60)))
				if self.users[user]["transferred"] > self.maxLimit:
					self.users[user]["transferred"] = self.maxLimit


	def removeConnection(self, socket):
		self.lock.acquire()
		if socket in self.connections:
			print "Connection closed"
			socket.close()
			self.connections.remove(socket)
		for userID in self.users.keys():
			if self.users[userID]["connection"] == socket:
				print "User removed: ID %s Name: %s" % (userID,self.users[userID]["username"])
				del self.users[userID]
		self.lock.release()

	def saveTree(self, tree, newRoot, hub):
		tree._setroot(newRoot)
		tree.write("economy_data_server_%s.xml" % hub)

	def validityCheck(self, user, commodity, bought, sold):
		if user["transferred"] < abs(bought + sold):
			return False
		if bought and not user["Out"]:
			return False
		if sold and not user["In"]:
			return False

		return True

	def updateClients(self, hub, chatMessage = ""):
		lock.acquire()
		for user in self.users:
			if self.users[user]["hub"] == hub:
				updateOneClient = ClientUpdater(self.connections, self.users[user], chatMessage, lock)
				updateOneClient.start()
		lock.release()



						
lock = Lock()
tcpsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
tcpsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
tcpsock.bind(("", TCP_PORT))

threads = []
connections = []
users = dict()
hubs = dict()

listenerThread = ClientListener(connections,users,hubs,lock)
listenerThread.start()

while True: 
	tcpsock.listen(5)
	print "Waiting for incoming connections..."
	(conn, (ip,port)) = tcpsock.accept() 
	print 'Got connection from ', (ip,port)
	lock.acquire()
	connections.append(conn)
	lock.release()
	newthread = ClientRegistrationThread(ip,port,conn,connections,users,hubs,lock)
	newthread.start()