import Foundation
import Combine

struct DeepSeekBalanceInfo: Codable {
    let currency: String
    let totalBalance: Double
    let grantedBalance: Double
    let toppedUpBalance: Double

    enum CodingKeys: String, CodingKey {
        case currency
        case totalBalance = "total_balance"
        case grantedBalance = "granted_balance"
        case toppedUpBalance = "topped_up_balance"
    }

    init(currency: String, totalBalance: Double, grantedBalance: Double, toppedUpBalance: Double) {
        self.currency = currency
        self.totalBalance = totalBalance
        self.grantedBalance = grantedBalance
        self.toppedUpBalance = toppedUpBalance
    }

    init(from decoder: Decoder) throws {
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

struct DeepSeekBalanceResponse: Codable {
    let isAvailable: Bool
    let balanceInfos: [DeepSeekBalanceInfo]

    enum CodingKeys: String, CodingKey {
        case isAvailable = "is_available"
        case balanceInfos = "balance_infos"
    }
}

class BalanceManager: ObservableObject {
    @Published var hasApiKey: Bool = false
    @Published var isAvailable: Bool = true
    @Published var totalBalance: Double? = nil
    @Published var toppedUpBalance: Double? = nil
    @Published var grantedBalance: Double? = nil
    @Published var currency: String = "USD"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastSyncTime: Date? = nil
    @Published var isEditingKey: Bool = false
    @Published var enteredKey: String = ""

    private var syncTimer: AnyCancellable?
    private let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    init() {
        checkApiKey()
        if hasApiKey {
            fetchBalance()
        }
        setupSyncTimer()
    }

    func checkApiKey() {
        if let key = KeychainHelper.loadApiKey(), !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.hasApiKey = true
        } else {
            self.hasApiKey = false
            self.totalBalance = nil
            self.errorMessage = nil
        }
    }

    func saveApiKey(_ key: String) {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        KeychainHelper.saveApiKey(cleaned)
        self.hasApiKey = true
        self.errorMessage = nil
        fetchBalance()
    }

    func removeApiKey() {
        KeychainHelper.deleteApiKey()
        self.hasApiKey = false
        self.totalBalance = nil
        self.toppedUpBalance = nil
        self.grantedBalance = nil
        self.errorMessage = nil
        self.lastSyncTime = nil
    }

    func fetchBalance() {
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

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
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
        }.resume()
    }

    private func setupSyncTimer() {
        syncTimer = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if self?.hasApiKey == true {
                    self?.fetchBalance()
                }
            }
    }

    var formattedLastSync: String {
        guard let date = lastSyncTime else { return "Never" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// Calculate estimated remaining tokens for a model based on whether off-peak pricing is active
    func estimatedTokens(for model: ModelPricing, isOffPeak: Bool) -> String {
        guard let balance = totalBalance, balance > 0 else { return "0" }

        // Use output token rate as standard reference capacity metric
        let ratePer1M = isOffPeak ? model.offPeakOutput : model.peakOutput
        guard ratePer1M > 0 else { return "N/A" }

        let millions = balance / ratePer1M
        if millions >= 1.0 {
            return String(format: "%.1fM", millions)
        } else {
            let thousands = millions * 1000
            return String(format: "%.0fK", thousands)
        }
    }
}
