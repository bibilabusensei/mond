import SwiftUI
import Foundation

private struct AIDiagnosticItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let state: AIDiagnosticState
}

private enum AIDiagnosticState {
    case good
    case warning
    case neutral

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .neutral: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .neutral: return .gray
        }
    }
}

struct AppleIntelligenceDiagnosticsView: View {
    @AppStorage("token") private var token: String = ""

    @State private var systemItems: [AIDiagnosticItem] = []
    @State private var gestaltItems: [AIDiagnosticItem] = []
    @State private var eligibilityAccess: String = ""
    @State private var eligibilityMatches: [String] = []
    @State private var lastUpdated: Date? = nil

    private let regionCodeKey = "h63QSdBCiT/z0WU6rdQv6Q"
    private let legacyRegionInfoKey = "zHeENZu+wbg7PUprwNwBWg"
    private let sysconfigRegionInfoKey = "yK+xavymRGZ3xWc1tb8XDg"
    private let activationRegionInfoKey = "mYFYwkOYqb5fOiu1C5W6Aw"
    private let regulatoryModelKey = "97JDvERpVwO+GHtthIh7hA"
    private let modelNumberKey = "D0cJ8r7U5zve6uA6QbOiLA"
    private let productTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    private let appleIntelligenceKey = "A62OafQ85EJAiiqKn4agtg"
    private let greenTeaKey = "iyfxmLogGVIaH7aEgqwcIA"
    private let notGreenTeaKey = "4snMZS8LJkSctKypt2m+xA"

