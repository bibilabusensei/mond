import SwiftUI

struct GestaltEditCompatibilityView: View {
    @AppStorage("token") private var token: String = ""

    @State private var status: String = ""
    @State private var currentValues: [String] = []
    @State private var detectedProductType: String = ""
    @State private var targetRegulatoryModel: String = ""
    @State private var mobileGestaltValid = false
    @State private var baselineAvailable = false

    private let regionCodeKey = "h63QSdBCiT/z0WU6rdQv6Q"
    private let sysconfigRegionInfoKey = "yK+xavymRGZ3xWc1tb8XDg"
    private let regulatoryModelKey = "97JDvERpVwO+GHtthIh7hA"
    private let thinningProductTypeKey = "0+nc/Udy4WNG8S+Q7a/s1A"

    // Keys touched by earlier Mond experiments. GestaltEdit does not need these
    // for an Apple-Intelligence-capable iPhone, so compatibility mode restores
    // them from Mond's original backup before applying the three-key US patch.
    private let legacyRegionInfoKey = "zHeENZu+wbg7PUprwNwBWg"
    private let productTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private let modelNumberKey = "D0cJ8r7U5zve6uA6QbOiLA"
    private let greenTeaKey = "iyfxmLogGVIaH7aEgqwcIA"
    private let notGreenTeaKey = "4snMZS8LJkSctKypt2m+xA"
    private let appleIntelligenceKey = "A62OafQ85EJAiiqKn4agtg"
    private let hardwareModelKey = "oYicEKzVTz4/CxxE05pEgQ"
    private let cpuModelKey = "5pYKlGnYYBzGvAlIU8RjEQ"

