//
//  SettingsView.swift
//  BubbleTodo
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(L("settings.language"), selection: $localizationManager.currentLanguage) {
                        Text(L("settings.language.system")).tag("system")
                        Text(L("settings.language.english")).tag("en")
                        Text(L("settings.language.chinese")).tag("zh-Hans")
                    }
                } header: {
                    Text(L("settings.appearance"))
                }

                Section {
                    HStack {
                        Text(L("settings.version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text(L("settings.about"))
                }
            }
            .navigationTitle(L("settings.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
}
