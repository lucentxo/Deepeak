import Foundation
import Combine

public struct DeepSeekBalanceInfo: Codable, Sendable {
    public let currency: String
    public let totalBalance: Double
    public let grantedBalance: Double
    public let toppedUpBalance: Double

    public enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }

    public init(currency: String, totalBalance: Double, grantedBalance: Double, toppedUpBalance: Double) {
        self.currency = currency
        self.totalBalance = totalBalance
        self.grantedBalance = grantedBalance
        self.toppedUpBalance = toppedUpBalance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currency = (try? container.decode(String.self, forKey: .currency)) ?? "USD"

        self.totalBalance = Self.decodeDouble(container: container, key: .totalBalance)
        self.grantedBalance = Self.decodeDouble(container: container, key: .grantedBalance)
        self.toppedUpBalance = Self.decodeDouble(container: container, key: .toppedUpBalance)
    }

    private static func decodeDouble(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Double {
        if let val = try? container.decode(Double.self, forKey: key) {
            return val
        }
        if let str = try? container.decode(String.self, forKey: key), let val = Double(str) {
            return val
        }
        return 0.0
    }
}

public struct DeepSeekBalanceResponse: Codable, Sendable {
    public let isAvailable: Bool
    public let balanceInfos: [DeepSeekBalanceInfo]

    public enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }

    public init(isAvailable: Bool, balanceInfos: [DeepSeekBalanceInfo]) {
        self.isAvailable = isAvailable
        self.balanceInfos = balanceInfos
    }
}

public enum TokenMetric: String, Sendable, CaseIterable {
    case output = "output"
    case inputMiss = "input_miss"
    case inputHit = "input_hit"
}

@MainActor
public final class BalanceManager: ObservableObject {
    @Published public var hasApiKey: Bool = false
    @Published public var isAvailable: Bool = true
    @Published public var totalBalance: Double? = nil
    @Published public var toppedUpBalance: Double? = nil
    @Published public var grantedBalance: Double? = nil
    @Published public var currency: String = "USD"
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var lastSyncTime: Date? = nil
    @Published public var isEditingKey: Bool = false
    @Published public var enteredKey: String = ""

    private var syncTimer: AnyCancellable?
    private var currentDataTask: URLSessionDataTask?
    private let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    public init(checkKeyOnInit: Bool = true, autoFetch: Bool = true) {
        if checkKeyOnInit {
            checkApiKey()
        }
        if hasApiKey && autoFetch {
            fetchBalance()
        }
        if autoFetch {
            setupSyncTimer()
        }
    }

