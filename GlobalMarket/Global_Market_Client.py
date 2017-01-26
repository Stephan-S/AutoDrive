#!/usr/bin/python

from __future__ import division
import socket, thread, time, sys, random, math
import threading, select
import xml.etree.ElementTree as ET


class Client((threading.Thread)):
    tree = ET.parse('economy_data.xml')
    root = tree.getroot()

    SO_BINDTODEVICE = 25

    PORT_SERVER = 5752
    registered = False
    UPDATE_INTERVAL = 3
    UPDATE_INTERVAL_SERVER = 2

    def register(self):
        if not self.updateInfo["registered"]:
            server = self.root[0].find('server')
            serverName = server.get("name")
            if serverName is not None:
                print("Connecting to: %s" % serverName)
                connected = False
                while not connected:
                    try:
                        outSock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        outSock.connect((serverName, self.PORT_SERVER))
                        msg = "Register|%s/%s/%s/%s" % (
                        self.userName, self.hub, self.hubPasswordIn, self.hubPasswordOut)
                        outSock.send(msg)

                        ready_to_read, ready_to_write, in_error = select.select([outSock], [], [], 15)
                        if outSock in ready_to_read:
                            reply = outSock.recv(65500)
                            replyType, replyMessage = reply.split("|")

                            if replyType == "Ack":
                                lock.acquire()
                                if replyMessage == "registered":
                                    print "Im registered"
                                    self.registered = True
                                    self.updateInfo["registered"] = True
                                    connected = True
                                    self.connection[0] = outSock
                                else:
                                    self.registered = False
                                    self.updateInfo["registered"] = False

                                lock.release()

                            else:
                                print "Did not get a positive response from the server"
                                time.sleep(60)
                        else:
                            print "Error Registering. Trying again in 30s"
                            time.sleep(random.randint(20, 40))

                    except socket.error:
                        print "Error Registering at server. Server might be offline"
                        time.sleep(60)

    def __init__(self, root, tree, timeOutTimer, connection, updateInfo, function, lock):
        threading.Thread.__init__(self)
        self.root = root
        self.tree = tree
        self.function = function
        self.userName = self.root[0].find('username').text  # "Bob"
        self.hub = self.root[0].find('hub').text  # "global"
        self.hubPasswordIn = self.root[0].find('hubPasswordIn').text
        self.hubPasswordOut = self.root[0].find('hubPasswordOut').text
        self.useMoney = self.root[0].find('useMoney').text  # "global"
        self.printedInitialStorageInfo = False
        self.timeOutTimer = timeOutTimer
        self.connection = connection
        self.updateInfo = updateInfo
        self.backupData = None

    def run(self):
        if self.function == "listenOnServer":
            self.register()
            self.listenOnServer()
        if self.function == "update":
            self.update()

    def listenOnServer(self):

        while True:
            socketOpen = False
            while not socketOpen:
                if self.connection[0] != "null":
                    socketOpen = True
                else:
                    time.sleep(10)
            try:
                self.transmissionComplete = False
                self.data = ""
                if self.backupData is not None:
                    self.data = self.backupData
                    self.backupData = None

                while not self.transmissionComplete:
                    receivedData = self.connection[0].recv(65000)
                    if not receivedData: break
                    self.data = "%s%s" % (self.data, receivedData)
                    if "transmissionComplete" in receivedData:
                        if self.data.find("transmissionComplete") != (len(self.data) - 20):
                            self.backupData = self.data[(self.data.find("transmissionComplete") + 20):len(self.data)]
                            self.data = self.data[0:(self.data.find("transmissionComplete") + 20)]
                        self.transmissionComplete = True

                if self.data != "":
                    # print "received data: ", self.data
                    try:
                        messageType, message = self.data.split("|")
                    except:
                        print "Connection to the server was closed"
                        print "Trying to reconnect in 30 second"
                        lock.acquire()
                        self.updateInfo["registered"] = False
                        self.connection[0] != "null"
                        self.registered = False
                        lock.release()
                        time.sleep(30)
                        self.register()

                    if messageType == "Update":
                        xml, over = message.split("//")
                        lock.acquire()
                        # print "received update"
                        self.rootServer = ET.fromstring(xml)
                        changed = False
                        debugPrintMessage = "Current Content of storage '%s':" % self.hub
                        commidityList = self.rootServer.find('commodities')
                        for commodity in commidityList:
                            name = commodity.find('name').text
                            amount = int(commodity.find('amount').text)
                            price = int(commodity.find('price').text)
                            amountLocal = int(self.root[0].find(".//*[name='%s']" % name).find('amount').text)
                            boughtLocal = int(self.root[0].find(".//*[name='%s']" % name).find('bought').text)
                            soldLocal = int(self.root[0].find(".//*[name='%s']" % name).find('sold').text)
                            if amount != amountLocal and boughtLocal == 0 and soldLocal == 0:
                                self.root[0].find(".//*[name='%s']" % name).find('amount').text = "%s" % amount
                                changed = True
                            debugPrintMessage = "%s\n\t%s: amount: %s price: %s" % (
                            debugPrintMessage, name.ljust(25), ("%s" % amount).ljust(10), ("%s" % price).ljust(6))
                        if self.printedInitialStorageInfo == False:
                            if self.useMoney == "1" or self.hub == "global":
                                debugPrintMessage = "%s\nThis storage hub is set to pay and deduct money if you are going to trade with it" % debugPrintMessage
                            else:
                                debugPrintMessage = "%s\nTrading with this storage hub will not cost or reward you any money" % debugPrintMessage
                            print debugPrintMessage
                            self.printedInitialStorageInfo = True
                        if changed:
                            self.saveTree(self.root[0])
                        lock.release()
                    else:
                        message, over = message.split("//")
                        if messageType == "Ack" and message == "Ok":
                            lock.acquire()
                            print "Accepting changes made to: %s" % self.updateInfo["commodity"]
                            self.root[0].find(".//*[name='%s']" % self.updateInfo["commodity"]).find(
                                'bought').text = "0"
                            self.root[0].find(".//*[name='%s']" % self.updateInfo["commodity"]).find('sold').text = "0"
                            self.saveTree(self.root[0])
                            self.updateInfo["send"] = False
                            lock.release()
                        elif messageType == "Nack":
                            print "Server refused my update message. Server message: %s" % message
                            if message == "Unknown Client":
                                self.updateInfo["registered"] = False
                                self.register()
                            if message == "Update not accepted":
                                print "Your update was not accepted.\nWrong password for this hub or you have tried to buy/sell too much in a short time\nRetry in 60 seconds"
                                time.sleep(60)
                                lock.acquire()
                                self.updateInfo["send"] = False
                                lock.release()

                        else:
                            print "unknown message from server. Should probably update your mod right now. Message: %s" % self.data

                        # tree.write('economy_data.xml')
                else:
                    print "Connection to the server was closed"
                    print "Trying to reconnect in 30 second"
                    lock.acquire()
                    self.updateInfo["registered"] = False
                    self.connection[0] != "null"
                    self.registered = False
                    lock.release()
                    time.sleep(30)
                    self.register()

            except socket.error:
                e = sys.exc_info()[0]
                print "Error %s" % e
                print "Socket error while receiving"
                time.sleep(60)

    def update(self):
        while True:
            allowed = False
            lock.acquire()
            if not self.updateInfo["send"] and self.updateInfo["registered"] == True:
                allowed = True
            lock.release()
            if allowed:
                lock.acquire()
                readIn = False
                while not readIn:
                    try:
                        tree = ET.parse('economy_data.xml')
                        rootLocal = tree.getroot()
                        readIn = True
                    except:
                        print "Problem accessing the xml file"

                changed = False
                commidityList = self.root[0].find('commodities')
                for commodity in commidityList:
                    name = commodity.find('name').text
                    # amount = int(commodity.find('amount').text)
                    # price = int(commodity.find('price').text)
                    # amountLocal = int(rootLocal.find(".//*[name='%s']" % name).find('amount').text)
                    boughtLocal = int(rootLocal.find(".//*[name='%s']" % name).find('bought').text)
                    soldLocal = int(rootLocal.find(".//*[name='%s']" % name).find('sold').text)
                    if boughtLocal > 0 or soldLocal > 0 and self.connection[0] != "null" and not self.updateInfo[
                        "send"]:
                        messageType = "Update"
                        msg = "%s|%s/%s/%s" % (messageType, name, boughtLocal, soldLocal)
                        try:
                            print "Sending update to server %s" % msg
                            self.connection[0].send(msg)
                            self.updateInfo["send"] = True
                            self.updateInfo["commodity"] = name
                            self.updateInfo["timeout"] = 15
                        except socket.error:
                            e = sys.exc_info()[0]
                            print "Error while sending update to server %s" % e
                            self.updateInfo["registered"] = False
                            self.connection[0] != "null"
                            self.registered = False
                            time.sleep(60)
                            self.register()
                lock.release()
            else:
                if self.updateInfo["send"]:
                    self.updateInfo["timeout"] -= self.UPDATE_INTERVAL
                    if self.updateInfo["timeout"] < 0:
                        lock.acquire()
                        self.updateInfo["send"] = False
                        self.updateInfo["timeout"] = 15
                        lock.release()
                        print "Update unanswered by server. Retrying"

            time.sleep(self.UPDATE_INTERVAL)

    def saveTree(self, newRoot):
        tree._setroot(newRoot)
        tree.write('economy_data.xml')


registeredOnServer = False
tree = ET.parse('economy_data.xml')
root = [tree.getroot()]
lock = threading.Lock()
timeOutTimer = [30]
connection = ["null"]
updateInfo = {"send": False, "commodity": "null", "registered": False, "timeout": 15}

client = Client(root, tree, timeOutTimer, connection, updateInfo, "listenOnServer", lock)
client.start()

clientUpdate = Client(root, tree, timeOutTimer, connection, updateInfo, "update", lock)
clientUpdate.start()
