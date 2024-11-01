//
//  GalnetScreen.swift
//  EDMobile
//
//  Created by Eduard Radu Nita on 31/10/2024.
//
import SwiftUI

struct EDGalnetScreen: View {
    @Binding
    var detailsVisible: Bool

    @StateObject
    var model = EDGalnetViewModel()

    var body: some View {
        ScrollView {
            ForEach(model.galnetData, id: \.id) { data in
                VStack(alignment: .leading, spacing: 0) {
                    articleImage(data.url)
                    articleHeader(data.title, date: data.date)
                    articleContent(data.text)
                }
            }
        }
        .onAppear {
            model.loadData()
        }
    }
}

extension EDGalnetScreen {
    @ViewBuilder
    fileprivate func articleImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success:
                phase.image?
                    .resizable()
                    .scaledToFit()
                    .background {
                        GeometryReader { geometry in
                            phase.image?
                                .resizable()
                                .scaledToFit()
                                .transformEffect(
                                    CGAffineTransform(scaleX: 1, y: -1)
                                        .translatedBy(x: 0, y: -geometry.size.height * 2)
                                )
                        }
                    }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    fileprivate func articleHeader(_ title: String, date: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(date)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    fileprivate func articleContent(_ text: String) -> some View {
        VStack {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .padding()
        }
        .background(Color.black)
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
        guard galnetData.count == 0 else {
            logger.error("tring to reload data")
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
                text: $0.attributes.body.value,
                image: $0.attributes.field_galnet_image
            )
        }
    }

    func loadComunityGoals() {
        guard galnetData.count == 0 else {
            logger.error("tring to reload data")
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

extension EDGalnetViewModel.GalnetData {
    var url: URL? {
        guard let image else {
            return URL(string: "https://hosting.zaonce.net/elite-dangerous/galnet/NewsImageNewEquipmentSale.png")
        }
        return URL(string: "https://hosting.zaonce.net/elite-dangerous/galnet/\(image).png")
    }
}

extension EDGalnetScreen {
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
