import XCTest
@testable import DeepSeekStatus

@MainActor
final class BalanceManagerTests: XCTestCase {
    
    func testDecodeBalanceResponseWithStringValues() throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "USD",
                    "total_balance": "25.50",
                    "granted_balance": "5.00",
                    "topped_up_balance": "20.50"
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: json)
        XCTAssertTrue(response.isAvailable)
        XCTAssertEqual(response.balanceInfos.count, 1)
        
        let info = response.balanceInfos[0]
        XCTAssertEqual(info.currency, "USD")
        XCTAssertEqual(info.totalBalance, 25.50, accuracy: 0.001)
        XCTAssertEqual(info.grantedBalance, 5.00, accuracy: 0.001)
        XCTAssertEqual(info.toppedUpBalance, 20.50, accuracy: 0.001)
    }
    
    func testDecodeBalanceResponseWithNumericValues() throws {
        let json = """
        {
            "is_available": true,
            "balance_infos": [
                {
                    "currency": "CNY",
                    "total_balance": 100.25,
                    "granted_balance": 10.00,
                    "topped_up_balance": 90.25
                }
            ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: json)
        XCTAssertTrue(response.isAvailable)
        XCTAssertEqual(response.balanceInfos.count, 1)
        
        let info = response.balanceInfos[0]
        XCTAssertEqual(info.currency, "CNY")
        XCTAssertEqual(info.totalBalance, 100.25, accuracy: 0.001)
        XCTAssertEqual(info.grantedBalance, 10.00, accuracy: 0.001)
        XCTAssertEqual(info.toppedUpBalance, 90.25, accuracy: 0.001)
    }
    
    func testDecodeEmptyBalanceInfos() throws {
        let json = """
        {
            "is_available": false,
            "balance_infos": []
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(DeepSeekBalanceResponse.self, from: json)
        XCTAssertFalse(response.isAvailable)
        XCTAssertTrue(response.balanceInfos.isEmpty)
    }
    
    func testEstimatedTokensForFlashModel() {
        let balanceManager = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        
        let flashModel = ModelPricing(
            id: "deepseek-flash",
            name: "DeepSeek-V4.1-Flash-1017",
            description: "High-speed flagship multimodal reasoning model (1017) with 1M context",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20,
            aliases: ["deepseek-v4.1-flash-1017", "deepseek-v4-flash"]
        )
        
        // When balance is $12.00
        // Peak rate $1.20/1M -> 10.0M tokens
        // Off-peak rate $0.60/1M -> 20.0M tokens
        balanceManager.totalBalance = 12.00
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: false), "10.0M")
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: true), "20.0M")
        
        // Input hit metrics ($0.006 peak, $0.003 off-peak)
        // With $12.00 balance:
        // Peak input hit: 12 / 0.006 = 2,000M = 2.0B tokens
        // Off-peak input hit: 12 / 0.003 = 4,000M = 4.0B tokens
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: false, metric: .inputHit), "2.0B")
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: true, metric: .inputHit), "4.0B")
        
        // Input miss metrics ($0.30 peak, $0.15 off-peak)
        // With $12.00 balance:
        // Peak input miss: 12 / 0.30 = 40.0M tokens
        // Off-peak input miss: 12 / 0.15 = 80.0M tokens
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: false, metric: .inputMiss), "40.0M")
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: true, metric: .inputMiss), "80.0M")
        
        // When balance is $0.60
        // Peak rate $1.20/1M -> 0.5M -> 500K tokens
        // Off-peak rate $0.60/1M -> 1.0M tokens
        balanceManager.totalBalance = 0.60
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: false), "500K")
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: true), "1.0M")
        
        // When balance is $0.06
        // Peak rate $1.20/1M -> 0.05M -> 50K tokens
        // Off-peak rate $0.60/1M -> 0.1M -> 100K tokens
        balanceManager.totalBalance = 0.06
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: false), "50K")
        XCTAssertEqual(balanceManager.estimatedTokens(for: flashModel, isOffPeak: true), "100K")
    }
    
    func testEstimatedTokensForProModel() {
        let balanceManager = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        
        let proModel = ModelPricing(
            id: "deepseek-v4-pro",
            name: "DeepSeek V4 Pro",
            description: "Full-capability professional reasoning & code model",
            peakInputMiss: 1.32,
            peakInputHit: 0.08,
            peakOutput: 3.96
        )
        
        // When balance is $3.96
        // Peak rate $3.96/1M -> 1.0M tokens
        // Off-peak rate $1.98/1M -> 2.0M tokens
        balanceManager.totalBalance = 3.96
        XCTAssertEqual(balanceManager.estimatedTokens(for: proModel, isOffPeak: false), "1.0M")
        XCTAssertEqual(balanceManager.estimatedTokens(for: proModel, isOffPeak: true), "2.0M")
        
        // When balance is $1.98
        // Peak rate $3.96/1M -> 0.5M -> 500K tokens
        // Off-peak rate $1.98/1M -> 1.0M tokens
        balanceManager.totalBalance = 1.98
        XCTAssertEqual(balanceManager.estimatedTokens(for: proModel, isOffPeak: false), "500K")
        XCTAssertEqual(balanceManager.estimatedTokens(for: proModel, isOffPeak: true), "1.0M")
    }
    
    func testEstimatedTokensWithZeroOrNilBalance() {
        let balanceManager = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        let model = ModelPricing(
            id: "deepseek-flash",
            name: "DeepSeek Flash",
            description: "Flash model",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20
        )
        
        balanceManager.totalBalance = nil
        XCTAssertEqual(balanceManager.estimatedTokens(for: model, isOffPeak: false), "0")
        
        balanceManager.totalBalance = 0.0
        XCTAssertEqual(balanceManager.estimatedTokens(for: model, isOffPeak: true), "0")
        
        balanceManager.totalBalance = -5.0
        XCTAssertEqual(balanceManager.estimatedTokens(for: model, isOffPeak: false), "0")
    }
    
    func testRawEstimatedTokensCalculations() {
        let balanceManager = BalanceManager(checkKeyOnInit: false, autoFetch: false)
        let flash = ModelPricing(
            id: "deepseek-flash",
            name: "Flash",
            description: "Flash model",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20
        )
        
        balanceManager.totalBalance = 6.00
        // Peak output: 6.00 / 1.20 * 1,000,000 = 5,000,000
        let peakOutputTokens = balanceManager.rawEstimatedTokens(for: flash, isOffPeak: false, metric: .output)
        XCTAssertEqual(peakOutputTokens, 5_000_000, accuracy: 1.0)
        
        // Off-peak output: 6.00 / 0.60 * 1,000,000 = 10,000,000
        let offPeakOutputTokens = balanceManager.rawEstimatedTokens(for: flash, isOffPeak: true, metric: .output)
        XCTAssertEqual(offPeakOutputTokens, 10_000_000, accuracy: 1.0)
    }
    
    func testFormatEstimatedTokensHelper() {
        XCTAssertEqual(BalanceManager.formatEstimatedTokens(millions: 0.0), "0")
        XCTAssertEqual(BalanceManager.formatEstimatedTokens(millions: 0.5), "500K")
        XCTAssertEqual(BalanceManager.formatEstimatedTokens(millions: 1.0), "1.0M")
        XCTAssertEqual(BalanceManager.formatEstimatedTokens(millions: 12.34), "12.3M")
        XCTAssertEqual(BalanceManager.formatEstimatedTokens(millions: 1500.0), "1.5B")
    }
}
