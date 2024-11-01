//
//  EDMobileApp.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 19/03/2024.
//

import SwiftData
import SwiftUI

class EDLocalData {
    private static var container: ModelContainer = {
        let schema = Schema([EDJournalFile.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    static var shared: ModelContainer { container }
}

@main
struct EDMobileApp: App {
    var body: some Scene {
        WindowGroup {
//            #if os(macOS)
//                EDContentView()
//            #else
                EDMainScreen()
//            #endif
        }
        .modelContainer(EDLocalData.shared)
    }
}
