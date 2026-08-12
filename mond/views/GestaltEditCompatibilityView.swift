import SwiftUI

private func GE(_ key: String) -> String {
    let configured = currentAppLanguage()
    let effective: AppLanguage

    if configured == .system {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") {
            effective = .zhHant
        } else if preferred.hasPrefix("zh") {
            effective = .zhHans
        } else if preferred.hasPrefix("ja") {
            effective = .ja
        } else {
            effective = .en
        }
    } else {
        effective = configured
    }

    if effective != .en,
       let path = Bundle.main.path(forResource: effective.rawValue, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let translated = bundle.localizedString(forKey: key, value: key, table: "SourceMode")
        if translated != key { return translated }
    }

    return L(key)
}

/// Uses the upstream GestaltEdit access/write implementation directly while
/// keeping Mond's independent in-app language switch and diagnostics UI.
///
/// Safety rule: source mode only patches devices that are already officially
/// Apple-Intelligence capable. It does not use GestaltEdit's forced device
/// identity spoof fallback for unsupported hardware.
struct GestaltEditCompatibilityView: View {
    @State private var status: String = ""
    @State private var currentValues: [String] = []
    @State private var detectedProductType: String = ""
    @State private var detectedMarketingName: String = ""
    @State private var targetRegulatoryModel: String = ""
    @State private var mobileGestaltValid = false
    @State private var sourceEngineReady = false
    @State private var alreadyConfigured = false
    @State private var lastBackupName = ""

    private let access = GestaltAccess.shared()

    private let regionCodeKey = "h63QSdBCiT/z0WU6rdQv6Q"
    private let sysconfigRegionInfoKey = "yK+xavymRGZ3xWc1tb8XDg"
    private let regulatoryModelKey = "97JDvERpVwO+GHtthIh7hA"
    private let thinningProductTypeKey = "0+nc/Udy4WNG8S+Q7a/s1A"

    // Display-only fields. The source-compatible patch does not modify them on
    // an already-supported iPhone/iPad.
    private let legacyRegionInfoKey = "zHeENZu+wbg7PUprwNwBWg"
    private let productTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private let modelNumberKey = "D0cJ8r7U5zve6uA6QbOiLA"
    private let greenTeaKey = "iyfxmLogGVIaH7aEgqwcIA"
    private let notGreenTeaKey = "4snMZS8LJkSctKypt2m+xA"
    private let appleIntelligenceKey = "A62OafQ85EJAiiqKn4agtg"

