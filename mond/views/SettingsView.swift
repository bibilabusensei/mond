//
//  SettingsView.swift
//  mond
//
//  Created by ruter on 18.07.26.
//

import SwiftUI
import PartyUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var state: AppState
    
    @AppStorage("token") private var token: String = ""
    @AppStorage("method") private var method: String = "bad_query"
    @AppStorage("app_language") private var appLanguageRaw: String = AppLanguage.system.rawValue
    @State private var show_confirm: Bool = false
    
    var valid: Bool {
        (sandbox_extension_consume(token) ?? -1) >= 0
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = URL(string: "https://github.com/rooootdev/mond"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
                               let files = primary["CFBundleIconFiles"] as? [String],
                               let icon = files.last,
                               let img = UIImage(named: icon) {
                                Image(uiImage: img)
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                     ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                                     ?? L("Unknown App"))
                                .font(.headline)
                                
                                Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tertiary)
                                .imageScale(.small)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section {
                    Picker("App Language", selection: $appLanguageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                } header: {
                    Label("Language", systemImage: "globe")
                } footer: {
                    Text("Changes the Mond interface language only. It does not change the iPhone system language, region, or Siri language.")
                }
                
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    Label("Logs", systemImage: "apple.terminal")
                }
                
                Section {
                    HStack {
                        TextField("Sandbox Extension Token", text: $token)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Image(systemName: "document.on.document")
                        }
                    }
                    .contextMenu {
                        Text("\(L("Class")): \(token.split(separator: ";").first { $0.contains("com.apple") }.map(String.init) ?? L("N/A"))")
                        Text("\(L("Path")): \(token.split(separator: ";").last.map(String.init) ?? L("N/A"))")
                        
                        Button {
                            UIPasteboard.general.string = token
                        } label: {
                            Label("Copy token", systemImage: "doc.on.doc")
                        }
                    }
                    .lineLimit(1)
                    
                    Button {
                        token = sandbox_extension_issue_file(path: TweakPaths.gestalt_dir) ?? L("Failed to get token.")
                    } label: {
                        Text("Generate Token")
                    }
                    .disabled(!state.exploit_succeeded)
                } header: {
                    Label("Token", systemImage: "key")
                } footer: {
                    if !token.isEmpty {
                        if valid {
                            Text("Your sandbox token is valid.")
                        } else {
                            Text("Your sandbox token is invalid.")
                        }
                    }
                    
                    if !state.exploit_succeeded {
                        Text("Disabled because the exploit failed. Is your iOS version supported?")
                    }
                }
                
                Section {
                    Picker("Method", selection: $method) {
                        Text("bad_query").tag("bad_query")
                        Text("cmg").tag("cmg")
                    }
                    .pickerStyle(.segmented)
                    
                    Button {
                        _ = grant_mg_write()
                    } label: {
                        Text("Run Exploit")
                    }
                } header: {
                    Label("Exploit", systemImage: "wrench.and.screwdriver")
                } footer: {
                    Text(method == "cmg"
                         ? L("CMG supports iOS 27.0 beta 1 through beta 4. Normally prefer bad_query; try CMG if bad_query cannot write.")
                         : L("bad_query supports iOS 27.0 beta 1 through beta 4. By forcequit."))
                }
                
                Section {
                    Button {
                        show_confirm = true
                    } label: {
                        Text("Respring")
                    }
                } header: {
                    Label("Tools", systemImage: "wrench.and.screwdriver")
                }
                
                Section {
                    CreditsRow(name: "roooot", role: L("Main developer"), profile: URL(string: "https://github.com/rooootdev")!)
                    CreditsRow(name: "forcequit", role: L("The bad_query exploit"), profile: URL(string: "https://github.com/forcequitOS")!)
                    CreditsRow(name: "johnny", role: L("MCM bug research"), profile: URL(string: "https://github.com/0xjohnnydev")!)
                    CreditsRow(name: "jailbreak.party", role: "PartyUI, GestaltView", profile: URL(string: "https://github.com/jailbreakdotparty")!)
                    CreditsRow(name: "bibilabusensei", role: "Chinese localization & feature optimization / 汉化与功能优化", profile: URL(string: "https://github.com/bibilabusensei")!)
                    CreditsRow(name: "ChatGPT", role: "AI-assisted development & debugging / AI 协助开发与调试", profile: URL(string: "https://github.com/openai")!)
                } header: {
                    Label("Credits", systemImage: "person.3.fill")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                    }
                }
            }
            .alert("Are you sure?", isPresented: $show_confirm) {
                Button("Cancel") {
                    show_confirm = false
                }
                
                Button("Confirm") {
                    state.respring()
                }
            } message: {
                Text("Confirm that you want to respring. This reloads the iOS interface so some MobileGestalt changes can take effect.")
            }
        }
    }
}

struct CreditsRow: View {
    let name: String
    let role: String
    let profile: URL

    private var pfp: URL? {
        URL(string: profile.absoluteString + ".png")
    }

    var body: some View {
        HStack(alignment: .top) {
            AsyncImage(url: pfp) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)

                Text(role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onTapGesture {
            UIApplication.shared.open(profile)
        }
    }
}
