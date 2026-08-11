//
//  ContentView.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI

struct ContentView: View {
    @EnvironmentObject var state: AppState
    @AppStorage("mg_devicename") private var mg_devicename: String = ""
    @AppStorage("token") private var token: String = ""
    
    @State private var mg_dict_now: NSMutableDictionary = NSMutableDictionary()
    @State private var is_valid: Bool = false
    
    @State private var subtype: Int = 0
    @State private var og_subtype: Int = 0
    @State private var og_devicename: String = ""
    @State private var enable_devicename: Bool = false
    @State private var product_type: String = ""

    @State private var identity_preset: String = "custom"
    @State private var custom_regulatory_model: String = ""
    @State private var custom_region_code: String = ""
    @State private var custom_region_info: String = ""
    @State private var custom_product_type: String = ""
    @State private var legacy_region_info: String = ""
    @State private var sysconfig_region_info: String = ""
    @State private var activation_region_info: String = ""
    @State private var identity_status: String = ""
    
    @State private var show_settings: Bool = false

    private let regionCodeKey = "h63QSdBCiT/z0WU6rdQv6Q"
    private let legacyRegionInfoKey = "zHeENZu+wbg7PUprwNwBWg"
    private let sysconfigRegionInfoKey = "yK+xavymRGZ3xWc1tb8XDg"
    private let activationRegionInfoKey = "mYFYwkOYqb5fOiu1C5W6Aw"
    private let regulatoryModelKey = "97JDvERpVwO+GHtthIh7hA"
    private let productTypeKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    
    private var mg_valid: Bool {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: TweakPaths.gestalt)) else { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }
    
    private var mg_empty: Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: TweakPaths.gestalt),
              let size = attributes[.size] as? UInt64 else { return false }

        return size == 0
    }
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !mg_valid || mg_empty {
                    Section {
                        if mg_empty {
                            PlainAlert(title: L("Do not reboot!"), icon: "exclamationmark.triangle.fill", text: L("Your MobileGestalt.plist seems to be empty."), color: Color.yellow)
                        }
                        
                        if !mg_valid {
                            PlainAlert(title: L("Do not reboot!"), icon: "exclamationmark.triangle.fill", text: L("Your MobileGestalt.plist seems to be invalid."), color: Color.yellow)
                        }
                    } header: {
                        Label("Warning", systemImage: "exclamationmark.triangle")
                    } footer: {
                        Text("Rebooting now might cause a bootloop. Try pressing 'Revert Tweaks'. If the warnings dont go away after that, you're fucked.")
                    }
                }
                
                Section {
                    Button {
                        mg_apply()
                    } label: {
                        Text("Apply Tweaks")
                    }
                    
                    Button {
                        mg_revert()
                    } label: {
                        Text("Revert Tweaks")
                    }
                } footer: {
                    Text("**WARNING:** These tweaks have the capability to break features on your device or softbrick it if misused!")
                }
                
                Section {
                    Picker(selection: $subtype) {
                        Text("\(L("Original")) (\(og_subtype))").tag(og_subtype)
                        if is_device_good() {
                            Text("Disable Dynamic Island").tag(2436)
                        }
                        Text("iPhone 14 Pro").tag(2436)
                        Text("iPhone 14 Pro Max").tag(2796)
                        Text("iPhone 15 Pro Max").tag(2976)
                        if doubleSystemVersion() >= 18.0 {
                            Text("iPhone 16 Pro").tag(2622)
                            Text("iPhone 16 Pro Max").tag(2868)
                        }
                        if doubleSystemVersion() >= 26.0 {
                            Text("iPhone Air").tag(2736)
                        }
                        if hasHomeButton() {
                            Text("iPhone X Gestures").tag(2436)
                        }
                    } label: {
                        HStack {
                            Text("Subtype")
                            Spacer()
                        }
                    }
                    
                    Toggle("Custom Device Name", isOn: $enable_devicename)
                    
                    if enable_devicename {
                        TextField("Device Name", text: $mg_devicename)
                    }
                } header: {
                    Label("Device Artwork", systemImage: "paintbrush.pointed")
                }
                
                Section {
                    PlainToggle(text: L("Dynamic Island"), minSupportedVersion: 19.0, isOn: mg_key_binding(["YlEtTtHlNesRBMal1CqRaA"]))
                    PlainToggle(text: L("Always On Display"), minSupportedVersion: 18.0, isOn: mg_key_binding(["j8/Omm6s1lsmTDFsXjsBfA", "2OOJf1VhaM7NxfRok3HbWQ"]))
                    PlainToggle(text: L("AOD Vibrancy"), minSupportedVersion: 18.0, isOn: mg_key_binding(["ykpu7qyhqFweVMKtxNylWA"]))
                    PlainToggle(text: L("Charge Limit"), minSupportedVersion: 17.0, isOn: mg_key_binding(["37NVydb//GP/GrhuTN+exg"]))
                    PlainToggle(text: L("Boot Chime"), isOn: mg_key_binding(["QHxt+hGLaBPbQJbXiUJX3w"]))
                    PlainToggle(text: L("Liquid Glass LPM"), minSupportedVersion: 19.0, isOn: mg_key_binding(["SAGvsp6O6kAQ4fEfDJpC4Q"]))
                } header: {
                    Label("Software-Oriented Features", systemImage: "gearshape")
                }
                
                Section {
                    PlainToggle(text: L("Camera Control"), minSupportedVersion: 18.0, isOn: mg_key_binding(["CwvKxM2cEogD3p+HYgaW0Q", "oOV1jhJbdV3AddkcCg0AEA"]))
                    PlainToggle(text: L("Action Button"), minSupportedVersion: 17.0, isOn: mg_key_binding(["cT44WE1EohiwRzhsZ8xEsw"]))
                    PlainToggle(text: L("Crash Detection"), isOn: mg_key_binding(["HCzWusHQwZDea6nNhaKndw"]))
                    if hasHomeButton() {
                        PlainToggle(text: L("Enable Tap to Wake"), isOn: mg_key_binding(["yZf3GTRMGTuwSV/lD7Cagw"]))
                    }
                    PlainToggle(text: L("Pulse Width Modulation"), minSupportedVersion: 19.0, isOn: mg_key_binding(["6IejgN+1Fmu5/QrZFOIeNw"]))
                } header: {
                    Label("Hardware-Oriented Features", systemImage: "iphone")
                }
                
                Section {
                    PlainToggle(text: L("Security Research Device UI"), minSupportedVersion: 26.0, isOn: mg_key_binding(["XYlJKKkj2hztRP1NWWnhlw"]))
                    PlainToggle(text: L("Disable Region Restrictions"), isOn: mg_region_restrict_binding())
                    PlainToggle(text: L("Apple Intelligence"), minSupportedVersion: 18.1, isOn: mg_key_binding(["A62OafQ85EJAiiqKn4agtg"]))
                    HStack(spacing: 10) {
                        Picker("Spoofing", selection: $product_type) {
                            Text("Default").tag(machine_name())
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                if doubleSystemVersion() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSystemVersion() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSystemVersion() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                            }
                        }
                        
                        Button {
                            Alertinator.shared.alert(
                                title: L("Device Spoofing Info"),
                                body: L("Only spoof your device model if you want to download Apple Intelligence. This may break Face ID. If you decide to unspoof and want to keep Apple Intelligence, do NOT re-enter the Apple Intelligence & Siri menu in Settings.")
                            )
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Eligibility", systemImage: "checklist")
                }

                Section {
                    Picker("Preset", selection: $identity_preset) {
                        Text("Custom").tag("custom")
                        Text("United States (LL/A)").tag("us")
                        Text("Hong Kong / Macau (ZP/A)").tag("hk")
                        Text("Japan (J/A)").tag("jp")
                        Text("China Mainland (CH/A)").tag("cn")
                    }
                    .onChange(of: identity_preset) { newValue in
                        apply_identity_preset(newValue)
                    }

                    TextField("Regulatory Model (e.g. A2848)", text: $custom_regulatory_model)
                    TextField("Region Code (e.g. LL)", text: $custom_region_code)
                    TextField("Region Info (e.g. LL/A)", text: $custom_region_info)
                    TextField("Product Type (e.g. iPhone16,1)", text: $custom_product_type)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Read-back diagnostics")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(L("Legacy RegionInfo")): \(legacy_region_info.isEmpty ? L("(missing)") : legacy_region_info)")
                            .font(.caption)
                        Text("\(L("Sysconfig RegionInfo")): \(sysconfig_region_info.isEmpty ? L("(missing)") : sysconfig_region_info)")
                            .font(.caption)
                        Text("\(L("Activation RegionInfo")): \(activation_region_info.isEmpty ? L("(missing)") : activation_region_info)")
                            .font(.caption)
                    }

                    Button {
                        apply_custom_identity()
                    } label: {
                        Text("Apply Identity & Verify")
                    }

                    Button {
                        identity_status = ""
                        mg_load()
                    } label: {
                        Text("Reload Current Values")
                    }

                    if !identity_status.isEmpty {
                        Text(identity_status)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Device Region Identity", systemImage: "globe.americas")
                } footer: {
                    Text("Writes RegulatoryModelNumber, RegionCode, legacy RegionInfo and the newer RegionInfoFromSysconfig, then reads the plist back to verify. RegionInfoFromActivation is shown for diagnostics only and is not modified. Wrong identity values may break device features; keep your backup. Settings > General > Language & Region and Siri language are separate system settings and should be changed manually when needed.")
                }
                
                Section {
                    let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary
                    
                    PlainToggle(text: L("Allow Installing iPadOS Apps"), isOn: mg_key_binding(["9MZ5AdH43csAUajl/dU+IQ"], type: [Int].self, default_val: [1], on_val: [1, 2]))
                    PlainToggle(text: L("Apple Pencil Settings"), isOn: mg_key_binding(["yhHcB0iH0d1XzPO/CFd3ow"]))
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        PlainToggle(text: L("Stage Manager"), isOn: mg_key_binding(["qeaj75wk3HF4DwQ8qbIi7g"]))
                    }
                    PlainToggle(
                        text: L("iPadOS UI"),
                        infoType: .warning,
                        infoTitle: L("Warning!"),
                        infoMessage: L("This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. But I guess some funny multitasking features that still make the device relatively unusable are cool? Whatever dude, I'm not here to tell you how to use your own device."),
                        isOn: mg_trollpad_binding()
                    )
                    .disabled(cache_extra?["+3Uf0Pm5F8Xy7Onyvko0vA"] as? String != "iPhone")
                } header: {
                    Label("iPadOS Features", systemImage: "ipad")
                }
                
                Section {
                    PlainToggle(text: L("Internal Storage"), isOn: mg_key_binding(["LBJfwOEzExRxzlAnSuI7eg"]))
                    PlainToggle(text: L("Internal Features"), isOn: mg_internal_binding())
                    PlainToggle(text: L("Metal HUD in All Apps"), isOn: mg_key_binding(["EqrsVvjcYDdxHBiQmGhAWw"]))
                } header: {
                    Label("Internal", systemImage: "ant")
                }
            }
            .navigationTitle("mond")
            .tint(Color("AccentColor"))
            .onAppear {
                if !valid {
                    state.exploit_succeeded = grant_mg_write() >= 0
                } else {
                    print("(mond) valid token saved, skipping exploit")
                    state.exploit_succeeded = true
                }
                
                mg_load()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            show_settings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $show_settings) {
                SettingsView()
            }
        }
    }
    
    private enum MGViewError: Error, LocalizedError {
        case missingArtworkSubtype
        case missingArtworkDeviceName
        case invalidIdentity(String)
        case identityVerificationFailed
        
        var errorDescription: String? {
            switch self {
            case .missingArtworkSubtype:
                return L("Failed to get ArtworkDeviceSubType!")
            case .missingArtworkDeviceName:
                return L("Failed to get ArtworkDeviceProductDescription!")
            case .invalidIdentity(let message):
                return message
            case .identityVerificationFailed:
                return L("The MobileGestalt file was written, but the requested identity values did not read back correctly.")
            }
        }
    }
    
    private func mg_load() {
        do {
            let mg_url_now = URL(fileURLWithPath: TweakPaths.gestalt)
            mg_dict_now = try NSMutableDictionary(contentsOf: mg_url_now, error: ())
            
            let mg_url_saved = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            
            if !FileManager.default.fileExists(atPath: mg_url_saved.path) {
                try FileManager.default.copyItem(at: mg_url_now, to: mg_url_saved)
            }
            
            let mg_saved_dict = try NSMutableDictionary(contentsOf: mg_url_saved, error: ())
            let og_cache_extra = mg_saved_dict["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let og_artwork = og_cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            guard let ogSubtype = og_artwork["ArtworkDeviceSubType"] as? Int else { throw MGViewError.missingArtworkSubtype }
            og_subtype = ogSubtype
            
            guard let ogDeviceName = og_artwork["ArtworkDeviceProductDescription"] as? String else { throw MGViewError.missingArtworkDeviceName }
            
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            let artwork = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            
            subtype = artwork["ArtworkDeviceSubType"] as? Int ?? ogSubtype
            mg_devicename = artwork["ArtworkDeviceProductDescription"] as? String ?? ogDeviceName
            
            if mg_devicename != ogDeviceName {
                enable_devicename = true
            }
            
            if let productType = cache_extra[productTypeKey] as? String, !productType.isEmpty {
                product_type = productType
            } else {
                product_type = machine_name()
            }

            load_identity_fields(from: cache_extra)
        } catch {
            print("(mg) failed to load data: \(error)")
            Alertinator.shared.alert(title: L("Failed to load current MobileGestalt!"), body: L("Restart the app and try again. Check logs for more detailed information."))
        }
    }

    private func load_identity_fields(from cache_extra: NSMutableDictionary) {
        custom_regulatory_model = cache_extra[regulatoryModelKey] as? String ?? ""
        custom_region_code = cache_extra[regionCodeKey] as? String ?? ""
        legacy_region_info = cache_extra[legacyRegionInfoKey] as? String ?? ""
        sysconfig_region_info = cache_extra[sysconfigRegionInfoKey] as? String ?? ""
        activation_region_info = cache_extra[activationRegionInfoKey] as? String ?? ""
        custom_region_info = !sysconfig_region_info.isEmpty ? sysconfig_region_info : legacy_region_info
        custom_product_type = cache_extra[productTypeKey] as? String ?? machine_name()
        identity_preset = preset_for(regionCode: custom_region_code, regionInfo: custom_region_info)
    }

    private func preset_for(regionCode: String, regionInfo: String) -> String {
        switch (regionCode.uppercased(), regionInfo.uppercased()) {
        case ("LL", "LL/A"):
            return "us"
        case ("ZP", "ZP/A"):
            return "hk"
        case ("J", "J/A"):
            return "jp"
        case ("CH", "CH/A"):
            return "cn"
        default:
            return "custom"
        }
    }

    private func apply_identity_preset(_ preset: String) {
        switch preset {
        case "us":
            custom_region_code = "LL"
            custom_region_info = "LL/A"
        case "hk":
            custom_region_code = "ZP"
            custom_region_info = "ZP/A"
        case "jp":
            custom_region_code = "J"
            custom_region_info = "J/A"
        case "cn":
            custom_region_code = "CH"
            custom_region_info = "CH/A"
        default:
            return
        }

        let productType = custom_product_type.isEmpty ? machine_name() : custom_product_type
        if let model = regulatory_model(for: productType, preset: preset) {
            custom_regulatory_model = model
        }
    }

    private func regulatory_model(for productType: String, preset: String) -> String? {
        switch productType {
        case "iPhone16,1": // iPhone 15 Pro
            switch preset {
            case "us": return "A2848"
            case "jp": return "A3101"
            case "hk", "cn": return "A3104"
            default: return nil
            }
        case "iPhone16,2": // iPhone 15 Pro Max
            switch preset {
            case "us": return "A2849"
            case "jp": return "A3105"
            case "hk", "cn": return "A3108"
            default: return nil
            }
        case "iPhone17,3": // iPhone 16
            switch preset {
            case "us": return "A3081"
            case "jp": return "A3286"
            case "hk", "cn": return "A3288"
            default: return nil
            }
        case "iPhone17,4": // iPhone 16 Plus
            switch preset {
            case "us": return "A3082"
            case "jp": return "A3289"
            case "hk", "cn": return "A3291"
            default: return nil
            }
        case "iPhone17,1": // iPhone 16 Pro
            switch preset {
            case "us": return "A3083"
            case "jp": return "A3292"
            case "hk", "cn": return "A3294"
            default: return nil
            }
        case "iPhone17,2": // iPhone 16 Pro Max
            switch preset {
            case "us": return "A3084"
            case "jp": return "A3295"
            case "hk", "cn": return "A3297"
            default: return nil
            }
        case "iPhone18,3": // iPhone 17
            switch preset {
            case "us": return "A3258"
            case "jp": return "A3519"
            case "cn": return "A3521"
            case "hk": return "A3520"
            default: return nil
            }
        case "iPhone18,1": // iPhone 17 Pro
            switch preset {
            case "us": return "A3256"
            case "jp": return "A3522"
            case "cn": return "A3524"
            case "hk": return "A3523"
            default: return nil
            }
        case "iPhone18,2": // iPhone 17 Pro Max
            switch preset {
            case "us": return "A3257"
            case "jp": return "A3525"
            case "cn": return "A3527"
            case "hk": return "A3526"
            default: return nil
            }
        case "iPhone18,4": // iPhone Air
            switch preset {
            case "us": return "A3260"
            case "jp": return "A3516"
            case "cn": return "A3518"
            case "hk": return "A3517"
            default: return nil
            }
        default:
            return nil
        }
    }

    private func apply_custom_identity() {
        do {
            let model = custom_regulatory_model.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let regionCode = custom_region_code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let regionInfo = custom_region_info.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let productType = custom_product_type.trimmingCharacters(in: .whitespacesAndNewlines)

            if !model.isEmpty && model.range(of: #"^A[0-9]{4}$"#, options: .regularExpression) == nil {
                throw MGViewError.invalidIdentity(L("Regulatory Model must look like A2848 (A followed by four digits), or be left empty to keep the current value."))
            }
            if regionCode.range(of: #"^[A-Z0-9]{1,4}$"#, options: .regularExpression) == nil {
                throw MGViewError.invalidIdentity(L("Region Code must contain 1-4 uppercase letters/numbers, for example LL, ZP, J or CH."))
            }
            if regionInfo.range(of: #"^[A-Z0-9]{1,4}/A$"#, options: .regularExpression) == nil {
                throw MGViewError.invalidIdentity(L("Region Info must look like LL/A, ZP/A, J/A or CH/A."))
            }
            if !productType.isEmpty && productType.range(of: #"^[A-Za-z]+[0-9]+,[0-9]+$"#, options: .regularExpression) == nil {
                throw MGViewError.invalidIdentity(L("Product Type must look like iPhone16,1 or iPad16,3, or be left empty."))
            }

            guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
                throw MGViewError.invalidIdentity(L("MobileGestalt CacheExtra is missing."))
            }

            cache_extra[regionCodeKey] = regionCode
            cache_extra[legacyRegionInfoKey] = regionInfo
            cache_extra[sysconfigRegionInfoKey] = regionInfo
            if !model.isEmpty {
                cache_extra[regulatoryModelKey] = model
            }
            if !productType.isEmpty {
                cache_extra[productTypeKey] = productType
                product_type = productType
            }

            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)
            try mg_write(data)

            let verifyURL = URL(fileURLWithPath: TweakPaths.gestalt)
            let verifyDict = try NSMutableDictionary(contentsOf: verifyURL, error: ())
            guard let verifiedCache = verifyDict["CacheExtra"] as? NSMutableDictionary else {
                throw MGViewError.identityVerificationFailed
            }

            let codeOK = verifiedCache[regionCodeKey] as? String == regionCode
            let legacyOK = verifiedCache[legacyRegionInfoKey] as? String == regionInfo
            let sysconfigOK = verifiedCache[sysconfigRegionInfoKey] as? String == regionInfo
            let modelOK = model.isEmpty || verifiedCache[regulatoryModelKey] as? String == model
            let productOK = productType.isEmpty || verifiedCache[productTypeKey] as? String == productType

            guard codeOK && legacyOK && sysconfigOK && modelOK && productOK else {
                throw MGViewError.identityVerificationFailed
            }

            identity_status = "\(L("Verified")): \(model.isEmpty ? L("model unchanged") : model) · \(regionCode) · \(regionInfo) · \(productType.isEmpty ? L("ProductType unchanged") : productType)"
            print("(identity) verified RegulatoryModel=\(model.isEmpty ? "unchanged" : model), RegionCode=\(regionCode), RegionInfo=\(regionInfo), ProductType=\(productType.isEmpty ? "unchanged" : productType)")
            mg_load()
            Alertinator.shared.alert(title: L("Identity patch verified"), body: L("The requested MobileGestalt identity values were written and read back successfully. Respring first; some region identity changes may require a full reboot."), actionLabel: L("Respring"), action: {
                state.respring()
            })
        } catch {
            identity_status = "\(L("Failed")): \(error.localizedDescription)"
            print("(identity) failed: \(error)")
            Alertinator.shared.alert(title: L("Identity patch failed"), body: error.localizedDescription)
        }
    }
    
    private func mg_apply() {
        do {
            let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary ?? NSMutableDictionary()
            if !product_type.isEmpty {
                cache_extra[productTypeKey] = product_type
            }
            
            let artwork_dict = cache_extra["oPeik/9e8lQWMszEjbPzng"] as? NSMutableDictionary ?? NSMutableDictionary()
            artwork_dict["ArtworkDeviceSubType"] = subtype
            if enable_devicename {
                artwork_dict["ArtworkDeviceProductDescription"] = mg_devicename
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mg_dict_now, format: .xml, options: 0)

            try mg_write(data)
            enable_devicename = false
            mg_load()

            print("(mg) successfully overwrote mobilegestalt!")
            Alertinator.shared.alert(title: L("Successfully applied Gestalt tweaks!"), body: L("Respring your device for changes to take effect. Note that some tweaks may require a reboot for them to apply properly."), actionLabel: L("Respring"), action: {
                state.respring()
            })
        } catch {
            print("(mg) failed to apply mobilegestalt: \(error)")
            Alertinator.shared.alert(title: L("Failed to apply MobileGestalt!"), body: L("Restart the app and try again. Check logs for more detailed information."))
        }
    }
    
    private func mg_revert() {
        do {
            let backup_url = URL(fileURLWithPath: AppPaths.backups).appendingPathComponent("SavedGestalt.plist")
            let backup_data = try Data(contentsOf: backup_url)
            try mg_write(backup_data)
            mg_load()

            print("(mg) successfully reverted mobilegestalt!)")
            Alertinator.shared.alert(title: L("Successfully reverted Gestalt tweaks!"), body: L("Reboot your device for changes to take effect."))
        } catch {
            print("(mg) failed to revert mobilegestalt: \(error)")
            Alertinator.shared.alert(title: L("Failed to revert MobileGestalt!"), body: L("Check logs for error information."))
        }
    }

    private func mg_write(_ data: Data) throws {
        let target_url = URL(fileURLWithPath: TweakPaths.gestalt)
        let temp_url = target_url.deletingLastPathComponent()
            .appendingPathComponent(".\(target_url.lastPathComponent).\(UUID().uuidString).tmp")

        try data.write(to: temp_url, options: [.withoutOverwriting])
        defer { try? fm.removeItem(at: temp_url) }

        if fm.fileExists(atPath: target_url.path) {
            _ = try fm.replaceItemAt(target_url, withItemAt: temp_url)
        } else {
            try fm.moveItem(at: temp_url, to: target_url)
        }
    }
    
    private func mg_key_binding<T: Equatable>(_ keys: [String], type: T.Type = Int.self, default_val: T? = 0, on_val: T? = 1) -> Binding<Bool>  {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? T?, let on_val {
                return value == on_val
            }
            
            return false
        }, set: { enabled in
            for key in keys {
                if enabled {
                    cache_extra[key] = on_val
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_trollpad_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData,
                let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        let value_off = cache_data_offset("mtrAoWJ3gsq+I90ZnQ0vQw")
        let keys = [
            "uKc7FPnEO++lVhHWHFlGbQ",
            "mG0AnH/Vy1veoqoLRAIgTA",
            "UCG5MkVahJxG1YULbbd5Bg",
            "ZYqko/XM5zD3XBfN5RmaXA",
            "nVh/gwNpy7Jv1NOk00CMrw",
            "qeaj75wk3HF4DwQ8qbIi7g",
        ]
        
        return Binding(get: {
            if let value = cache_extra[keys.first!] as? Int? {
                return value == 1
            }
            
            return false
        }, set: { enabled in
            if enabled {
                Alertinator.shared.alert(title: L("Warning!"), body: L("This is a very dangerous tweak to use! If you use an alphanumeric passcode, DO NOT USE THIS TWEAK AT ALL! Please do not turn off \"Show Dock In Stage Manager\" or your device will BOOTLOOP when rotating to landscape! With these two things in mind, you may experience general instability, or other major issues such as app data randomly disappearing. I'm honestly not too certain why you'd want to use this tweak anyways, it's not like your device is gonna be all that usable (due to apps scaling weirdly) when it's enabled."))
            }
            
            cache_data.mutableBytes.storeBytes(of: enabled ? 3 : 1, toByteOffset: value_off, as: Int.self)
            
            for key in keys {
                if enabled {
                    cache_extra[key] = 1
                } else {
                    cache_extra.removeObject(forKey: key)
                }
            }
        })
    }
    
    private func mg_region_restrict_binding() -> Binding<Bool> {
        guard let cache_extra = mg_dict_now["CacheExtra"] as? NSMutableDictionary else {
            return .constant(false)
        }
        
        return Binding<Bool>(
            get: {
                let code = cache_extra[regionCodeKey] as? String
                let legacy = cache_extra[legacyRegionInfoKey] as? String
                let sysconfig = cache_extra[sysconfigRegionInfoKey] as? String
                return code == "LL" && (legacy == "LL/A" || sysconfig == "LL/A")
            },
            set: { enabled in
                if enabled {
                    Alertinator.shared.alert(title: L("Warning!"), body: L("Please do not use this feature to bypass region restrictions that would equate to breaking regional laws (e.g. disabling the camera shutter sound). We will NOT be held responsible for enabling any illegal activites!"))
                    cache_extra[regionCodeKey] = "LL"
                    cache_extra[legacyRegionInfoKey] = "LL/A"
                    cache_extra[sysconfigRegionInfoKey] = "LL/A"
                } else {
                    cache_extra.removeObject(forKey: regionCodeKey)
                    cache_extra.removeObject(forKey: legacyRegionInfoKey)
                    cache_extra.removeObject(forKey: sysconfigRegionInfoKey)
                }
            }
        )
    }
    
    private func mg_internal_binding() -> Binding<Bool> {
        guard let cache_data = mg_dict_now["CacheData"] as? NSMutableData else {
            return .constant(false)
        }
        
        let off_apple_internal_install = cache_data_offset("EqrsVvjcYDdxHBiQmGhAWw")
        let off_has_internal_settings_bundle = cache_data_offset("Oji6HRoPi7rH7HPdWVakuw")
        let off_internal_build = cache_data_offset("LBJfwOEzExRxzlAnSuI7eg")
        
        return Binding(
            get: {
                return cache_data.bytes.load(fromByteOffset: off_apple_internal_install, as: Int.self) == 1
            },
            set: { enabled in
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_apple_internal_install, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_has_internal_settings_bundle, as: Int.self)
                cache_data.mutableBytes.storeBytes(of: enabled ? 1 : 0, toByteOffset: off_internal_build, as: Int.self)
            }
        )
    }
    
    private func is_device_good() -> Bool {
        let supported: [String] = ["iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2", "iPhone17,3", "iPhone17,4", "iPhone17,1", "iPhone17,2", "iPhone18,3", "iPhone18,1", "iPhone18,2", "iPhone17,5"]
        
        if supported.contains(machine_name()) && doubleSystemVersion() < 19.0 {
            return true
        }
        
        return false
    }
    
    private func machine_name() -> String {
        var sys_info = utsname()
        uname(&sys_info)
        let machine_mirror = Mirror(reflecting: sys_info.machine)
        
        return machine_mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
