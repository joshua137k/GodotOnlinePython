import asyncio
import json
import sqlite3

from autobahn.asyncio.websocket import WebSocketServerProtocol, WebSocketServerFactory

class ChatProtocol(WebSocketServerProtocol):

    def __init__(self):
        super().__init__()
        self.username = None

    def onConnect(self, request):
        print("Client connecting: {}".format(request.peer))

    def onOpen(self):
        print("WebSocket connection open")
        self.factory.register(self)
        print(self.factory.protocols)

    def onClose(self, wasClean, code, reason):
        print("WebSocket connection closed: {}".format(reason))
        if self.username:
            print("User '{}' disconnected".format(self.username))
            self.factory.unregister(self)

    def onMessage(self, payload, isBinary):
        message = payload.decode('utf8')
        print("Text message received: {}".format(message))
        try:
            data = json.loads(message)
            if data["action"] == "register":
                self.register_user(data["username"], data["password"])
            elif data["action"] == "login":
                self.login_user(data["username"], data["password"])
            elif data["action"] == "message":
                if self.username:
                    self.broadcast_message(data["message"])
            else:
                print("Unknown action: {}".format(data["action"]))
        except json.JSONDecodeError:
            print("Invalid JSON format")

    def register_user(self, username, password):
        try:
            conn = sqlite3.connect('users.db')
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, password))
            conn.commit()
            self.send_message("registered")
            print("User '{}' registered".format(username))
        except sqlite3.IntegrityError:
            self.send_message("username_taken")
            print("Username '{}' is already taken".format(username))
        finally:
            conn.close()

    def login_user(self, username, password):
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
        user = cursor.fetchone()
        islogged=any(p.username == username for p in self.factory.protocols)
        if user and not(islogged):
            self.username = username
            self.send_message("logged_in")
            print("User '{}' logged in".format(username))

        else:
            self.send_message("invalid_credentials or username logged")
            print("Invalid login credentials for user '{}'".format(username))
        conn.close()

    def send_message(self, message):
        self.sendMessage(json.dumps({"message": message}).encode('utf8'))

    def broadcast_message(self, message):
        for p in self.factory.protocols:
            if p is not self:
                p.send_message("{}: {}".format(self.username, message))

class ChatFactory(WebSocketServerFactory):

    def __init__(self, url):
        super().__init__(url)
        self.protocol = ChatProtocol
        self.protocols = set()


    def register(self, protocol):
        self.protocols.add(protocol)

    def unregister(self, protocol):
        self.protocols.remove(protocol)

if __name__ == '__main__':
    factory = ChatFactory("ws://localhost:9000")
    asyncio.get_event_loop().run_until_complete(asyncio.gather(
        asyncio.get_event_loop().create_server(factory, 'localhost', 9000),
        ))
    asyncio.get_event_loop().run_forever()
