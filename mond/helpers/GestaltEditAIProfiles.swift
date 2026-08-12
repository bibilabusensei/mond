import Foundation

/// Safe, supported-device Apple Intelligence US-region profiles mirrored from
/// frs0n/GestaltEdit. This helper intentionally does not provide the upstream
/// forced device-spoof fallback for unsupported hardware; Mond's source mode
/// only applies the three-key region patch when the real device is recognized.
struct GestaltEditAIProfile: Equatable {
    let productType: String
    let marketingName: String
    let regulatoryModel: String

    private static let thinningProductTypeKey = "0+nc/Udy4WNG8S+Q7a/s1A"
    private static let marketingNameKeys = [
        "Z/dqyWS6OZTRy10UcmUAhw",
        "bbtR9jQx50Fv5Af/affNtA"
    ]

    private static let profiles: [String: GestaltEditAIProfile] = [
        "iPhone16,1": .init(productType: "iPhone16,1", marketingName: "iPhone 15 Pro", regulatoryModel: "A2848"),
        "iPhone16,2": .init(productType: "iPhone16,2", marketingName: "iPhone 15 Pro Max", regulatoryModel: "A2849"),
        "iPhone17,1": .init(productType: "iPhone17,1", marketingName: "iPhone 16 Pro", regulatoryModel: "A3083"),
        "iPhone17,2": .init(productType: "iPhone17,2", marketingName: "iPhone 16 Pro Max", regulatoryModel: "A3084"),
        "iPhone17,3": .init(productType: "iPhone17,3", marketingName: "iPhone 16", regulatoryModel: "A3081"),
        "iPhone17,4": .init(productType: "iPhone17,4", marketingName: "iPhone 16 Plus", regulatoryModel: "A3082"),
        "iPhone17,5": .init(productType: "iPhone17,5", marketingName: "iPhone 16e", regulatoryModel: "A3212"),

        "iPad13,4": .init(productType: "iPad13,4", marketingName: "iPad Pro 11-inch (M1)", regulatoryModel: "A2377"),
        "iPad13,5": .init(productType: "iPad13,5", marketingName: "iPad Pro 11-inch (M1)", regulatoryModel: "A2459"),
        "iPad13,6": .init(productType: "iPad13,6", marketingName: "iPad Pro 11-inch (M1)", regulatoryModel: "A2301"),
        "iPad13,7": .init(productType: "iPad13,7", marketingName: "iPad Pro 11-inch (M1)", regulatoryModel: "A2301"),
        "iPad13,8": .init(productType: "iPad13,8", marketingName: "iPad Pro 12.9-inch (M1)", regulatoryModel: "A2378"),
        "iPad13,9": .init(productType: "iPad13,9", marketingName: "iPad Pro 12.9-inch (M1)", regulatoryModel: "A2461"),
        "iPad13,10": .init(productType: "iPad13,10", marketingName: "iPad Pro 12.9-inch (M1)", regulatoryModel: "A2379"),
        "iPad13,11": .init(productType: "iPad13,11", marketingName: "iPad Pro 12.9-inch (M1)", regulatoryModel: "A2379"),
        "iPad13,16": .init(productType: "iPad13,16", marketingName: "iPad Air (M1)", regulatoryModel: "A2588"),
        "iPad13,17": .init(productType: "iPad13,17", marketingName: "iPad Air (M1)", regulatoryModel: "A2589"),
        "iPad14,3": .init(productType: "iPad14,3", marketingName: "iPad Pro 11-inch (M2)", regulatoryModel: "A2759"),
        "iPad14,4": .init(productType: "iPad14,4", marketingName: "iPad Pro 11-inch (M2)", regulatoryModel: "A2435"),
        "iPad14,5": .init(productType: "iPad14,5", marketingName: "iPad Pro 12.9-inch (M2)", regulatoryModel: "A2436"),
        "iPad14,6": .init(productType: "iPad14,6", marketingName: "iPad Pro 12.9-inch (M2)", regulatoryModel: "A2764"),
        "iPad14,8": .init(productType: "iPad14,8", marketingName: "iPad Air 11-inch (M2)", regulatoryModel: "A2902"),
        "iPad14,9": .init(productType: "iPad14,9", marketingName: "iPad Air 11-inch (M2)", regulatoryModel: "A2903"),
        "iPad14,10": .init(productType: "iPad14,10", marketingName: "iPad Air 13-inch (M2)", regulatoryModel: "A2898"),
        "iPad14,11": .init(productType: "iPad14,11", marketingName: "iPad Air 13-inch (M2)", regulatoryModel: "A2899"),
        "iPad15,3": .init(productType: "iPad15,3", marketingName: "iPad Air 11-inch (M3)", regulatoryModel: "A3266"),
        "iPad15,4": .init(productType: "iPad15,4", marketingName: "iPad Air 11-inch (M3)", regulatoryModel: "A3267"),
        "iPad15,5": .init(productType: "iPad15,5", marketingName: "iPad Air 13-inch (M3)", regulatoryModel: "A3268"),
        "iPad15,6": .init(productType: "iPad15,6", marketingName: "iPad Air 13-inch (M3)", regulatoryModel: "A3269"),
        "iPad16,1": .init(productType: "iPad16,1", marketingName: "iPad mini (A17 Pro)", regulatoryModel: "A2993"),
        "iPad16,2": .init(productType: "iPad16,2", marketingName: "iPad mini (A17 Pro)", regulatoryModel: "A2995"),
        "iPad16,3": .init(productType: "iPad16,3", marketingName: "iPad Pro 11-inch (M4)", regulatoryModel: "A2836"),
        "iPad16,4": .init(productType: "iPad16,4", marketingName: "iPad Pro 11-inch (M4)", regulatoryModel: "A2837"),
        "iPad16,5": .init(productType: "iPad16,5", marketingName: "iPad Pro 13-inch (M4)", regulatoryModel: "A2925"),
        "iPad16,6": .init(productType: "iPad16,6", marketingName: "iPad Pro 13-inch (M4)", regulatoryModel: "A2926"),
        "iPad16,8": .init(productType: "iPad16,8", marketingName: "iPad Air 11-inch (M4)", regulatoryModel: "A3459"),
        "iPad16,9": .init(productType: "iPad16,9", marketingName: "iPad Air 11-inch (M4)", regulatoryModel: "A3460"),
        "iPad16,10": .init(productType: "iPad16,10", marketingName: "iPad Air 13-inch (M4)", regulatoryModel: "A3461"),
        "iPad16,11": .init(productType: "iPad16,11", marketingName: "iPad Air 13-inch (M4)", regulatoryModel: "A3462"),
        "iPad17,1": .init(productType: "iPad17,1", marketingName: "iPad Pro 11-inch (M5)", regulatoryModel: "A3357"),
        "iPad17,2": .init(productType: "iPad17,2", marketingName: "iPad Pro 11-inch (M5)", regulatoryModel: "A3358"),
        "iPad17,3": .init(productType: "iPad17,3", marketingName: "iPad Pro 13-inch (M5)", regulatoryModel: "A3360"),
        "iPad17,4": .init(productType: "iPad17,4", marketingName: "iPad Pro 13-inch (M5)", regulatoryModel: "A3361")
    ]

