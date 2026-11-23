import XCTest
@testable import DeepSeekStatus

@MainActor
final class PricingManagerTests: XCTestCase {
    
    func testModelPricingOffPeak50PercentDiscount() {
        let flash = ModelPricing(
            id: "deepseek-flash",
            name: "DeepSeek-V4.1-Flash-1017",
            description: "High-speed flagship multimodal reasoning model (1017) with 1M context",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20,
            aliases: ["deepseek-v4.1-flash-1017", "deepseek-v4-flash", "deepseek-flash-1017"]
        )
        
        XCTAssertEqual(flash.peakInputMiss, 0.30, accuracy: 0.00001)
        XCTAssertEqual(flash.peakInputHit, 0.006, accuracy: 0.00001)
        XCTAssertEqual(flash.peakOutput, 1.20, accuracy: 0.00001)
        
        // 50% discount off-peak rates
        XCTAssertEqual(flash.offPeakInputMiss, 0.15, accuracy: 0.00001)
        XCTAssertEqual(flash.offPeakInputHit, 0.003, accuracy: 0.00001)
        XCTAssertEqual(flash.offPeakOutput, 0.60, accuracy: 0.00001)
    }
    
    func testProModelPricingAndOffPeakDiscount() {
        let pro = ModelPricing(
            id: "deepseek-v4-pro",
            name: "DeepSeek V4 Pro",
            description: "Full-capability professional reasoning & code model",
            peakInputMiss: 1.32,
            peakInputHit: 0.08,
            peakOutput: 3.96,
            aliases: ["deepseek-pro", "deepseek-reasoner"]
        )
        
        XCTAssertEqual(pro.peakInputMiss, 1.32, accuracy: 0.00001)
        XCTAssertEqual(pro.peakInputHit, 0.08, accuracy: 0.00001)
        XCTAssertEqual(pro.peakOutput, 3.96, accuracy: 0.00001)
        
        // 50% discount off-peak rates
        XCTAssertEqual(pro.offPeakInputMiss, 0.66, accuracy: 0.00001)
        XCTAssertEqual(pro.offPeakInputHit, 0.04, accuracy: 0.00001)
        XCTAssertEqual(pro.offPeakOutput, 1.98, accuracy: 0.00001)
    }
    
    func testDeepSeekV41FlashModelAliasesAndMatching() {
        let manager = PricingManager()
        
        // Look up via primary id
        let primary = manager.model(for: "deepseek-flash")
        XCTAssertNotNil(primary)
        XCTAssertEqual(primary?.id, "deepseek-flash")
        XCTAssertEqual(primary?.name, "DeepSeek-V4.1-Flash-1017")
        XCTAssertTrue(primary?.description.contains("1017") == true)
        XCTAssertTrue(primary?.description.contains("1M context") == true)
        
        // Look up via aliases
        let alias1 = manager.model(for: "deepseek-v4.1-flash-1017")
        XCTAssertNotNil(alias1)
        XCTAssertEqual(alias1?.id, "deepseek-flash")
        
        let alias2 = manager.model(for: "deepseek-v4-flash")
        XCTAssertNotNil(alias2)
        XCTAssertEqual(alias2?.id, "deepseek-flash")
        
        let alias3 = manager.model(for: "deepseek-flash-1017")
        XCTAssertNotNil(alias3)
        XCTAssertEqual(alias3?.id, "deepseek-flash")
        
        let alias4 = manager.model(for: "DeepSeek V4.1 Flash")
        XCTAssertNotNil(alias4)
        XCTAssertEqual(alias4?.id, "deepseek-flash")
        
        // Quick access properties
        XCTAssertNotNil(manager.flashModel)
        XCTAssertEqual(manager.flashModel?.id, "deepseek-flash")
        XCTAssertNotNil(manager.proModel)
        XCTAssertEqual(manager.proModel?.id, "deepseek-v4-pro")
    }
    
    func testPricingManagerDefaultModels() {
        let manager = PricingManager()
        
        XCTAssertFalse(manager.models.isEmpty, "PricingManager should provide default models")
        
        // Locate Flash model
        guard let flash = manager.flashModel else {
            XCTFail("Flash model must be present in PricingManager")
            return
        }
        XCTAssertEqual(flash.peakInputMiss, 0.30, accuracy: 0.00001)
        XCTAssertEqual(flash.peakInputHit, 0.006, accuracy: 0.00001)
        XCTAssertEqual(flash.peakOutput, 1.20, accuracy: 0.00001)
        XCTAssertEqual(flash.offPeakInputMiss, 0.15, accuracy: 0.00001)
        XCTAssertEqual(flash.offPeakInputHit, 0.003, accuracy: 0.00001)
        XCTAssertEqual(flash.offPeakOutput, 0.60, accuracy: 0.00001)
        
        // Locate Pro model
        guard let pro = manager.proModel else {
            XCTFail("Pro model must be present in PricingManager")
            return
        }
        XCTAssertEqual(pro.peakInputMiss, 1.32, accuracy: 0.00001)
        XCTAssertEqual(pro.peakInputHit, 0.08, accuracy: 0.00001)
        XCTAssertEqual(pro.peakOutput, 3.96, accuracy: 0.00001)
        XCTAssertEqual(pro.offPeakInputMiss, 0.66, accuracy: 0.00001)
        XCTAssertEqual(pro.offPeakInputHit, 0.04, accuracy: 0.00001)
        XCTAssertEqual(pro.offPeakOutput, 1.98, accuracy: 0.00001)
    }
    
    func testModelPricingCodableSerialization() throws {
        let model = ModelPricing(
            id: "deepseek-flash",
            name: "DeepSeek-V4.1-Flash-1017",
            description: "High-speed flagship multimodal reasoning model (1017) with 1M context",
            peakInputMiss: 0.30,
            peakInputHit: 0.006,
            peakOutput: 1.20,
            aliases: ["deepseek-v4.1-flash-1017", "deepseek-v4-flash"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(model)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ModelPricing.self, from: data)
        
        XCTAssertEqual(decoded.id, model.id)
        XCTAssertEqual(decoded.name, model.name)
        XCTAssertEqual(decoded.description, model.description)
        XCTAssertEqual(decoded.peakInputMiss, model.peakInputMiss)
        XCTAssertEqual(decoded.peakInputHit, model.peakInputHit)
        XCTAssertEqual(decoded.peakOutput, model.peakOutput)
        XCTAssertEqual(decoded.offPeakInputMiss, model.offPeakInputMiss)
        XCTAssertEqual(decoded.offPeakInputHit, model.offPeakInputHit)
        XCTAssertEqual(decoded.offPeakOutput, model.offPeakOutput)
        XCTAssertEqual(decoded.aliases, model.aliases)
    }
}
