import Foundation
import Combine

public struct ModelPricing: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let peakInputMiss: Double      // Price per 1M tokens in USD
    public let peakInputHit: Double       // Price per 1M tokens in USD
    public let peakOutput: Double         // Price per 1M tokens in USD
    public let aliases: [String]
    
    // Off-peak is discounted 50%
    public var offPeakInputMiss: Double { peakInputMiss * 0.5 }
    public var offPeakInputHit: Double { peakInputHit * 0.5 }
    public var offPeakOutput: Double { peakOutput * 0.5 }
    
    public init(
        id: String,
        name: String,
        description: String,
        peakInputMiss: Double,
        peakInputHit: Double,
        peakOutput: Double,
        aliases: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.peakInputMiss = peakInputMiss
        self.peakInputHit = peakInputHit
        self.peakOutput = peakOutput
        self.aliases = aliases
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case peakInputMiss
        case peakInputHit
        case peakOutput
        case aliases
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.peakInputMiss = try container.decode(Double.self, forKey: .peakInputMiss)
        self.peakInputHit = try container.decode(Double.self, forKey: .peakInputHit)
        self.peakOutput = try container.decode(Double.self, forKey: .peakOutput)
        self.aliases = (try? container.decode([String].self, forKey: .aliases)) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(peakInputMiss, forKey: .peakInputMiss)
        try container.encode(peakInputHit, forKey: .peakInputHit)
        try container.encode(peakOutput, forKey: .peakOutput)
        try container.encode(aliases, forKey: .aliases)
    }
    
    /// Matches model parameter, identifier, alias, or display name (case-insensitive)
    public func matches(_ identifier: String) -> Bool {
        let cleaned = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if id.lowercased() == cleaned || name.lowercased() == cleaned {
            return true
        }
        return aliases.contains { $0.lowercased() == cleaned }
    }
}

/// Manages DeepSeek pricing tiers, caching, and 12-hour refresh interval
public class PricingManager: ObservableObject {
    @Published public var models: [ModelPricing] = []
    @Published public var lastRefreshed: Date = Date()
    @Published public var isRefreshing: Bool = false
    @Published public var refreshStatusMessage: String = "Up to date"
    
    private var refreshTimer: AnyCancellable?
    private let refreshIntervalSeconds: TimeInterval = 12 * 60 * 60 // 12 hours
    private let cacheKey = "deepseek_pricing_cache"
    private let lastUpdatedKey = "deepseek_pricing_last_updated"
    
    public static let defaultModels: [ModelPricing] = [
        ModelPricing(
            id: "deepseek-flash",
            name: "DeepSeek-V4.1-Flash-1017",
            description: "High-speed flagship multimodal reasoning model (1017) with 1M context",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20,
            aliases: ["deepseek-v4.1-flash-1017", "deepseek-v4-flash", "deepseek-flash-1017", "DeepSeek V4.1 Flash"]
        ),
        ModelPricing(
            id: "deepseek-v4-pro",
            name: "DeepSeek V4 Pro",
            description: "Full-capability professional reasoning & code model",
            peakInputMiss: 1.32,
            peakInputHit: 0.08,
            peakOutput: 3.96,
            aliases: ["deepseek-pro", "deepseek-reasoner"]
        )
    ]
    
    public init() {
        loadDefaultOrCachedData()
        setup12HourRefreshTimer()
    }
    
    private func setup12HourRefreshTimer() {
        // Automatically check/refresh every 12 hours
        refreshTimer = Timer.publish(every: refreshIntervalSeconds, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshPricingData()
            }
    }
    
    public func loadDefaultOrCachedData() {
        // DeepSeek active models: V4.1 Flash-1017 and V4 Pro
        self.models = Self.defaultModels
        if let savedDate = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date {
            self.lastRefreshed = savedDate
        } else {
            saveCache()
        }
    }
    
    /// Finds a model by its parameter id, alias, or display name
    public func model(for identifier: String) -> ModelPricing? {
        models.first { $0.matches(identifier) }
    }
    
    public var flashModel: ModelPricing? {
        model(for: "deepseek-flash")
    }
    
    public var proModel: ModelPricing? {
        model(for: "deepseek-v4-pro")
    }
    
    public func refreshPricingData() {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshStatusMessage = "Refreshing pricing..."
        
        // Simulating network fetch / validating API endpoint
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.lastRefreshed = Date()
                self.saveCache()
                self.isRefreshing = false
                self.refreshStatusMessage = "Refreshed just now"
            }
        }
    }
    
    private func saveCache() {
        if let encoded = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
            UserDefaults.standard.set(lastRefreshed, forKey: lastUpdatedKey)
        }
    }
    
    public var formattedLastRefreshed: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: lastRefreshed)
    }
}
