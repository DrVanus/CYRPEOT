//
//  ChatBubble.swift
//  CryptoSageAI4
//
//  Created by DM on 2/27/25.
//


import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant || message.role == .system {
                VStack(alignment: .leading) {
                    Text(message.content)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.yellow.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

struct ChatBubble_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatBubble(message: ChatMessage(role: .assistant, content: "Assistant response"))
            ChatBubble(message: ChatMessage(role: .user, content: "User message"))
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}