    var body: some View {
        List {
            Section {
                ForEach(systemItems) { item in
                    diagnosticRow(item)
                }
            } header: {
                Label(L("System Environment"), systemImage: "iphone")
            } footer: {
                Text(L("This page is read-only. The device language shown here is the app/system preferred language; Siri language is evaluated separately by iOS and may only appear inside eligibilityd data when that file is readable."))
            }

            Section {
                ForEach(gestaltItems) { item in
                    diagnosticRow(item)
                }
            } header: {
                Label(L("MobileGestalt Identity"), systemImage: "checklist")
            }

            Section {
                HStack(alignment: .top) {
                    Image(systemName: eligibilityMatches.isEmpty ? "lock.trianglebadge.exclamationmark" : "doc.text.magnifyingglass")
                        .foregroundStyle(eligibilityMatches.isEmpty ? Color.orange : Color.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("eligibilityd")
                            .font(.headline)
                        Text(eligibilityAccess.isEmpty ? L("Not checked") : eligibilityAccess)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !eligibilityMatches.isEmpty {
                    ForEach(Array(eligibilityMatches.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            } header: {
                Label(L("Apple Intelligence Eligibility"), systemImage: "brain.head.profile")
            } footer: {
                Text(L("Mond only attempts to read eligibilityd here. It does not modify eligibility.plist. If access is denied, that result is useful: the current MobileGestalt sandbox token does not grant access to eligibilityd and a different read path would be required before deeper diagnosis."))
            }

            Section {
                Button {
                    refreshDiagnostics()
                } label: {
                    Label(L("Refresh Diagnostics"), systemImage: "arrow.clockwise")
                }

                if let lastUpdated {
                    Text("\(L("Last updated")): \(lastUpdated.formatted(date: .omitted, time: .standard))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(L("AI Diagnostics"))
        .onAppear {
            refreshDiagnostics()
        }
    }

    @ViewBuilder
    private func diagnosticRow(_ item: AIDiagnosticItem) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: item.state.icon)
                .foregroundStyle(item.state.color)
                .frame(width: 22)
            Text(item.title)
            Spacer(minLength: 12)
            Text(item.value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }

    private func refreshDiagnostics() {
        if !token.isEmpty {
            _ = sandbox_extension_consume(token)
        }

        let preferredLanguage = Locale.preferredLanguages.first ?? L("(missing)")
        let currentLocale = Locale.current.identifier
        let currentRegion: String
        if #available(iOS 16.0, *) {
            currentRegion = Locale.current.region?.identifier ?? L("(missing)")
        } else {
            currentRegion = Locale.current.regionCode ?? L("(missing)")
        }

        systemItems = [
            AIDiagnosticItem(title: L("iOS Version"), value: UIDevice.current.systemVersion, state: .neutral),
            AIDiagnosticItem(title: L("Hardware ProductType"), value: machineName(), state: .neutral),
            AIDiagnosticItem(title: L("Preferred Language"), value: preferredLanguage, state: preferredLanguage.lowercased().hasPrefix("en") ? .good : .neutral),
            AIDiagnosticItem(title: L("Current Locale"), value: currentLocale, state: .neutral),
            AIDiagnosticItem(title: L("Current Region"), value: currentRegion, state: currentRegion == "US" ? .good : .neutral)
        ]

        loadMobileGestaltDiagnostics()
        loadEligibilityDiagnostics()
        lastUpdated = Date()
    }

    private func loadMobileGestaltDiagnostics() {
        do {
            let url = URL(fileURLWithPath: TweakPaths.gestalt)
            let dict = try NSMutableDictionary(contentsOf: url, error: ())
            guard let cache = dict["CacheExtra"] as? NSDictionary else {
                gestaltItems = [AIDiagnosticItem(title: "MobileGestalt", value: L("CacheExtra missing"), state: .warning)]
                return
            }

            let regionCode = stringValue(cache[regionCodeKey])
            let legacyRegion = stringValue(cache[legacyRegionInfoKey])
            let sysconfigRegion = stringValue(cache[sysconfigRegionInfoKey])
            let activationRegion = stringValue(cache[activationRegionInfoKey])
            let regulatoryModel = stringValue(cache[regulatoryModelKey])
            let retailModel = stringValue(cache[modelNumberKey])
            let productType = stringValue(cache[productTypeKey])
            let aiEnabled = boolValue(cache[appleIntelligenceKey])
            let greenTea = boolValue(cache[greenTeaKey])
            let notGreenTea = boolValue(cache[notGreenTeaKey])

            gestaltItems = [
                AIDiagnosticItem(title: L("Regulatory Model"), value: regulatoryModel, state: regulatoryModel == "A2848" ? .good : .neutral),
                AIDiagnosticItem(title: L("Retail Model Base"), value: retailModel, state: .neutral),
                AIDiagnosticItem(title: L("Region Code"), value: regionCode, state: regionCode == "LL" ? .good : .neutral),
                AIDiagnosticItem(title: L("Legacy RegionInfo"), value: legacyRegion, state: legacyRegion == "LL/A" ? .good : .neutral),
                AIDiagnosticItem(title: L("Sysconfig RegionInfo"), value: sysconfigRegion, state: sysconfigRegion == "LL/A" ? .good : .neutral),
                AIDiagnosticItem(title: L("Activation RegionInfo"), value: activationRegion, state: .neutral),
                AIDiagnosticItem(title: "ProductType", value: productType, state: .neutral),
                AIDiagnosticItem(title: L("Apple Intelligence capability"), value: aiEnabled == true ? "1 / true" : displayBool(aiEnabled), state: aiEnabled == true ? .good : .warning),
                AIDiagnosticItem(title: L("green-tea (China market)"), value: displayBool(greenTea), state: greenTea == true ? .warning : .good),
                AIDiagnosticItem(title: L("not-green-tea (non-China market)"), value: displayBool(notGreenTea), state: notGreenTea == true ? .good : .warning)
            ]
        } catch {
            gestaltItems = [
                AIDiagnosticItem(title: "MobileGestalt", value: "\(L("Read failed")): \(error.localizedDescription)", state: .warning)
            ]
        }
    }

    private func loadEligibilityDiagnostics() {
        let candidates = [
            "/private/var/db/eligibilityd/eligibility.plist",
            "/var/db/eligibilityd/eligibility.plist"
        ]

        var errors: [String] = []
        eligibilityMatches = []

        for path in candidates {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                var matches: [String] = []
                collectInterestingEntries(plist, path: "root", depth: 0, into: &matches)
                eligibilityAccess = "\(L("Readable")): \(path) · \(data.count) bytes"
                eligibilityMatches = matches.isEmpty ? [L("File is readable, but no GREYMATTER/language/region/model eligibility fields were matched.")] : Array(matches.prefix(80))
                return
            } catch {
                let nsError = error as NSError
                errors.append("\((path as NSString).lastPathComponent): \(nsError.domain) \(nsError.code) · \(nsError.localizedDescription)")
            }
        }

        eligibilityAccess = "\(L("Not readable with current sandbox"))\n" + errors.joined(separator: "\n")
    }

    private func collectInterestingEntries(_ object: Any, path: String, depth: Int, into output: inout [String]) {
        guard depth < 12, output.count < 120 else { return }

        let needles = ["grey", "matter", "eligib", "siri", "language", "region", "model", "china", "device", "answer", "status", "generative"]

        if let dict = object as? [String: Any] {
            for key in dict.keys.sorted() {
                guard output.count < 120 else { return }
                let value = dict[key]!
                let lowerKey = key.lowercased()
                let interesting = needles.contains { lowerKey.contains($0) }

                if interesting, !(value is [String: Any]), !(value is [Any]) {
                    output.append("\(path).\(key) = \(compactDescription(value))")
                }
                collectInterestingEntries(value, path: "\(path).\(key)", depth: depth + 1, into: &output)
            }
        } else if let dict = object as? NSDictionary {
            for rawKey in dict.allKeys {
                guard output.count < 120 else { return }
                let key = String(describing: rawKey)
                guard let value = dict[rawKey] else { continue }
                let lowerKey = key.lowercased()
                let interesting = needles.contains { lowerKey.contains($0) }
                if interesting, !(value is NSDictionary), !(value is NSArray) {
                    output.append("\(path).\(key) = \(compactDescription(value))")
                }
                collectInterestingEntries(value, path: "\(path).\(key)", depth: depth + 1, into: &output)
            }
        } else if let array = object as? [Any] {
            for (index, value) in array.enumerated() {
                collectInterestingEntries(value, path: "\(path)[\(index)]", depth: depth + 1, into: &output)
                if output.count >= 120 { return }
            }
        } else if let array = object as? NSArray {
            for (index, value) in array.enumerated() {
                collectInterestingEntries(value, path: "\(path)[\(index)]", depth: depth + 1, into: &output)
                if output.count >= 120 { return }
            }
        }
    }

    private func stringValue(_ value: Any?) -> String {
        guard let value else { return L("(missing)") }
        if let string = value as? String, !string.isEmpty { return string }
        return String(describing: value)
    }

    private func boolValue(_ value: Any?) -> Bool? {
        if let number = value as? NSNumber { return number.boolValue }
        if let bool = value as? Bool { return bool }
        return nil
    }

    private func displayBool(_ value: Bool?) -> String {
        guard let value else { return L("(missing)") }
        return value ? "1 / true" : "0 / false"
    }

    private func compactDescription(_ value: Any) -> String {
        if let data = value as? Data { return "Data(\(data.count) bytes)" }
        let text = String(describing: value).replacingOccurrences(of: "\n", with: " ")
        return text.count > 180 ? String(text.prefix(180)) + "…" : text
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
