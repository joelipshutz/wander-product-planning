import Foundation

struct WanderBackendConfiguration: Equatable {
    let clerkPublishableKey: String?
    let clerkFrontendAPI: String?
    let supabaseURL: URL?
    let supabasePublishableKey: String?

    var isClerkConfigured: Bool {
        clerkPublishableKey?.isEmpty == false
    }

    var isSupabaseConfigured: Bool {
        supabaseURL != nil && supabasePublishableKey?.isEmpty == false
    }

    static func current(bundle: Bundle = .main) -> WanderBackendConfiguration {
        WanderBackendConfiguration(
            clerkPublishableKey: bundle.trimmedString(for: "WANDER_CLERK_PUBLISHABLE_KEY"),
            clerkFrontendAPI: bundle.trimmedString(for: "WANDER_CLERK_FRONTEND_API"),
            supabaseURL: bundle.trimmedString(for: "WANDER_SUPABASE_URL").flatMap(URL.init(string:)),
            supabasePublishableKey: bundle.trimmedString(for: "WANDER_SUPABASE_PUBLISHABLE_KEY")
        )
    }
}

private extension Bundle {
    func trimmedString(for key: String) -> String? {
        guard let value = object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }

        return trimmed
    }
}
