import sqlite3
import asyncio
import json
from autobahn.asyncio.websocket import WebSocketServerProtocol, WebSocketServerFactory
import protocol



class MyServerFactory(WebSocketServerFactory):

    def __init__(self, url):
        super().__init__(url)
        self.protocol = protocol.MyServerProtocol
        self.clients = {}
        self.id=0
        # cria tabela players se ela não existir
        conn = sqlite3.connect('players.db')
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS players
                     (id INTEGER PRIMARY KEY, pos TEXT, rot TEXT)''')
        conn.commit()
        conn.close()

        conn = sqlite3.connect('users.db')
        cursor = conn.cursor()

#        cria a tabela "users" caso ela não exista
        cursor.execute('''CREATE TABLE IF NOT EXISTS users
                (id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT NOT NULL,
                password TEXT NOT NULL)''')
        conn.commit()
        # fecha a conexão com o banco de dados
        conn.close()



    def register(self, client):
        self.clients[self.id]=client
        self.create_player(self.id)
        self.set_player_id(client, self.id)
        self.id+=1
        print("Novo cliente registrado. Total de clientes: {}".format(len(self.clients)))
        print(self.clients)


    def unregister(self, client):
        print("Cliente removido. Total de clientes: {}".format(len(self.clients)))
        conn = sqlite3.connect('players.db')
        cursor = conn.cursor()
        cursor.execute('DELETE FROM players WHERE id = ?', (client.id,))
        conn.commit()
        conn.close()

        del self.clients[client.id]


    def set_player_id(self, client, player_id):
        client.id=player_id


    def create_player(self, player_id):
        conn = sqlite3.connect('players.db')
        c = conn.cursor()

        # cria um novo jogador
        result = c.execute("SELECT * FROM players WHERE id=?", (player_id,)).fetchone()

        if result is None:
            c.execute("INSERT INTO players (id, pos, rot) VALUES (?, ?, ?)", (player_id, "(0,0,0)", "(0,0,0)"))
        conn.commit()
        conn.close()


    def broadcast_message(self, message, exclude=None):
        payload = json.dumps(message).encode('utf8')
        for client in self.clients:
            if self.clients[client] is not exclude:
                self.clients[client].sendMessage(payload, isBinary=False)


if __name__ == '__main__':
    factory = MyServerFactory("ws://localhost:9000")
    asyncio.get_event_loop().run_until_complete(asyncio.gather(
        asyncio.get_event_loop().create_server(factory, '0.0.0.0', 9000),
    ))
    asyncio.get_event_loop().run_forever()
