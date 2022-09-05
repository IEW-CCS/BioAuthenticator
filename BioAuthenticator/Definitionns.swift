//
//  Definitionns.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/9/5.
//

import Foundation
import LocalAuthentication

struct BioAccountInformation: Codable {
    let bio_switch_flag: String
    let mode: String
    let server_name: String
    let user_name: String
}

struct KeychainError: Error {
    var status: OSStatus

    var localizedDescription: String {
        return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
    }
}

struct Credentials {
    var server: String
    var username: String
    var credential_hash: String
}
