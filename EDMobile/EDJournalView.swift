//
//  EDJournalView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 05/07/2024.
//

import Foundation
import SwiftData
import SwiftUI

struct EDJournalView {
    @Query
    var journals: [EDJournalFile]

    @State
    var selected: EDJournalFile?

    @State
    var parsedItems: [EventRow] = []
}

extension EDJournalView: View {
    var body: some View {
        HStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach(parsedItems) { event in
                        HStack {
                            Text(event.timestamp)
                            Spacer()
                            Text(event.event)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }

            List(journals, selection: $selected) { item in
                Text(item.timestamp)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item != selected {
                            selected = item
                            parseItems()
                        }
                    }
                    .bold(item == selected)
                    .background(.tertiary.opacity(item == selected ? 1 : 0))
            }
        }
    }

    func parseItems() {
        guard let selected else {
            return
        }
        Task {
            let rows = selected.content
                .split(separator: "\r\n")
                .compactMap { str -> EventRow? in
                    guard let data = str.data(using: .utf8) else {
                        return nil
                    }
                    do {
                        var row = try JSONDecoder().decode(EventRow.self, from: data)
                        row.content = String(str)
                        return row
                    } catch {
                        return nil
                    }
                }
            await MainActor.run {
                parsedItems = rows
            }
        }
    }

    struct EventRow: Identifiable, Codable {
        let id = UUID()
        var timestamp: String
        var event: String
        var content: String?

        enum CodingKeys: String, CodingKey {
            case timestamp
            case event
        }
    }
}