    var body: some View {
        List {
            Section {
                LabeledContent(L("MobileGestalt"), value: mobileGestaltValid ? L("Valid") : L("Invalid / unreadable"))
                LabeledContent(L("Original backup"), value: baselineAvailable ? L("Available") : L("Missing"))
                LabeledContent("ThinningProductType", value: detectedProductType.isEmpty ? L("(missing)") : detectedProductType)
                LabeledContent(L("Target regulatory model"), value: targetRegulatoryModel.isEmpty ? L("Unsupported") : targetRegulatoryModel)
            } header: {
                Label(L("GestaltEdit compatibility"), systemImage: "checkmark.shield")
            } footer: {
                Text(L("This mode mirrors GestaltEdit's Siri AI US-region patch for already-supported iPhones: RegionCode=LL, RegionInfoFromSysconfig=LL/A, and the matching US regulatory model. It does not write SysCfg."))
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
                    applyCompatibilityPatch()
                } label: {
                    Label(L("Apply GestaltEdit-compatible US AI patch"), systemImage: "wand.and.stars")
                }
                .disabled(!mobileGestaltValid || !baselineAvailable || targetRegulatoryModel.isEmpty)

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
                Text(L("Before writing, Mond saves the current plist and restores extra identity fields previously changed by Mond from the original backup. After the three GestaltEdit-compatible values are written, the file is read back and validated. Only restart the iPhone after the result says Verified and MobileGestalt remains valid."))
            }
        }
        .navigationTitle(L("GestaltEdit AI Mode"))
        .onAppear {
            if !token.isEmpty {
                _ = sandbox_extension_consume(token)
            }
            loadState()
        }
    }

    private func loadState() {
        status = ""
        mobileGestaltValid = false
        baselineAvailable = false
        currentValues = []

        do {
            let currentURL = URL(fileURLWithPath: TweakPaths.gestalt)
            let currentData = try Data(contentsOf: currentURL)
            guard !currentData.isEmpty,
                  let current = try PropertyListSerialization.propertyList(from: currentData, options: [], format: nil) as? [String: Any],
                  let cache = current["CacheExtra"] as? [String: Any] else {
                status = L("MobileGestalt is empty or invalid. Do not restart the device.")
                return
            }

            mobileGestaltValid = true

            let backupURL = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            if let backupData = try? Data(contentsOf: backupURL),
               let backup = try? PropertyListSerialization.propertyList(from: backupData, options: [], format: nil) as? [String: Any],
               backup["CacheExtra"] is [String: Any] {
                baselineAvailable = true
            }

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
            status = "\(L("Read failed")): \(error.localizedDescription)\n\(L("Do not restart the device."))"
        }
    }

    private func applyCompatibilityPatch() {
        guard mobileGestaltValid, baselineAvailable, !targetRegulatoryModel.isEmpty else {
            status = L("Cannot apply: MobileGestalt, the original backup, or a supported device profile is missing.")
            return
        }

        do {
            let fm = FileManager.default
            let targetURL = URL(fileURLWithPath: TweakPaths.gestalt)
            let currentData = try Data(contentsOf: targetURL)
            guard !currentData.isEmpty,
                  var current = try PropertyListSerialization.propertyList(from: currentData, options: [], format: nil) as? [String: Any],
                  var cache = current["CacheExtra"] as? [String: Any] else {
                throw CompatibilityError.invalidGestalt
            }

            let originalURL = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let originalData = try Data(contentsOf: originalURL)
            guard let original = try PropertyListSerialization.propertyList(from: originalData, options: [], format: nil) as? [String: Any],
                  let originalCache = original["CacheExtra"] as? [String: Any] else {
                throw CompatibilityError.missingOriginalBackup
            }

            // Preserve a snapshot of the exact pre-compatibility state.
            let stamp = Int(Date().timeIntervalSince1970)
            let snapshotURL = URL(fileURLWithPath: AppPaths.backups)
                .appendingPathComponent("BeforeGestaltEditCompat-\(stamp).plist")
            try currentData.write(to: snapshotURL, options: [.atomic])

            // Revert fields our earlier experiments changed, so the resulting
            // delta matches GestaltEdit as closely as possible on supported devices.
            let restoreKeys = [
                legacyRegionInfoKey,
                productTypeKey,
                modelNumberKey,
                greenTeaKey,
                notGreenTeaKey,
                appleIntelligenceKey,
                hardwareModelKey,
                cpuModelKey
            ]

            for key in restoreKeys {
                if let originalValue = originalCache[key] {
                    cache[key] = originalValue
                } else {
                    cache.removeValue(forKey: key)
                }
            }

            // GestaltEdit's supported-device Siri AI US-region patch.
            cache[regionCodeKey] = "LL"
            cache[sysconfigRegionInfoKey] = "LL/A"
            cache[regulatoryModelKey] = targetRegulatoryModel
            current["CacheExtra"] = cache

            let patchedData = try PropertyListSerialization.data(fromPropertyList: current, format: .xml, options: 0)
            try atomicReplace(patchedData, at: targetURL)

            let verifyData = try Data(contentsOf: targetURL)
            guard !verifyData.isEmpty,
                  let verify = try PropertyListSerialization.propertyList(from: verifyData, options: [], format: nil) as? [String: Any],
                  let verifyCache = verify["CacheExtra"] as? [String: Any],
                  verifyCache[regionCodeKey] as? String == "LL",
                  verifyCache[sysconfigRegionInfoKey] as? String == "LL/A",
                  verifyCache[regulatoryModelKey] as? String == targetRegulatoryModel else {
                throw CompatibilityError.verificationFailed
            }

            mobileGestaltValid = true
            status = "\(L("Verified")): LL · LL/A · \(targetRegulatoryModel)\n\(L("MobileGestalt is valid. GestaltEdit's implementation expects a full iPhone restart after a verified write."))"
            loadStatePreservingStatus()
        } catch {
            mobileGestaltValid = isCurrentGestaltValid()
            let warning = mobileGestaltValid ? "" : "\n\(L("MobileGestalt is invalid or empty. Do not restart the device."))"
            status = "\(L("Failed")): \(error.localizedDescription)\(warning)"
        }
    }

    private func loadStatePreservingStatus() {
        let savedStatus = status
        loadState()
        status = savedStatus
    }

    private func atomicReplace(_ data: Data, at targetURL: URL) throws {
        let fm = FileManager.default
        let tempURL = targetURL.deletingLastPathComponent()
            .appendingPathComponent(".\(targetURL.lastPathComponent).\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: [.withoutOverwriting])
        defer { try? fm.removeItem(at: tempURL) }

        if fm.fileExists(atPath: targetURL.path) {
            _ = try fm.replaceItemAt(targetURL, withItemAt: tempURL)
        } else {
            try fm.moveItem(at: tempURL, to: targetURL)
        }
    }

    private func isCurrentGestaltValid() -> Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)), !data.isEmpty else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }

    private func display(_ value: Any?) -> String {
        guard let value else { return L("(missing)") }
        if let number = value as? NSNumber {
            return number.boolValue ? "1 / true" : "0 / false"
        }
        return String(describing: value)
    }

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
    case missingOriginalBackup
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidGestalt:
            return L("MobileGestalt is empty or invalid. Do not restart the device.")
        case .missingOriginalBackup:
            return L("The original SavedGestalt.plist backup is missing or invalid.")
        case .verificationFailed:
            return L("The compatibility values were written but did not verify correctly.")
        }
    }
}
