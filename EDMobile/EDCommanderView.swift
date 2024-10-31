//
//  EDCommanderView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 19/03/2024.
//

import Foundation
import SwiftUI

struct EDCommanderView: View {
    @EnvironmentObject
    var server: EDFrontierServer

    var body: some View {
        VStack {
            if let profile = server.profile {
                Text("Commander: \(profile.commander.name)")
                HStack {
                    Image(.credits)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .foregroundStyle(.primary)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Credits: \(profile.commander.credits)")
                            .foregroundStyle(.primary)
                        Text("Debt: \(profile.commander.debt)")
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                }
                Text("On foot: \(profile.commander.onfoot ? "yes" : "no") ")
                if profile.commander.docked {
                    Text("Docked: " + (profile.ship?.station?.name ?? ""))
                }
                if let ship = profile.ship {
                    Text("Current ship: \(ship.name)  \(ship.shipName ?? "")")
                    Text("System: \(ship.starsystem?.name ?? "")")
                }

                EDCommanderRankView(rank: profile.commander.rank)
            } else {
                Text("Commander")
            }
        }
        .task {
            guard server.profile == nil else {
                // profile already loaded
                return
            }
            do {
                try await server.loadData()
            } catch {
                print("Error getting profile")
            }
        }
    }
}
