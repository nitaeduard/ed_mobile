//
//  EDCommanderRankView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 19/03/2024.
//

import Foundation
import SwiftUI

struct EDCommanderRankView: View {
    let rank: Rank

    var body: some View {
        VStack {
            Grid {
                GridRow {
                    rankLevel("combat", text: "Combat", rank: rank.combat)
                    rankLevel("exploration", text: "Exploration", rank: rank.explore)
                    rankLevel("trading", text: "Trade", rank: rank.trade)
                }

                GridRow {
                    rankLevel("cqc", text: "CQC", rank: rank.cqc)
                    rankLevel("exo", text: "Exobiology", rank: rank.exobiologist)
                    rankLevel("merc", text: "Mercenary", rank: rank.soldier)
                }

                GridRow {
                    power("empire", text: "Empire", rank: rank.empire)
                    power("federation", text: "Federation", rank: rank.federation)
                    power("alliance", text: "Aliance", rank: 0)
                }

                Divider()

                GridRow {
                    Text("Crime: \(rank.crime)")
                    Text("Power: \(rank.power)")
                    Text("Service: \(rank.service)")
                }
            }
        }
    }

    @ViewBuilder
    func rankLevel(_ space: String, text: String, rank: Int) -> some View {
        VStack {
            EDRankIcon(space: space, rank: rank)
                .frame(width: 44, height: 44)
                .foregroundStyle(.primary)
            Text(text.localizedCapitalized)
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey(text.lowercased() + "_\(rank)"))
        }
    }

    @ViewBuilder
    func power(_ power: String, text: String, rank: Int) -> some View {
        VStack {
            Image("power/\(power)")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.primary)
            Text("\(text): \(rank)")
                .foregroundStyle(.secondary)
        }
    }
}

struct EDRankIcon: View {
    var space: String
    let rank: Int
    @State
    var doAnimate = false

    var body: some View {
        ZStack {
            ForEach(0 ... rank, id: \.self) { image in
                Image("\(space)/rank\(image)")
                    .resizable()
                    .scaledToFit()
                    .keyframeAnimator(initialValue: 0, trigger: doAnimate) { view, val in
                        view
                            .opacity(val)
                            .scaleEffect(
                                x: Double(image + 2) / Double(rank + 2),
                                y: Double(image + 2) / Double(rank + 2)
                            )
                    } keyframes: { _ in
                        KeyframeTrack {
                            for index in 0 ... rank {
                                CubicKeyframe(1.1 - Double(abs(image - index)), duration: 0.3)
                            }
                        }
                    }
            }
        }
        .onAppear {
            doAnimate = true
        }
    }

    init(space: String, rank: Int) {
        self.space = space
        self.rank = rank + 1
    }
}

#Preview("RankView") {
    EDCommanderRankView(rank: Rank(
        combat: 6,
        trade: 8,
        explore: 8,
        crime: 3,
        service: 3,
        empire: 1,
        federation: 1,
        power: 1,
        cqc: 0,
        soldier: 0,
        exobiologist: 8
    ))
}

#Preview("RankIcon") {
    EDRankIcon(space: "exploration", rank: 8)
        .frame(width: 44, height: 44)
        .padding()
}
