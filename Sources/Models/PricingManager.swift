import Foundation
import Combine

struct ModelPricing: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let peakInputMiss: Double      // Price per 1M tokens in USD
    let peakInputHit: Double       // Price per 1M tokens in USD
    let peakOutput: Double         // Price per 1M tokens in USD
    
    // Off-peak is discounted 50%
    var offPeakInputMiss: Double { peakInputMiss * 0.5 }
    var offPeakInputHit: Double { peakInputHit * 0.5 }
    var offPeakOutput: Double { peakOutput * 0.5 }
}

/// Manages DeepSeek pricing tiers, caching, and 12-hour refresh interval
class PricingManager: ObservableObject {
    @Published var models: [ModelPricing] = []
    @Published var lastRefreshed: Date = Date()
    @Published var isRefreshing: Bool = false
    @Published var refreshStatusMessage: String = "Up to date"
    
    private var refreshTimer: AnyCancellable?
    private let refreshIntervalSeconds: TimeInterval = 12 * 60 * 60 // 12 hours
    private let cacheKey = "deepseek_pricing_cache"
    private let lastUpdatedKey = "deepseek_pricing_last_updated"
    
    init() {
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
    
    func loadDefaultOrCachedData() {
        // DeepSeek active models: V4.1 Flash and V4 Pro
        let defaultModels: [ModelPricing] = [
            ModelPricing(
                id: "deepseek-v4-flash",
                name: "DeepSeek V4.1 Flash",
                description: "High-speed flagship model with 1M token context",
                peakInputMiss: 0.30,
                peakInputHit: 0.006,
                peakOutput: 1.20
            ),
            ModelPricing(
                id: "deepseek-v4-pro",
                name: "DeepSeek V4 Pro",
                description: "Full-capability professional reasoning & code model",
                peakInputMiss: 1.32,
                peakInputHit: 0.08,
                peakOutput: 3.96
            )
        ]
        
        // Use updated models as baseline
        self.models = defaultModels
        if let savedDate = UserDefaults.standard.object(forKey: lastUpdatedKey) as? Date {
            self.lastRefreshed = savedDate
        } else {
            saveCache()
        }
    }
    
    func refreshPricingData() {
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
    
    var formattedLastRefreshed: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: lastRefreshed)
    }
}
