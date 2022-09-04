//
//  BioAuthenticatorApp.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/16.
//

import SwiftUI

@main
struct BioAuthenticatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                //.environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(BLEPeripheralController())
        }
    }
}