    private static let regulatoryByMarketingName: [String: String] = [
        "iPhone 17e": "A3575",
        "iPhone 17 Pro Max": "A3257",
        "iPhone 17 Pro": "A3256",
        "iPhone 17": "A3258",
        "iPhone Air": "A3260",
        "iPhone 16e": "A3212",
        "iPhone 16 Pro Max": "A3084",
        "iPhone 16 Pro": "A3083",
        "iPhone 16 Plus": "A3082",
        "iPhone 16": "A3081",
        "iPhone 15 Pro Max": "A2849",
        "iPhone 15 Pro": "A2848"
    ]

    static func resolve(cacheExtra: [String: Any], machineIdentifier: String) -> GestaltEditAIProfile? {
        let rawProductType = (cacheExtra[thinningProductTypeKey] as? String) ?? machineIdentifier
        let productType = rawProductType.split(separator: "-").first.map(String.init) ?? rawProductType
        if let profile = profiles[productType] {
            return profile
        }

        let storedMarketingName = marketingNameKeys
            .compactMap { cacheExtra[$0] as? String }
            .first { regulatoryByMarketingName[$0] != nil }

        guard let marketingName = storedMarketingName,
              let regulatoryModel = regulatoryByMarketingName[marketingName] else {
            return nil
        }

        return GestaltEditAIProfile(
            productType: productType,
            marketingName: marketingName,
            regulatoryModel: regulatoryModel
        )
    }
}