    public func checkApiKey() {
        if let key = KeychainHelper.loadApiKey(), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.hasApiKey = true
        } else {
            self.hasApiKey = false
            self.totalBalance = nil
            self.errorMessage = nil
        }
    }

    public func saveApiKey(_ key: String) {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        KeychainHelper.saveApiKey(cleaned)
        self.hasApiKey = true
        self.errorMessage = nil
        fetchBalance()
    }

    public func removeApiKey() {
        currentDataTask?.cancel()
        currentDataTask = nil
        KeychainHelper.deleteApiKey()
        self.hasApiKey = false
        self.totalBalance = nil
        self.toppedUpBalance = nil
        self.grantedBalance = nil
        self.errorMessage = nil
        self.lastSyncTime = nil
    }

    public func fetchBalance() {
        guard let apiKey = KeychainHelper.loadApiKey(), !apiKey.isEmpty else {
            self.hasApiKey = false
            return
        }

        guard let url = URL(string: "https://api.deepseek.com/user/balance") else { return }

        self.isLoading = true
        self.errorMessage = nil

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0

        // Cancel previous in-flight task to prevent overlapping race conditions
        currentDataTask?.cancel()
        currentDataTask = nil

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.currentDataTask = nil

                if let error = error as NSError? {
                    if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                        return
                    }
                    self.errorMessage = "Connection error"
                    print("[BalanceManager] Request failed: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        self.errorMessage = "Invalid API key"
                        return
                    } else if httpResponse.statusCode == 402 {
                        self.errorMessage = "Payment required"
                        return
                    } else if httpResponse.statusCode != 200 {
                        self.errorMessage = "Error (\(httpResponse.statusCode))"
                        return
                    }
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: data)
                    self.isAvailable = decoded.isAvailable

                    if let primary = decoded.balanceInfos.first {
                        self.currency = primary.currency
                        self.totalBalance = primary.totalBalance
                        self.toppedUpBalance = primary.toppedUpBalance
                        self.grantedBalance = primary.grantedBalance
                    } else {
                        self.totalBalance = 0.0
                    }
                    self.lastSyncTime = Date()
                    self.errorMessage = nil
                } catch {
                    self.errorMessage = "Parse error"
                    print("[BalanceManager] JSON decode failed: \(error)")
                }
            }
        }
        self.currentDataTask = task
        task.resume()
    }

    private func setupSyncTimer() {
        syncTimer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.hasApiKey {
                    self.fetchBalance()
                }
            }
    }

    public func stopSyncTimer() {
        syncTimer?.cancel()
        syncTimer = nil
        currentDataTask?.cancel()
        currentDataTask = nil
    }

    public var formattedLastSync: String {
        guard let date = lastSyncTime else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Token Capacity Estimations

    /// Retrieves the price per 1M tokens for a given model, metric, and off-peak status
    public func ratePer1M(for model: ModelPricing, isOffPeak: Bool, metric: TokenMetric = .output) -> Double {
        switch metric {
        case .output:
            return isOffPeak ? model.offPeakOutput : model.peakOutput
        case .inputMiss:
            return isOffPeak ? model.offPeakInputMiss : model.peakInputMiss
        case .inputHit:
            return isOffPeak ? model.offPeakInputHit : model.peakInputHit
        }
    }

    /// Calculate raw estimated token count for current balance
    public func rawEstimatedTokens(for model: ModelPricing, isOffPeak: Bool, metric: TokenMetric = .output) -> Double {
        guard let balance = totalBalance, balance > 0 else { return 0.0 }
        return rawEstimatedTokens(balance: balance, model: model, isOffPeak: isOffPeak, metric: metric)
    }

    /// Calculate raw estimated token count for an arbitrary balance
    public func rawEstimatedTokens(balance: Double, model: ModelPricing, isOffPeak: Bool, metric: TokenMetric = .output) -> Double {
        guard balance > 0 else { return 0.0 }
        let rate = ratePer1M(for: model, isOffPeak: isOffPeak, metric: metric)
        guard rate > 0 else { return 0.0 }
        return (balance / rate) * 1_000_000.0
    }

    /// Calculate estimated remaining tokens for a model based on current balance and whether off-peak pricing is active
    public func estimatedTokens(for model: ModelPricing, isOffPeak: Bool) -> String {
        guard let balance = totalBalance, balance > 0 else { return "0" }
        return estimatedTokens(balance: balance, model: model, isOffPeak: isOffPeak, metric: .output)
    }

    /// Overload allowing specific token metric (output, input hit, input miss)
    public func estimatedTokens(for model: ModelPricing, isOffPeak: Bool, metric: TokenMetric) -> String {
        guard let balance = totalBalance, balance > 0 else { return "0" }
        return estimatedTokens(balance: balance, model: model, isOffPeak: isOffPeak, metric: metric)
    }

    /// Calculate estimated tokens given an explicit balance amount
    public func estimatedTokens(balance: Double, model: ModelPricing, isOffPeak: Bool, metric: TokenMetric = .output) -> String {
        guard balance > 0 else { return "0" }
        let rate = ratePer1M(for: model, isOffPeak: isOffPeak, metric: metric)
        guard rate > 0 else { return "N/A" }
        return Self.formatEstimatedTokens(millions: balance / rate)
    }

    /// Standard token estimation string formatter (e.g. "8.3M", "16.7M", "500K")
    public static func formatEstimatedTokens(millions: Double) -> String {
        guard millions > 0 else { return "0" }
        if millions >= 1000.0 {
            return String(format: "%.1fB", millions / 1000.0)
        } else if millions >= 1.0 {
            return String(format: "%.1fM", millions)
        } else {
            let thousands = millions * 1000.0
            return String(format: "%.0fK", thousands)
        }
    }
}
