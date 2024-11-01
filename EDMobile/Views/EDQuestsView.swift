//
//  EDQuestsView.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 05/10/2024.
//
import SwiftUI

struct EDQuestsView: View {
    @StateObject
    var model: EDQuestsManager = EDQuestsManager()

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Quests")
            List {
                ForEach(model.quests) { quest in
                    Text(quest.name)
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                Button(action: {
                }, label: {
                    Text("Add")
                })
            }
        }
        .background {
            LinearGradient(colors: backColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .onAppear {
            model.setup()
        }
    }

    var backColors: [Color] {
        colorScheme == .dark ?
            [.black, .black, .black, .blue] :
            [.blue.opacity(0.5), .blue.opacity(0.4), .blue.opacity(0.3), .blue.opacity(0.1)]
    }
}

struct EDSystemDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let gameId: Int64?
    let scoopable: Bool?
}

struct EDQuestDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let details: String
    let type: String?
    let system: EDSystemDTO?
}

class EDQuestsManager: ObservableObject {
    @Published
    var quests: [EDQuestDTO] = []

    let api: EDAPIProtocol

    init(api: EDAPIProtocol = EDApi()) {
        self.api = api
    }

    func setup() {
        Task {
            quests = await api.getQuests()
        }
    }
}

protocol EDAPIProtocol {
    func getQuests() async -> [EDQuestDTO]
}

class EDApi: EDAPIProtocol {
    let session: URLSession = .shared

    let baseURL = URL(string: "https://edq-api.vercel.app")

    func getQuests() async -> [EDQuestDTO] {
        guard let url = URL(string: "/quests", relativeTo: baseURL) else {
            return []
        }
        do {
            let request = URLRequest(url: url)
            let (data, urlResponse) = try await session.data(for: request)
            guard let response = urlResponse as? HTTPURLResponse else {
                return []
            }
            switch response.statusCode {
            case 200:
                return try JSONDecoder().decode([EDQuestDTO].self, from: data)
            default:
                break
            }
        } catch {
            print("Error getting quests \(error)")
        }
        return []
    }
}

struct EDQuestsAdd: View {
    @StateObject
    var model: EDQuestsAddModel = EDQuestsAddModel()

    @State
    var focusedField: FocusedField?

    @FocusState
    var focusState: FocusedField?

    enum FocusedField: Hashable {
        case title, category, details, system
    }

    var body: some View {
        VStack {
            Text("Add quest")

            inputRow("Title", value: Text(model.title), item: .title) {
                TextField("", text: $model.title)
                    .focused($focusState, equals: .title)
            }
            inputRow("Category", value: Text(model.category), item: .category) {
                TextField("", text: $model.category)
//                    .focused($focusedField, equals: .category)
            }
            inputRow("Details", value: Text(model.details), item: .details) {
                TextEditor(text: $model.details)
//                    .focused($focusedField, equals: .details)
            }
            inputRow("System", value: Text(model.system), item: .system) {
                TextField("", text: $model.system)
//                    .focused($focusedField, equals: .system)
            }
            Spacer()
        }
    }

    @ViewBuilder @MainActor
    func inputRow<Content: View>(_ title: String, value: Text, item: FocusedField, @ViewBuilder content: () -> Content) -> some View {
        if focusedField == item || focusedField == nil {
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .bold(focusedField == item)
                    Spacer()
                    Image(systemName: "pencil")
                }
                if focusedField == item {
                    content()
                        .frame(maxWidth: .infinity)
                } else {
                    value
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(.tertiary)
            .padding(.horizontal)
            .transition(.blurReplace(.upUp))
            .onTapGesture {
                tapOnField(on: item)
            }
        }
    }

    @MainActor
    func tapOnField(on item: FocusedField) {
        if focusedField == item {
            withAnimation {
                focusedField = nil
                focusState = nil
            }
        } else {
            withAnimation {
                focusedField = item
                focusState = item
            }
        }
    }
}

class EDQuestsAddModel: ObservableObject {
    @Published
    var title: String = ""

    @Published
    var category: String = ""

    @Published
    var details: String = ""

    @Published
    var system: String = ""
}

#Preview {
    EDQuestsAdd()
//    NavigationSplitView {
//        List {
//            NavigationLink { EDQuestsView() } label: { Text("Quests") }
//        }
//    } detail: {
//        Text("Select an item")
//    }
}
