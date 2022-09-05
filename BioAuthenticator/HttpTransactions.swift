//
//  HttpTransactions.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/31.
//

import Foundation

struct HttpCredentialRequest: Codable {
    let server: String
    let user_name: String
    let public_key: String
    let process_step: String
}

struct HttpCredentialReply: Codable {
    let process_step: String
    let result: String
    let credential_hash: String
    let server_public_key: String
}

struct HttpUUIDReport: Codable {
    let server: String
    let user_name: String
    let process_step: String
    let device_uuid: String
}

struct HttpUUIDReply: Codable {
    let process_step: String
    let result: String
}

struct HttpUUIDReport2: Codable {
    let serverURL: String
    let clientID: String
    let processStep: String
    let serviceUUID: String
}

struct HttpUUIDReply2: Codable {
    let replyResult: String
}

