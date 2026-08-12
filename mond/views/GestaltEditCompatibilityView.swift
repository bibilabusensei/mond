import SwiftUI

/// Uses the upstream GestaltEdit access/write implementation directly while
/// keeping Mond's independent in-app language switch and diagnostics UI.
struct GestaltEditCompatibilityView: View {
    @State private var status: String = ""
    @State private var currentValues: [String] = []
    @State private var detectedProductType: String = ""
    @State private var targetRegulatoryModel: String = ""
    @State private var mobileGestaltValid = false
    @State private var sourceEngineReady = false

    private let access = GestaltAccess.shared()

    private let regionCodeKey = "h63QSdBCiT/z0WU6rdQv6Q"
    private let sysconfigRegionInfoKey = "yK+xavymRGZ3xWc1tb8XDg"
    private let regulatoryModelKey = "97JDvERpVwO+GHtthIh7hA"
    private let thinningProductTypeKey = "0+nc/Udy4WNG8S+Q7a/s1A"

    // Display-only fields. The source-compatible patch does not modify them on
    // an already-supported iPhone.
    private let legacyRegionInfoKey = "zHeENZu+wbg7PUprwNwBWg"
    private let productTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private let modelNumberKey = "D0cJ8r7U5zve6uA6QbOiLA"
    private let greenTeaKey = "iyfxmLogGVIaH7aEgqwcIA"
    private let notGreenTeaKey = "4snMZS8LJkSctKypt2m+xA"
    private let appleIntelligenceKey = "A62OafQ85EJAiiqKn4agtg"

