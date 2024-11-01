//
//  QuestsListScreen.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 31/10/2024.
//
import SwiftUI

struct EDQuestsListScreen: View {
    let quests: [EDQuestDTO] = [
        EDQuestDTO(id: 1, name: "Test 1", details: "details", type: "Explore", system: nil),
        EDQuestDTO(id: 2, name: "Test 2", details: "details", type: "Combat", system: nil),
        EDQuestDTO(id: 3, name: "Test 3", details: "details", type: "Explore", system: EDSystemDTO(id: 1, name: "test", gameId: nil, scoopable: true)),
        EDQuestDTO(id: 4, name: "Test 4", details: "details", type: "Explore", system: nil),
        EDQuestDTO(id: 5, name: "Test 5", details: "details", type: "Explore", system: nil)
    ]

    @Binding
    var detailsVisible: Bool

    @State
    var visibleQuest: EDQuestDTO? = nil

    var visibleQuests: [EDQuestDTO] {
        quests.filter { visibleQuest == nil || $0.id == visibleQuest?.id }
    }

    var body: some View {
        VStack {
            ScrollView {
                ForEach(visibleQuests) { quest in
                    questRowView(quest)
                        .onTapGesture {
                            withAnimation {
                                visibleQuest = quest
                                detailsVisible = true
                            }
                        }
                }
            }
            Spacer()
        }
        .background {
            if let visibleQuest {
                if visibleQuest.system?.scoopable ?? false {
                    EDPlanetSceneView()
                } else {
                    EDStarSceneView(starType: .blueGiant)
                }
            }
        }
    }

    @ViewBuilder
    func questRowView(_ quest: EDQuestDTO) -> some View {
        VStack {
            HStack(spacing: 16) {
                Circle()
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2))
                    .frame(height: 44)
                    .background {
                        Image(questLogo(for: quest.type))
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                    }

                VStack(alignment: .leading) {
                    Text(quest.name)
                        .font(.headline)

                    if let name = quest.system?.name {
                        Text(name)
                            .font(.body)
                    }
                }

                Spacer()
            }
            .questCell

            if visibleQuest?.id == quest.id {
                Group {
                    Text(quest.details)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
                .questCell

                if let system = quest.system {
                    VStack {
                        Text("System: \(system.name)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                        Text("Scoopable: \(system.scoopable ?? false ? "Yes" : "No")")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .questCell
                }

                Button(action: {
                    withAnimation {
                        self.visibleQuest = nil
                        detailsVisible = false
                    }
                }, label: { Text("Back") })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }

    func questLogo(for type: String?) -> ImageResource {
        switch type {
        case "Explore": return .Exploration.rank9
        case "Combat": return .Combat.rank9
        default: return .planet
        }
    }
}

fileprivate extension View {
    @ViewBuilder
    var questCell: some View {
        padding()
            .background(.ultraThinMaterial.opacity(0.8))
            .background(.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 2))
            }
    }
}
