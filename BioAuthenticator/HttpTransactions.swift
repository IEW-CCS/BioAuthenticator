//
//  HttpTransactions.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/31.
//

import Foundation

struct HttpCredentialRequest: Codable {
    var username: String = ""
}

struct HttpCredentialReply: Codable {
    var credential: String = ""
}

struct HttpUUIDReport: Codable {
    var UserName: String = ""
    var DeviceUUID: String = ""
    var MobilePublicKey: String = ""
    //var TimeStamp: Date = Date.now
}

struct HttpUUIDReply: Codable {
    var ServerName: String = ""
    var ServerPublicKey: String = ""
    //var TimeStamp: Date = Date.now
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

struct QRCodeContent: Codable {
    let strServerURL: String
    let strTokenID: String
    let strUserName: String
}

struct HttpTrx: Codable {
    var username: String = ""
    var devicetype: String = ""
    var procstep: String = ""
    var returncode: Int = 0
    var returnmsg: String?
    var datacontent: String?
    var ecs: String?
    var ecssign: String?
}
