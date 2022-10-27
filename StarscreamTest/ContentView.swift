//
//  ContentView.swift
//  StarscreamTest
//
//  Created by Ethan Kisiel on 10/26/22.
//

import SwiftUI
import SocketIO
var clientId: String = ""
struct ClientMessage: Hashable
{
    let clientId: String
    let message: String
    
    init(_ clientId: String, _ message: String)
    {
        self.clientId = clientId
        self.message = message
    }
}

final class Service: ObservableObject
{
    private var manager = SocketManager(socketURL: URL(string: "http://24.75.155.201:8080")!, config: [.log(true), .compress])
    
    @Published var messages = [ClientMessage]()
    
    init()
    {
        let socket = manager.defaultSocket
        socket.on(clientEvent: .connect)
        { (data, ack) in
            print("Connected")
            socket.emit("test_custom_event", "Hi flask socket server")
            socket.emit("recieve_id")
        }
        
        socket.on("accept_id")
        { [weak self] (data, ack) in
            if let data = data[0] as? [String: String],
               let rawMessage = data["id"]
            {
                clientId = rawMessage
            }
        }
        
        socket.on("ios_client_event")
        { [weak self] (data, ack) in
            if let data = data[0] as? [String: String],
               let rawMessage = data["message"],
               let clientId = data["client_id"]
            {
                DispatchQueue.main.async
                {
                    let messageToAdd = ClientMessage(clientId, rawMessage)
                    self?.messages.append(messageToAdd)
                }
                
            }
        }
        
        socket.connect()
    }
    
    func sendMessage(_ message: String)
    {
        let event = ["client_id": clientId, "message": message]
        manager.defaultSocket.emit("test_custom_event", event)
    }
}

struct ContentView: View {
    @ObservedObject var socketClient = Service()
    @State var sendMessage: String = ""
    var body: some View {
        VStack
        {
            if !socketClient.messages.isEmpty
            {
                List
                {
                    ForEach(socketClient.messages, id: \.self)
                    {
                        Text("\($0.clientId): \($0.message)")
                    }
                }
            }
            else
            {
                Text("No Messages")
            }
            
            TextField("Enter Message", text: $sendMessage)
            Button("Send Message")
            {
                socketClient.sendMessage(sendMessage)
                sendMessage = ""
            }.disabled(sendMessage.isEmpty)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
