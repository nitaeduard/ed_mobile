//
//  ContentView.swift
//  E:D Mobile
//
//  Created by Eduard Radu Nita on 19/03/2024.
//

import AuthenticationServices
import SwiftData
import SwiftUI

struct EDContentView: View {
    @Environment(\.webAuthenticationSession)
    private var webAuthenticationSession

    @State
    private var loggedIn: String = ""

    @State
    private var server = EDFrontierServer()

    @Environment(\.modelContext)
    private var context

    var body: some View {
        NavigationSplitView {
            List {
                // NavigationLink { EDGalnetView() } label: { Text("Gallnet") }
                NavigationLink { EDCommanderView().environmentObject(server) } label: { Text("Commander") }
                NavigationLink { EDJournalView() } label: { Text("Journal") }
                NavigationLink { EDQuestsView() } label: { Text("Quests") }
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            #endif
            .toolbar {
                #if os(iOS)
                    if loggedIn.isEmpty {
                        Button("Log In") {
                            Task {
                                do {
                                    try await server.showLogin(using: webAuthenticationSession)
                                    loggedIn = "CMDR \(server.profile?.commander.name ?? "...")"
                                } catch {
                                    loggedIn = "Error"
                                    // Respond to any authorization errors.
                                    print(error.localizedDescription)
                                }
                            }
                        }
                    } else {
                        Text("O7, \(loggedIn)!")
                    }
                #endif
            }
        } detail: {
            Text("Select an item")
        }
        .toolbar {
            if !loggedIn.isEmpty {
                Text("O7, \(loggedIn)!")
            } else {
                Text("O7!")
                Button("Sign In") {
                    Task {
                        do {
                            try await server.showLogin(using: webAuthenticationSession)
                            loggedIn = "CMDR \(server.profile?.commander.name ?? "...")"
                        } catch {
                            loggedIn = "Error"
                            // Respond to any authorization errors.
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        .environmentObject(server)
        .onAppear {
            Task {
                do {
//                    try await server.loadData()
//                    loggedIn = "CMDR \(server.profile?.commander.name ?? "...")"
                } catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    EDContentView()
}

// struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
//
//    var body: some View {
//        NavigationSplitView {
//            List {
//                ForEach(items) { item in
//                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
//                    } label: {
//                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
//                    }
//                }
//                .onDelete(perform: deleteItems)
//            }
//            #if os(macOS)
//            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
//            #endif
//            .toolbar {
//                #if os(iOS)
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        EditButton()
//                    }
//                #endif
//                ToolbarItem {
//                    Button(action: addItem) {
//                        Label("Add Item", systemImage: "plus")
//                    }
//                }
//            }
//        } detail: {
//            Text("Select an item")
//        }
//    }
//
//    private func addItem() {
//        withAnimation {
//            let newItem = Item(timestamp: Date())
//            modelContext.insert(newItem)
//        }
//    }
//
//    private func deleteItems(offsets: IndexSet) {
//        withAnimation {
//            for index in offsets {
//                modelContext.delete(items[index])
//            }
//        }
//    }
// }
//
// #Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
// }
