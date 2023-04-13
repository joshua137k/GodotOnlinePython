import sqlite3
import asyncio
import json
from autobahn.asyncio.websocket import WebSocketServerProtocol, WebSocketServerFactory



class MyServerProtocol(WebSocketServerProtocol):

    def __init__(self):
        super().__init__()
        self.username = None
        self.id = 0


    def onConnect(self, request):
        print("Cliente conectado: {}".format(request.peer))
        self.factory.register(self)



    def onOpen(self):
        print("Conexão aberta")


    def onClose(self, wasClean, code, reason):
        message = {'type': 'player_disconnected', 'id': self.id}
        self.factory.broadcast_message(message,self)

        client = self.factory.clients[self.id]
        if client:
            self.factory.unregister(self)
        print("Conexão fechada: {}".format(reason))


    def onMessage(self, payload, isBinary):
        #print("Mensagem de texto recebida: {}".format(payload.decode('utf8')))
        data = json.loads(payload.decode('utf8'))
        if data['type'] == 'player_position':
            # atualizar a posição do jogador no banco de dados
            #conn = sqlite3.connect('players.db')
            #c = conn.cursor()
            #c.execute("UPDATE players SET pos=?, rot=?WHERE id=?", (data['pos'], data['rot'], data['id']))
            #conn.commit()
            #conn.close()
            # enviar a posição atualizada para todos os clientes conectados, exceto o remetente original
            #w
            message = {'type': 'player_position', 'id': data['id'], 'data':data['data'], "username":self.username}
            #print(message)
            self.factory.broadcast_message(message, exclude=self)
        elif data['type'] == 'chat_message':
            # enviar a mensagem de chat para todos os clientes conectados, exceto o remetente original
            print("Mensagem de texto recebida: {}".format(payload.decode('utf8')))
            message = {'type': 'chat_message', 'username':self.username, 'text': data['text']}
            self.factory.broadcast_message(message, exclude=self)

        elif data["type"] == "register":
            self.register_user(data["username"],data["password"])
        elif data["type"] == "login":
            self.login_user(data["username"], data["password"])


    def register_user(self, username, password):
        conn = sqlite3.connect('users.db')
        try:

            cursor = conn.cursor()

            # Verifica se já existe um usuário com este username
            cursor.execute("SELECT username FROM users WHERE username = ?", (username,))
            user = cursor.fetchone()
            if user:

                message = {'type': 'system_message', 'text': "Username '{}' is already taken".format(username)}
                self.sendSystemMessage(message)
                print("Username '{}' is already taken".format(username))
                return
            else:
                cursor = conn.cursor()
                cursor.execute("INSERT INTO users (username, password) VALUES (?, ?)", (username, password))
                conn.commit()
                print("User '{}' registered".format(username))
                message = {'type': 'system_message', 'text': "User '{}' registered".format(username)}
                self.sendSystemMessage(message)
        except:
            print("ERROR")

        finally:
            conn.close()


    def login_user(self, username, password):
        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
        user = cursor.fetchone()
        islogged=any(self.factory.clients[p].username == username for p in self.factory.clients)
        if user and not(islogged):
            self.username = username
            print("User '{}' logged in".format(username))
            pay={"type":"Logged","id":str(self.id)}
            payload=json.dumps(pay).encode('utf8')
            self.sendMessage(payload,isBinary=False)

            message = {'type': 'player_connected', 'id': self.id}
            self.sendSystemMessage(message)

        else:
            message = {'type': 'system_message', 'text': "Invalid login credentials for user '{}'".format(username)}
            self.sendSystemMessage(message)
            print("Invalid login credentials for user '{}'".format(username))
        conn.close()

    def sendSystemMessage(self,message):
        payload = json.dumps(message).encode('utf8')
        self.sendMessage(payload,isBinary=False)