    var body: some View {
        List {
            Section {
                LabeledContent(L("Write engine"), value: L("GestaltEdit upstream source"))
                LabeledContent(L("MobileGestalt"), value: mobileGestaltValid ? L("Valid") : L("Invalid / unreadable"))
                LabeledContent(L("Source engine"), value: sourceEngineReady ? L("Ready") : L("Unavailable"))
                LabeledContent("ThinningProductType", value: detectedProductType.isEmpty ? L("(missing)") : detectedProductType)
                LabeledContent(L("Target regulatory model"), value: targetRegulatoryModel.isEmpty ? L("Unsupported") : targetRegulatoryModel)
            } header: {
                Label(L("GestaltEdit source mode"), systemImage: "checkmark.shield")
            } footer: {
                Text(L("This page now uses GestaltEdit's original bad_query lease and in-place MobileGestalt writer directly. Mond only provides the translated UI, backup display, and diagnostics around it."))
            }

            Section {
                ForEach(Array(currentValues.enumerated()), id: \.offset) { _, value in
                    Text(value)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            } header: {
                Text(L("Current values"))
            }

            Section {
                Button {
                    applySourcePatch()
                } label: {
                    Label(L("Apply GestaltEdit US AI patch"), systemImage: "wand.and.stars")
                }
                .disabled(!mobileGestaltValid || !sourceEngineReady || targetRegulatoryModel.isEmpty)

                Button {
                    loadState()
                } label: {
                    Label(L("Reload Current Values"), systemImage: "arrow.clockwise")
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } footer: {
                Text(L("A byte-for-byte backup of the live MobileGestalt file is saved before writing. Only RegionCode, RegionInfoFromSysconfig, and RegulatoryModelNumber are changed for an already-supported iPhone, matching GestaltEdit. Restart only after the result says Verified and MobileGestalt remains valid."))
            }
        }
        .navigationTitle(L("GestaltEdit AI Mode"))
        .onAppear(perform: loadState)
    }

    private func loadState() {
        status = ""
        mobileGestaltValid = false
        sourceEngineReady = false
        currentValues = []

        do {
            try access.connect()
            sourceEngineReady = true

            guard let current = try access.readGestalt() as? [String: Any],
                  let cache = current["CacheExtra"] as? [String: Any] else {
                status = L("MobileGestalt is empty or invalid. Do not restart the device.")
                return
            }

            mobileGestaltValid = true
            detectedProductType = (cache[thinningProductTypeKey] as? String) ?? machineName()
            targetRegulatoryModel = usRegulatoryModel(for: detectedProductType) ?? ""

            currentValues = [
                "RegionCode = \(display(cache[regionCodeKey]))",
                "RegionInfoFromSysconfig = \(display(cache[sysconfigRegionInfoKey]))",
                "RegulatoryModelNumber = \(display(cache[regulatoryModelKey]))",
                "ThinningProductType = \(display(cache[thinningProductTypeKey]))",
                "Legacy RegionInfo = \(display(cache[legacyRegionInfoKey]))",
                "ProductType = \(display(cache[productTypeKey]))",
                "ModelNumber = \(display(cache[modelNumberKey]))",
                "green-tea = \(display(cache[greenTeaKey]))",
                "not-green-tea = \(display(cache[notGreenTeaKey]))",
                "Apple Intelligence capability = \(display(cache[appleIntelligenceKey]))"
            ]
        } catch {
            sourceEngineReady = false
            status = "\(L("Read failed")): \(error.localizedDescription)\n\(L("Do not restart the device."))"
        }
    }

    private func applySourcePatch() {
        guard mobileGestaltValid, sourceEngineReady, !targetRegulatoryModel.isEmpty else {
            status = L("Cannot apply: MobileGestalt or a supported device profile is missing.")
            return
        }

        do {
            let originalData = try access.readGestaltData()
            guard !originalData.isEmpty else {
                throw CompatibilityError.invalidGestalt
            }
            try saveBackup(originalData)

            guard var current = try access.readGestalt() as? [String: Any],
                  var cache = current["CacheExtra"] as? [String: Any] else {
                throw CompatibilityError.invalidGestalt
            }

            // This is the supported-device path used by upstream GestaltEdit.
            // Do not touch ProductType, CPU/hardware model, ModelNumber,
            // green-tea/not-green-tea, or the generative-model capability here.
            cache[regionCodeKey] = "LL"
            cache[sysconfigRegionInfoKey] = "LL/A"
            cache[regulatoryModelKey] = targetRegulatoryModel
            current["CacheExtra"] = cache

            try access.saveGestalt(current)

            guard let verify = try access.readGestalt() as? [String: Any],
                  let verifyCache = verify["CacheExtra"] as? [String: Any],
                  verifyCache[regionCodeKey] as? String == "LL",
                  verifyCache[sysconfigRegionInfoKey] as? String == "LL/A",
                  verifyCache[regulatoryModelKey] as? String == targetRegulatoryModel else {
                throw CompatibilityError.verificationFailed
            }

            mobileGestaltValid = true
            status = "\(L("Verified")): LL · LL/A · \(targetRegulatoryModel)\n\(L("GestaltEdit source write verified. MobileGestalt is valid. Restart the iPhone to apply the change."))"
            loadStatePreservingStatus()
        } catch {
            mobileGestaltValid = sourceGestaltStillValid()
            let warning = mobileGestaltValid ? "" : "\n\(L("MobileGestalt is invalid or empty. Do not restart the device."))"
            status = "\(L("Failed")): \(error.localizedDescription)\(warning)"
        }
    }

    private func saveBackup(_ data: Data) throws {
        let directory = URL(fileURLWithPath: AppPaths.backups)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stamp = Int(Date().timeIntervalSince1970)
        let url = directory.appendingPathComponent("GestaltEditSource-\(stamp).plist")
        try data.write(to: url, options: [.atomic])
    }

    private func loadStatePreservingStatus() {
        let savedStatus = status
        loadState()
        status = savedStatus
    }

    private func sourceGestaltStillValid() -> Bool {
        do {
            return (try access.readGestalt() as? [String: Any])?["CacheExtra"] is [String: Any]
        } catch {
            return false
        }
    }

    private func display(_ value: Any?) -> String {
        guard let value else { return L("(missing)") }
        if let number = value as? NSNumber {
            return number.boolValue ? "1 / true" : "0 / false"
        }
        return String(describing: value)
    }

    /// Same supported-iPhone mapping used by GestaltEdit.
    private func usRegulatoryModel(for productType: String) -> String? {
        let base = productType.split(separator: "-").first.map(String.init) ?? productType
        switch base {
        case "iPhone16,1": return "A2848"
        case "iPhone16,2": return "A2849"
        case "iPhone17,1": return "A3083"
        case "iPhone17,2": return "A3084"
        case "iPhone17,3": return "A3081"
        case "iPhone17,4": return "A3082"
        case "iPhone17,5": return "A3212"
        default: return nil
        }
    }

    private func machineName() -> String {
        var sysInfo = utsname()
        uname(&sysInfo)
        let mirror = Mirror(reflecting: sysInfo.machine)
        return mirror.children.reduce("") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return result }
            return result + String(UnicodeScalar(UInt8(value)))
        }
    }
}

private enum CompatibilityError: LocalizedError {
    case invalidGestalt
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidGestalt:
            return L("MobileGestalt is empty or invalid. Do not restart the device.")
        case .verificationFailed:
            return L("The compatibility values were written but did not verify correctly.")
        }
    }
}
