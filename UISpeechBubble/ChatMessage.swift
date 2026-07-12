//
//  ChatMessage.swift
//  UISpeechBubble
//
//  Created by Johny Vu on 7/11/26.
//
//  One line in the chat transcript. Kept tiny and Identifiable so SwiftUI's ForEach
//  can diff the list without extra bookkeeping.

import Foundation

struct ChatMessage: Identifiable {

    /// Who authored the line — the person or the on-device model.
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}
