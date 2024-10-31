//
//  EDJournalFile.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 19/03/2024.
//

import Foundation
import SwiftData

@Model
final class EDJournalFile {
    @Attribute(.unique)
    var timestamp: String

    var content: String

    init(timestamp: String, content: String) {
        self.timestamp = timestamp
        self.content = content
    }
}
