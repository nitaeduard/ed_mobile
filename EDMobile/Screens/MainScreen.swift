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

    @State
    private var loggedIn: String = ""

    @State
    private var server = EDFrontierServer()

    @Environment(\.modelContext)
    private var context

    @Environment(\.webAuthenticationSession)
    private var webAuthenticationSession

    var body: some View {
        if #available(iOS 18, macOS 15, *) {
            TabView {
                Tab("Quests", image: "missions") {
                    NavigationStack {
                        EDQuestsListScreen(detailsVisible: $detailsVisible)
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
                            .background {
                                EDNebulaeBackground()
                            }
                    }
                }

                Tab("G", systemImage: "bell") {
                    EDGalnetScreen(detailsVisible: $detailsVisible)
                        .navigationTitle("My Note")
                }
//                Tab(value: "E") {
//                    EDEngineersScreen(detailsVisible: $detailsVisible)
//                }
//                Tab(value: "R") {
//                    EDRouteScreen(detailsVisible: $detailsVisible)
//                }
//                Tab(value: "S") {
//                    EDShipsScreen(detailsVisible: $detailsVisible)
//                }
            }
            .environmentObject(server)
            .tabViewStyle(.sidebarAdaptable)

            .onAppear {
                Task {
                    do {
                        try await server.loadData()
                        loggedIn = "CMDR \(server.profile?.commander.name ?? "...")"
                    } catch {
                        print(error)
                    }
                }
            }
        } else {
            Text("")
        }

        ///         .customizationID("com.myApp.home")

        ///
        ///         TabSection("Categories") {
        ///             Tab("Climate", systemImage: "fan") {
        ///                 ClimateView()
        ///             }
        ///             .customizationID("com.myApp.climate")
        ///
        ///             Tab("Lights", systemImage: "lightbulb") {
        ///                 LightsView()
        ///             }
        ///             .customizationID("com.myApp.lights")
        ///         }
        ///         .customizationID("com.myApp.browse")
        ///     }
        ///     .tabViewStyle(.sidebarAdaptable)
        ///     .tabViewCustomization($customization)

//        VStack {
//            switch visibleScreen {
//            case .quests:
//                EDQuestsListScreen(detailsVisible: $detailsVisible)
//            case .galnet:
//                EDGalnetScreen(detailsVisible: $detailsVisible)
//            case .engineers:
//                EDEngineersScreen(detailsVisible: $detailsVisible)
//            case .route:
//                EDRouteScreen(detailsVisible: $detailsVisible)
//            case .ship:
//                EDShipsScreen(detailsVisible: $detailsVisible)
//            }
//        }
//        .safeAreaInset(edge: .top) {
//            topBar
//                .background(.blue.opacity(0.1))
//                .background(.thickMaterial, ignoresSafeAreaEdges: .all)
//        }
//        .safeAreaInset(edge: .bottom) {
//            if !detailsVisible {
//                bottomBar
//                    .background(.blue.opacity(0.1))
//                    .background(.thickMaterial, ignoresSafeAreaEdges: .all)
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
//            }
//        }
//        .frame(maxWidth: .infinity)
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
            bottomBarButton(.galnet, image: .galnet)
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

struct EDNebulaeBackground: View {
    @State var startDate = Date()

    var body: some View {
//        TimelineView(.animation) { _ in
            Rectangle()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .colorEffect(
                    ShaderLibrary.simpleVertexShader(
                        .float(startDate.timeIntervalSinceNow)
                    )
                )
//        }0
    }
}

#Preview {
    // EDMainScreen()
    EDNebulaeBackground()
        .preferredColorScheme(.dark)
}
