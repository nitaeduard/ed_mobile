//
//  EDMainScreen.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 06/10/2024.
//
import SwiftUI

struct EDMainScreen: View {
    @State
    var visibleScreen: Screen = .galnet

    @State
    var detailsVisible: Bool = false

    var body: some View {
        VStack {
            switch visibleScreen {
            case .quests:
                EDQuestsListView(detailsVisible: $detailsVisible)
            case .galnet:
                EDGalnetView(detailsVisible: $detailsVisible)
            case .engineers:
                EDEngineersView(detailsVisible: $detailsVisible)
            case .route:
                EDRouteView(detailsVisible: $detailsVisible)
            case .ship:
                EDShipsView(detailsVisible: $detailsVisible)
            }
        }
        .safeAreaInset(edge: .top) {
            topBar
                .background(.blue.opacity(0.1))
                .background(.thickMaterial, ignoresSafeAreaEdges: .all)
        }
        .safeAreaInset(edge: .bottom) {
            if !detailsVisible {
                bottomBar
                    .background(.blue.opacity(0.1))
                    .background(.thickMaterial, ignoresSafeAreaEdges: .all)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct EDGalnetView: View {
    @Binding
    var detailsVisible: Bool

    @StateObject
    var model = EDGalnetViewModel()

    var body: some View {
        VStack {
            ScrollView {
                ForEach(model.galnetData, id: \.id) { data in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Text(data.title)
                                .font(.headline.bold())
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(data.date)
                                .font(.caption.bold())
                        }
                        .padding()
                        .background(.thinMaterial)

                        Text(data.text)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                    .background {
                        AsyncImage(url: URL(string: "https://hosting.zaonce.net/elite-dangerous/galnet/NewsImageNewEquipmentSale.png")) { phase in
                            switch phase {
                            case .success:
                                Image(phase.image)
                                    .resizable()
                                    .scaledToFit()
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            model.loadData()
        }
    }
}

class EDGalnetViewModel: ObservableObject {
    @Published
    var galnetData: [GalnetData] = []

    var session: URLSession = .shared

    struct GalnetData: Codable {
        var id: String
        var date: String
        var title: String
        var text: String
        var image: String?
    }

    init() {
        loadData()
    }

    func loadData() {
        print("load data")
        guard galnetData.count == 0 else {
            print("tring to reload data")
            return
        }

        Task {
            do {
                let data = try await getGalnetArticles()
                let articles = try processGalnetResponse(data)
                await MainActor.run {
                    galnetData = articles
                }
            } catch {
                logger.error("Error loading galnet")
            }
        }
    }

    func getGalnetArticles() async throws -> Data {
        guard let url = URL(string: "https://cms.zaonce.net/en-GB/jsonapi/node/galnet_article?&sort=-published_at&page%5Boffset%5D=0&page%5Blimit%5D=12") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try checkResponse(response)
        return data
    }

    func checkResponse(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    func processGalnetResponse(_ data: Data) throws -> [GalnetData] {
        struct Response: Codable {
            struct Body: Codable {
                var value: String
                var format: String?
                var processed: String?
                var summary: String?
            }

            struct Attributes: Codable {
                var langcode: String
                var status: Bool
                var title: String
                var created: String
                var published_at: String
                var body: Body
                var field_galnet_date: String
                var field_galnet_image: String?
            }

            struct Article: Codable {
                var type: String
                var id: String
                var attributes: Attributes
            }

            var data: [Article]
        }

        let galnetInfo = try JSONDecoder().decode(Response.self, from: data)
        return galnetInfo.data.compactMap {
            GalnetData(
                id: $0.id,
                date: $0.attributes.field_galnet_date,
                title: $0.attributes.title,
                text: $0.attributes.body.value
            )
        }
    }

    func loadComunityGoals() {
        print("load data")
        guard galnetData.count == 0 else {
            print("tring to reload data")
            return
        }
        guard let url = URL(string: "https://api.orerve.net/2.0/website/initiatives/list?lang=en") else {
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("*/*", forHTTPHeaderField: "Accept")

        Task {
            do {
                let (data, response) = try await session.data(for: request)
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                print("Response: \(response) \(String(data: data, encoding: .utf8)!)")
                let galnetInfo = try JSONDecoder().decode([GalnetData].self, from: data)
                await MainActor.run {
                    galnetData = galnetInfo
                }
            } catch {
                logger.error("Error loading galnet")
            }
        }
    }
}

extension EDGalnetView {
    func comunityGoals() -> String {
        "https://api.orerve.net/2.0/website/initiatives/list?lang=en"
        "Accept: */* will return JSON, as per the response header Content-Type: application/json."
        "Accept: text/xml will return XML as per the response header Content-Type: application/xml."
        return ""

        //        Note the lang=en parameter passed. These languages are known to be supported:
        //        de - German
        //        en - English
        //        fr - French
        //        es - Spanish
        //        pt - Portugese (Brazilian?)
        //        ru - Russian

        //        Commander
        //
        //        Return informations about the current logged- in commander: ranks, a lot of statistics(wealth, combat / trade / exploration statistics...)
        //
        //        URL: https: // api.orerve.net/2.0/website/user/commanders

        //        Squadrons
        //        Squadron tags
        //        Return the list of squadron tags (languages tags, activities types...).
        //        URL: https://api.orerve.net/2.0/website/squadron/tags/available

        //        List
        //
        //        Return the list of squadrons.
        //
        //        URL: https://api.orerve.net/2.0/website/squadron/list?platform=PC&name=test
        //
        //        Parameters:
        //
        //        platform: can be PC, PS4 or XBOX
        //        name: squadron name filter
        //        usertags: a integer id representing the tag (solo, cqc...) for filtering. You can get the identifier using the tags endpoint.
        //        Leaderboards
        //
        //        Return the leaderboards of squadrons.
        //
        //        URL: https://api.orerve.net/2.0/website/squadron/season/leaderboards?leaderboardType=cqc&squadronId=-1&platform=PC
        //
        //        Parameters:
        //
        //        squadronId: must be -1
        //        leaderboardType: can be combat, trade, exploration, bgs, exploration, powerplay, aegis, cqc
        //        platform: can be PC, PS4 or XBOX
        //        Informations
        //
        //        Return informations about a specific squadron.
        //
        //        URL: https://api.orerve.net/2.0/website/squadron/info?platform=PC&tag=ech0
        //
        //        Parameters:
        //
        //        tag: the squadron tag
        //        platform: can be PC, PS4 or XBOX
        //        Members
        //
        //        Return the member of a squadron. You need to be a member of the squadron to see the informations.
        //
        //        URL: https://api.orerve.net/2.0/website/squadron/member/list?squadronId=2838
        //
        //        Parameters:
        //
        //        squadronId: identifier of the squadron that can be retrievied from the squadrons information endpoint.
        // https://companion.orerve.net/fleetcarrier
        // https://companion.orerve.net/market
        // https://companion.orerve.net/shipyard
        // https://companion.orerve.net/journal/2024/03/18
    }
}

struct EDEngineersView: View {
    @Binding
    var detailsVisible: Bool

    var body: some View {
        Text("Engineers")
    }
}

struct EDRouteView: View {
    @Binding
    var detailsVisible: Bool

    var body: some View {
        Text("Route")
    }
}

struct EDShipsView: View {
    @Binding
    var detailsVisible: Bool

    var body: some View {
        Text("Ships")
    }
}

extension EDMainScreen {
    enum Screen {
        case quests
        case galnet
        case engineers
        case route
        case ship
    }

    var gameDate: String {
        let currentDate = Date()
        let calendar = Calendar.current

        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        let day = calendar.component(.day, from: currentDate)

        let eliteDangerousYear = year + 1286

        return String(format: "%02d-%02d-%d", month, day, eliteDangerousYear)
    }

    @ViewBuilder
    var topBar: some View {
        HStack {
            Spacer()
            Text(gameDate)
                .font(.headline.bold())
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    @ViewBuilder
    var bottomBar: some View {
        HStack {
            Spacer()
            bottomBarButton(.quests, image: .universalCartographics)
            bottomBarButton(.galnet, image: .galNet)
            bottomBarButton(.engineers, image: .engineer)
            bottomBarButton(.route, image: .route)
            bottomBarButton(.ship, image: .ship)
            Spacer()
        }
        .padding(8)
    }

    @ViewBuilder
    func bottomBarButton(_ screen: Screen, image: ImageResource) -> some View {
        Button(action: {
            if visibleScreen == screen {
                return
            }
            withAnimation {
                visibleScreen = screen
            }
        }) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(16)
                .foregroundStyle(visibleScreen == screen ? .primary : .secondary)
        }
    }
}

struct EDQuestsListView: View {
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
        .background {
            if let visibleQuest, visibleQuest.system?.scoopable ?? false {
                EDPlanetSceneView()
            } else {
                EDStarSceneView(starType: .blueGiant)
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
            .padding()
            .background(.ultraThinMaterial.opacity(0.8))
            .background(.blue.opacity(0.1))
            .cornerRadius(16)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), style: StrokeStyle(lineWidth: 2))
            }
            .padding(.horizontal)

            if let visibleQuest {
                ScrollView {
                    Text(visibleQuest.details)
                        .multilineTextAlignment(.leading)
                }

                Button(action: {
                    withAnimation {
                        self.visibleQuest = nil
                        detailsVisible = false
                    }
                }, label: { Text("Back") })
            }
        }
    }

    func questLogo(for type: String?) -> ImageResource {
        switch type {
        case "Explore": return .Exploration.rank9
        case "Combat": return .Combat.rank9
        default: return .planet
        }
    }
}

#Preview {
    EDMainScreen()
        .preferredColorScheme(.dark)
}
