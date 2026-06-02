import Foundation
#if canImport(Supabase)
import Supabase
#endif

enum WanderRemoteError: Error, Equatable {
    case notConfigured
    case notAuthenticated
    case notImplemented(String)
    case invalidResponse(String)
}

struct EmptyRPCResponse: Codable, Equatable {}

@MainActor
protocol RemoteProcedureCalling {
    func call<Value: Decodable, Params: Encodable>(
        _ name: String,
        params: Params,
        decoder: JSONDecoder
    ) async throws -> Value
}

extension RemoteProcedureCalling {
    func call<Value: Decodable, Params: Encodable>(_ name: String, params: Params) async throws -> Value {
        try await call(name, params: params, decoder: RemoteDecoding.decoder)
    }
}

enum RemoteDecoding {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

@MainActor
final class WanderSupabaseClient: RemoteProcedureCalling {
    let configuration: WanderBackendConfiguration
    private let authSession: AuthSessionProviding
    private let urlSession: URLSession

    init(configuration: WanderBackendConfiguration, authSession: AuthSessionProviding, urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.authSession = authSession
        self.urlSession = urlSession
    }

    var isConfigured: Bool {
        configuration.isSupabaseConfigured
    }

    func authenticatedHeaders() async throws -> [String: String] {
        guard configuration.isSupabaseConfigured else {
            throw WanderRemoteError.notConfigured
        }
        let token = try await authSession.supabaseAccessToken()
        return [
            "apikey": configuration.supabasePublishableKey ?? "",
            "Authorization": "Bearer \(token)"
        ]
    }

    func call<Value: Decodable, Params: Encodable>(
        _ name: String,
        params: Params,
        decoder: JSONDecoder = RemoteDecoding.decoder
    ) async throws -> Value {
        guard let supabaseURL = configuration.supabaseURL else {
            throw WanderRemoteError.notConfigured
        }

        let headers = try await authenticatedHeaders()
        let endpoint = supabaseURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("rpc")
            .appendingPathComponent(name)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONEncoder().encode(params)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WanderRemoteError.invalidResponse("Missing HTTP response for \(name)")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw WanderRemoteError.notAuthenticated
            }
            let body = String(data: data, encoding: .utf8) ?? "unreadable response"
            throw WanderRemoteError.invalidResponse("RPC \(name) failed with \(httpResponse.statusCode): \(body)")
        }

        if Value.self == EmptyRPCResponse.self {
            return EmptyRPCResponse() as! Value
        }

        guard !data.isEmpty else {
            throw WanderRemoteError.invalidResponse("RPC \(name) returned no data")
        }

        return try decoder.decode(Value.self, from: data)
    }
}
