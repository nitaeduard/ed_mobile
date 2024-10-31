//
//  FrontierServer.swift
//  E:D Mobile
//
//  Created by Eduard Radu Nita on 03/02/2024.
//

import AuthenticationServices
import CryptoKit
import Foundation
import OSLog
import SwiftData
import SwiftUI

let logger = Logger(subsystem: "edmobile", category: "frontier")

extension UserDefaults {
    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "EDToken") }
        set { UserDefaults.standard.set(newValue, forKey: "EDToken") }
    }

    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "EDTokenRefresh") }
        set { UserDefaults.standard.set(newValue, forKey: "EDTokenRefresh") }
    }
}

class EDFrontierServer: ObservableObject {
    private let frontierServer = "https://auth.frontierstore.net"
    private let capiServer = "https://companion.orerve.net"

    private let redirectUri = "edmobile"
    private let clientKey = "3d5e633c-64d7-4f1a-9298-0c2fef730dd7"

    @Published
    var userLoggedIn: Bool = UserDefaults.accessToken != nil

    @Published
    var profile: ProfileDTO?
}

extension EDFrontierServer {
    func loadData() async throws {
        do {
            try await getProfile()
        } catch let error as URLError {
            if error.code == .userAuthenticationRequired {
                throw error
            }
        } catch {
        }
        do {
            try await getJournal()
        } catch let error as URLError {
            if error.code == .userAuthenticationRequired {
                throw error
            }
        } catch {
        }
    }

    func getProfile() async throws {
        guard let data = try await frontierRequest(path: "/profile") else {
            logger.error("/profile error: cannotDecodeContentData")
            throw URLError(.cannotDecodeContentData)
        }

        let profile = try JSONDecoder().decode(ProfileDTO.self, from: data)
        await MainActor.run {
            self.profile = profile
            if let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        }
    }

    func getCommanderInfo() async {
    }

    func getJournal() async throws {
        var date = Date()
        while date > Date(timeIntervalSince1970: 0) {
            do {
                let response = try await getJournal(date: date)
                let content = String(data: response.data, encoding: .utf8) ?? ""
                try await MainActor.run {
                    let context = EDLocalData.shared.mainContext
                    context.insert(
                        EDJournalFile(
                            timestamp: response.timestamp,
                            content: content
                        )
                    )
                    try context.save()
                }
                logger.info("done loading journal \(date.description)")
                return
            } catch {
                if case URLError.fileDoesNotExist = error {
                    date = date.addingTimeInterval(-60 * 60 * 24)
                    logger.info("no journal found, trying previous day \(date)")
                } else {
                    logger.error("error loading journal: \(error)")
                    return
                }
            }
        }

        func getJournal(date: Date) async throws -> (timestamp: String, data: Data) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            let timestamp = formatter.string(from: date)

            guard let data = try await frontierRequest(path: "/journal/\(timestamp)") else {
                logger.error("/profile error: cannotDecodeContentData")
                throw URLError(.cannotDecodeContentData)
            }

            return (timestamp, data)
        }
    }
}

// MARK: - Login

extension EDFrontierServer {
    func showLogin(using webAuthenticationSession: WebAuthenticationSession) async throws {
        let sessionState = UUID().uuidString.urlEncoded
        let codeVerifier = (UUID().uuidString + UUID().uuidString).urlEncoded
            .replacingOccurrences(of: "-", with: "")
            .prefix(32)
            .lowercased()
        // Needs to be a minimum of 43 chars apparently, so use two UUIDs. Should already be URL-safe.
        let codeChallenge = SHA256
            .hash(data: codeVerifier.data(using: .ascii)!)
            .data
            .base64URLEncode
        guard let url = URL(
            string: "auth",
            relativeTo: URL(string: frontierServer))?
            .appending(queryItems: [
                URLQueryItem(name: "scope", value: "auth capi"),
                URLQueryItem(name: "audience", value: "frontier,steam,epic"),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: clientKey),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "state", value: sessionState),
                URLQueryItem(name: "redirect_uri", value: "\(redirectUri)://auth"),
            ]) else {
            logger.error("error showing login: bad url")
            throw URLError(.badURL)
        }

        // Perform the authentication and await the result.
        let callback = try await webAuthenticationSession.authenticate(using: url, callbackURLScheme: redirectUri)
        try await getToken(using: callback, state: sessionState, codeVerifier: codeVerifier)
    }

    struct TokenResponse: Codable {
        var access_token: String
        var token_type: String
        var expires_in: Int
        var refresh_token: String
    }

    private func getToken(using callback: URL, state: String, codeVerifier: String) async throws {
        guard let components = URLComponents(url: callback, resolvingAgainstBaseURL: false) else {
            logger.error("cannot construct getToken URL")
            return
        }
        guard let queryItems = components.queryItems,
              let code = queryItems.first(where: { $0.name == "code" })?.value,
              let callbackState = queryItems.first(where: { $0.name == "state" })?.value,
              callbackState == state
        else {
            logger.error("cannot construct getToken URL: invalid callbackState")
            return
        }
        let url = URL(string: "/token", relativeTo: URL(string: frontierServer))?.appending(queryItems: [
            URLQueryItem(name: "redirect_uri", value: "\(redirectUri)://auth"),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "client_id", value: clientKey),
            URLQueryItem(name: "code_verifier", value: codeVerifier),
            URLQueryItem(name: "code", value: code)
        ])
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = url?.query()?.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("getToken error: badServerResponse")
            throw URLError(.badServerResponse)
        }
        switch httpResponse.statusCode {
        case 200:
            let json = try JSONDecoder().decode(TokenResponse.self, from: data)
            UserDefaults.accessToken = json.access_token
            UserDefaults.refreshToken = json.refresh_token
            userLoggedIn = true
        case 404:
            throw URLError(.resourceUnavailable)
        default:
            return
        }
    }
}

private extension EDFrontierServer {
    func frontierRequest(path: String) async throws -> Data? {
        guard let url = URL(string: path, relativeTo: URL(string: capiServer)) else {
            logger.error("cannot construct capi URL for \(path)")
            throw URLError(.badURL)
        }
        guard let token = UserDefaults.accessToken else {
            logger.error("cannot start capi request: userAuthenticationRequired")
            throw URLError(.userAuthenticationRequired)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("error processing capi request: badServerResponse")
            throw URLError(.badServerResponse)
        }
        switch httpResponse.statusCode {
        case 200:
            return data
        case 404:
            logger.error("error processing capi request: resourceUnavailable")
            throw URLError(.resourceUnavailable)
        case 204:
            logger.error("error processing capi request: no data")
            throw URLError(.fileDoesNotExist)
        default:
            logger.error("error processing capi request: \(httpResponse.statusCode)")
            return nil
        }
    }
}

private extension Data {
    var base64URLEncode: String {
        return base64EncodedString().urlEncoded
    }
}

private extension String {
    var urlEncoded: String {
        return replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}