    var body: some View {
        List {
            Section {
                LabeledContent(GE("Write engine"), value: GE("GestaltEdit upstream source"))
                LabeledContent(L("MobileGestalt"), value: mobileGestaltValid ? L("Valid") : L("Invalid / unreadable"))
                LabeledContent(GE("Source engine"), value: sourceEngineReady ? GE("Ready") : GE("Unavailable"))
                LabeledContent(GE("Detected device"), value: detectedDeviceLabel)
                LabeledContent(L("Target regulatory model"), value: targetRegulatoryModel.isEmpty ? L("Unsupported") : targetRegulatoryModel)
                LabeledContent(GE("Patch state"), value: alreadyConfigured ? GE("Already configured") : GE("Needs patch"))
            } header: {
                Label(GE("GestaltEdit source mode"), systemImage: "checkmark.shield")
            } footer: {
                Text(GE("This page uses GestaltEdit's original bad_query lease and in-place MobileGestalt writer directly. Mond adds an independent translated UI, safe supported-device detection, backup status, and diagnostics around it."))
            }

            if alreadyConfigured {
                Section {
                    Label(GE("US Apple Intelligence region patch is already active"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(GE("No rewrite is needed. If Apple Intelligence assets are downloading, leave the region patch alone and let the download finish."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text(GE("Current status"))
                }
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
                    Label(
                        alreadyConfigured ? GE("Already configured — no write needed") : GE("Apply GestaltEdit US AI patch"),
                        systemImage: alreadyConfigured ? "checkmark.circle" : "wand.and.stars"
                    )
                }
                .disabled(!canApplyPatch)

                Button {
                    loadState()
                } label: {
                    Label(L("Reload Current Values"), systemImage: "arrow.clockwise")
                }

                if !lastBackupName.isEmpty {
                    LabeledContent(GE("Last backup"), value: lastBackupName)
                        .font(.footnote)
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(GE("A byte-for-byte backup of the live MobileGestalt file is saved before writing. On a supported device only RegionCode, RegionInfoFromSysconfig, and RegulatoryModelNumber are changed, matching GestaltEdit. Restart only after the result says Verified and MobileGestalt remains valid."))
                    Text(GE("Unsupported hardware is not force-spoofed in this safe source mode."))
                    Text(GE("GestaltEdit source mode keeps iPhone system language independent from the app language."))
                }
            }
        }
        .navigationTitle(L("GestaltEdit AI Mode"))
        .onAppear(perform: loadState)
    }

    private var detectedDeviceLabel: String {
        if !detectedMarketingName.isEmpty {
            return "\(detectedMarketingName) · \(detectedProductType)"
        }
        return detectedProductType.isEmpty ? L("(missing)") : detectedProductType
    }

    private var canApplyPatch: Bool {
        mobileGestaltValid
            && sourceEngineReady
            && !targetRegulatoryModel.isEmpty
            && !alreadyConfigured
    }

    private func loadState() {
        status = ""
        mobileGestaltValid = false
        sourceEngineReady = false
        alreadyConfigured = false
        currentValues = []
        detectedProductType = ""
        detectedMarketingName = ""
        targetRegulatoryModel = ""

        do {
            try access.connect()
            sourceEngineReady = true

            guard let current = try access.readGestalt() as? [String: Any],
                  let cache = current["CacheExtra"] as? [String: Any] else {
                status = L("MobileGestalt is empty or invalid. Do not restart the device.")
                return
            }

            mobileGestaltValid = true

            let rawProductType = (cache[thinningProductTypeKey] as? String) ?? machineName()
            detectedProductType = rawProductType.split(separator: "-").first.map(String.init) ?? rawProductType

            if let profile = GestaltEditAIProfile.resolve(cacheExtra: cache, machineIdentifier: machineName()) {
                detectedProductType = profile.productType
                detectedMarketingName = profile.marketingName
                targetRegulatoryModel = profile.regulatoryModel
            }

            alreadyConfigured = isPatchConfigured(cache)

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
        guard mobileGestaltValid, sourceEngineReady else {
            status = GE("Cannot apply: MobileGestalt or the GestaltEdit source engine is unavailable.")
            return
        }

        guard !alreadyConfigured else {
            status = GE("Already configured. No MobileGestalt write was performed.")
            return
        }

        do {
            let originalData = try access.readGestaltData()
            guard !originalData.isEmpty else {
                throw CompatibilityError.invalidGestalt
            }

            guard var current = try access.readGestalt() as? [String: Any],
                  var cache = current["CacheExtra"] as? [String: Any] else {
                throw CompatibilityError.invalidGestalt
            }

            guard let profile = GestaltEditAIProfile.resolve(cacheExtra: cache, machineIdentifier: machineName()) else {
                throw CompatibilityError.unsupportedDevice
            }

            lastBackupName = try saveBackup(originalData)

            // Supported-device path used by upstream GestaltEdit. Do not touch
            // ProductType, CPU/hardware model, ModelNumber, green-tea,
            // not-green-tea, or the generative-model capability here.
            cache[regionCodeKey] = "LL"
            cache[sysconfigRegionInfoKey] = "LL/A"
            cache[regulatoryModelKey] = profile.regulatoryModel
            current["CacheExtra"] = cache

            try access.saveGestalt(current)

            guard let verify = try access.readGestalt() as? [String: Any],
                  let verifyCache = verify["CacheExtra"] as? [String: Any],
                  verifyCache[regionCodeKey] as? String == "LL",
                  verifyCache[sysconfigRegionInfoKey] as? String == "LL/A",
                  verifyCache[regulatoryModelKey] as? String == profile.regulatoryModel else {
                throw CompatibilityError.verificationFailed
            }

            mobileGestaltValid = true
            alreadyConfigured = true
            status = "\(L("Verified")): LL · LL/A · \(profile.regulatoryModel)\n\(GE("GestaltEdit source write verified. MobileGestalt is valid. Restart the iPhone to apply the change."))"
            loadStatePreservingStatus()
        } catch {
            mobileGestaltValid = sourceGestaltStillValid()
            let warning = mobileGestaltValid ? "" : "\n\(L("MobileGestalt is invalid or empty. Do not restart the device."))"
            status = "\(L("Failed")): \(error.localizedDescription)\(warning)"
        }
    }

    private func isPatchConfigured(_ cache: [String: Any]) -> Bool {
        guard !targetRegulatoryModel.isEmpty else { return false }
        return cache[regionCodeKey] as? String == "LL"
            && cache[sysconfigRegionInfoKey] as? String == "LL/A"
            && cache[regulatoryModelKey] as? String == targetRegulatoryModel
    }

    @discardableResult
    private func saveBackup(_ data: Data) throws -> String {
        let directory = URL(fileURLWithPath: AppPaths.backups)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "GestaltEditSource-\(formatter.string(from: Date())).plist"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return filename
    }

    private func loadStatePreservingStatus() {
        let savedStatus = status
        let savedBackup = lastBackupName
        loadState()
        status = savedStatus
        lastBackupName = savedBackup
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
    case unsupportedDevice
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidGestalt:
            return L("MobileGestalt is empty or invalid. Do not restart the device.")
        case .unsupportedDevice:
            return GE("This device is not in GestaltEdit's supported Apple Intelligence profile list. Safe source mode will not force-spoof it.")
        case .verificationFailed:
            return L("The compatibility values were written but did not verify correctly.")
        }
    }
}
