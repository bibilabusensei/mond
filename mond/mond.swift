//
//  mond.swift
//  mond
//
//  Created by ruter on 16.07.26.
//

import SwiftUI
import PartyUI

var pipe = Pipe()
var sema = DispatchSemaphore(value: 0)
var fm = FileManager.default

var path: String {
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("test.txt")

    if !FileManager.default.fileExists(atPath: url.path) {
        FileManager.default.createFile(atPath: url.path, contents: Data())
    }

    return url.path
}

@main
struct mond: App {
    @StateObject private var state = AppState()
    @AppStorage("app_language") private var appLanguageRaw: String = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            "exploit_method": "bad_query",
            "app_language": AppLanguage.system.rawValue
        ])
        if !is_debugged() {
            setvbuf(stdout, nil, _IONBF, 0)
            dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .environment(\.locale, appLanguage.locale)
                .onAppear() {
                    if !is_supported() {
                        Alertinator.shared.alert(
                            title: L("Unsupported system version"),
                            body: L("Mond currently supports iOS 27.0 beta 1 through beta 4. Please confirm your system version before continuing.")
                        )
                    }
                }
                .overlay {
                    if state.show_respring {
                        RespringView()
                            .brightness(-1.0)
                            .ignoresSafeArea()
                            .onAppear {
                                print("(respring) respringing now...")
                            }
                    }
                }
        }
    }
}
