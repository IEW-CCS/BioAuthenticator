//
//  Utility.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/31.
//

import Foundation
import SwiftUI
import UIKit
import LocalAuthentication

extension URLSession {
    func dataTask(with url: URL, result: @escaping (Result<(URLResponse, Data), Error>) -> Void) -> URLSessionDataTask {
        return dataTask(with: url) { (data, response, error) in
            if let error = error {
                result(.failure(error))
                return
            }
            guard let response = response, let data = data else {
                let error = NSError(domain: "error", code: 0, userInfo: nil)
                result(.failure(error))
                return
            }
            result(.success((response, data)))
        }
    }
}

func httpReportUUID(codeContent: QRCodeContent, reportCallback: @escaping (String) -> ()) {
    print("Start to Report Service UUID...")
    var jsonData: Data?
        
    //let url = "http://10.0.1.25:5000/UploadUUID"
    //let url = "http://172.20.10.14:5000/UploadUUID"
    let url = codeContent.strServerURL
    var UrlRequest = URLRequest(url: URL(string: url)!)
    //hard code request body
    do {
        //let httpBody = HttpUUIDReport(server: "CredentialRequest", user_name: "james001", process_step: "CREQ", device_uuid: "a7gf67292-0001-00a2")
        
        //let httpBody2 = HttpUUIDReport2(serverURL: "UUID_Report", clientID: "client_james", processStep: "UUIDREPORT", serviceUUID: "e593247c-bc00-41a3-93d0-3ad4b64b27cb")
        
        var uuidReport: HttpUUIDReport = HttpUUIDReport()
        uuidReport.UserName = codeContent.strUserName
        uuidReport.DeviceUUID = "UUID_abc"
        let jsonReportData = try JSONEncoder().encode(uuidReport)
        let uuidReportString = String(data: jsonReportData, encoding: .utf8)!
        
        var httpBody: HttpTrx = HttpTrx()
        httpBody.username = codeContent.strUserName
        httpBody.devicetype = "MOBILE"
        httpBody.procstep = "UUID_RPT"
        httpBody.datacontent = uuidReportString
        
        jsonData = try JSONEncoder().encode(httpBody)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        
        print("UUID Report JSON string: " + jsonString)

        UrlRequest.httpMethod = "POST"
        UrlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        UrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        UrlRequest.setValue("bearer " + codeContent.strTokenID, forHTTPHeaderField: "Authorization")
        UrlRequest.httpBody = jsonData
    }
    catch {
        print("HttpUUIDReport JSON encode exception: " + error.localizedDescription)
        reportCallback("NG")
        return
    }
    
    let task = URLSession.shared.dataTask(with: UrlRequest) {(data, response, error) in
        do {
            
            if error != nil{
                print("UUID Report Error: \(error?.localizedDescription ?? "Error")")
                reportCallback("NG")
                return
            }
            else {
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        
                    let errorResponse = response as? HTTPURLResponse
                    let message: String = String(errorResponse!.statusCode) + " - " + HTTPURLResponse.localizedString(forStatusCode: errorResponse!.statusCode)
                    print("httpResponse message: " + message)
                    reportCallback("NG")
                    return
                }
                                
                let outputStr  = String(data: data!, encoding: String.Encoding.utf8) as String?
                let replyData = outputStr!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                
                let decoder = JSONDecoder()
                let httpReply = try decoder.decode(HttpTrx.self, from: replyData!)
                print("json decoding seems OK!!")
                print("HttpUUIDReply Result: " + String(httpReply.returncode))
                
                if httpReply.returncode == 0 {
                    let uuidReplyData = httpReply.datacontent!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                    let uuidReplyDecoder = JSONDecoder()
                    let uuidReply = try uuidReplyDecoder.decode(HttpUUIDReply.self, from: uuidReplyData!)
                    print("json decoding seems OK!!")
                    print("uuidReply ServerPublicKey: " + uuidReply.ServerPublicKey)
                    reportCallback("OK")
                }
                else {
                    print("HttpUUIDReply return code non-zero: " + String(httpReply.returncode))
                    reportCallback("NG")
                }
                
                
                
                //if httpReply.replyResult == "OK" {
                //    httpRequestCredential()
                //}
            }
        }
        catch {
            print("Cannot connect to server")
            print(error.localizedDescription)
            reportCallback("NG")
            return
        }
    }
    task.resume()
    
    return
}

func httpRequestCredential(codeContent: QRCodeContent, requestCallback: @escaping (String, HttpCredentialReply) -> ()) {
    print("Start to Request Credential...")
    var jsonData: Data?
    
    
    //let url = "http://10.0.1.25:5000/CredentialRequest"
    //let url = "http://172.20.10.14:5000/CredentialRequest"
    let url = codeContent.strServerURL
    var UrlRequest = URLRequest(url: URL(string: url)!)
    
    //hard code request body
    do {
        //let httpBody = HttpCredentialRequest(server: "CredentialRequest", user_name: "james001", public_key: "1234abcd", process_step: "CREQ")
        
        var credentialRequest: HttpCredentialRequest = HttpCredentialRequest()
        credentialRequest.username = codeContent.strUserName
        let jsonRequestData = try JSONEncoder().encode(credentialRequest)
        let requestString = String(data: jsonRequestData, encoding: .utf8)!
        
        var httpBody: HttpTrx = HttpTrx()
        httpBody.username = codeContent.strUserName
        httpBody.devicetype = "MOBILE"
        httpBody.procstep = "CRED_REQ"
        httpBody.datacontent = requestString
        
        jsonData = try JSONEncoder().encode(httpBody)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        
        print("Credential Request JSON string: " + jsonString)

        UrlRequest.httpMethod = "POST"
        UrlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        UrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        UrlRequest.setValue("bearer " + codeContent.strTokenID, forHTTPHeaderField: "Authorization")
        UrlRequest.httpBody = jsonData
    }
    catch {
        print("HttpCredentialRequest JSON encode exception: " + error.localizedDescription)
        let reply = HttpCredentialReply()
        requestCallback("NG", reply)
        return
    }
    
    let task = URLSession.shared.dataTask(with: UrlRequest) {(data, response, error) in
        do {
            
            if error != nil{
                print("Credential Request Error: \(error?.localizedDescription ?? "Error")")
                let reply = HttpCredentialReply()
                requestCallback("NG", reply)

                return
            }
            else {
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        
                    let errorResponse = response as? HTTPURLResponse
                    let message: String = String(errorResponse!.statusCode) + " - " + HTTPURLResponse.localizedString(forStatusCode: errorResponse!.statusCode)
                    print("httpResponse message: " + message)
                    let reply = HttpCredentialReply()
                    requestCallback("NG", reply)

                    return
                }
                
                let outputStr  = String(data: data!, encoding: String.Encoding.utf8) as String?
                let replyData = outputStr!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                
                let decoder = JSONDecoder()
                let httpReply = try decoder.decode(HttpTrx.self, from: replyData!)
                print("json decoding seems OK!!")
                print("HttpRequestCredential Result: " + String(httpReply.returncode))
                
                if httpReply.returncode == 0 {
                    let credentialReplyData = httpReply.datacontent!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                    let credentialReplyDecoder = JSONDecoder()
                    let credentialReply = try credentialReplyDecoder.decode(HttpCredentialReply.self, from: credentialReplyData!)
                    print("json decoding seems OK!!")
                    print("Credential: " + credentialReply.credential)
                    requestCallback("OK", credentialReply)
                }
                else {
                    print("HttpUUIDReply return code non-zero: " + String(httpReply.returncode))
                    let reply = HttpCredentialReply()
                    requestCallback("NG", reply)
                }
            }
        }
        catch {
            print("Cannot connect to server")
            print(error.localizedDescription)
            let reply = HttpCredentialReply()
            requestCallback("NG", reply)

            return
        }
    }
    task.resume()
    
    return
}

func biometricsVerify(biometricsVerifyResultCallback: @escaping (Bool) -> ()) {
    var error: NSError?
    
    let context = LAContext()
    context.localizedCancelTitle = "Use Password to Verify"
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        let reason = "Use Touch ID/Face ID to Verify"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, error) in
            if success {
                print("Biometrics Verify OK")
                biometricsVerifyResultCallback(true)
            }
            else {
                print("Biometrics Verify NG: " + error!.localizedDescription)
                biometricsVerifyResultCallback(false)
            }
        }
    }
}

// Biometrics & Keychain related declaration and functions
// Stores credentials to keychain for the given server.
func addCredentials(_ credentials: Credentials) throws {
    // Use the username as the account, and get the password as data.
    let account = credentials.username
    let credential_hash = credentials.credential_hash.data(using: String.Encoding.utf8)!

    // Create an access control instance that dictates how the item can be read later.
    let access = SecAccessControlCreateWithFlags(nil, // Use the default allocator.
                                                 kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                 .userPresence,
                                                 nil) // Ignore any error.

    // Allow a device unlock in the last 10 seconds to be used to get at keychain items.
    let context = LAContext()
    context.touchIDAuthenticationAllowableReuseDuration = 10

    // Build the query for use in the add operation.
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrAccount as String: account,
                                kSecAttrServer as String: credentials.server,
                                kSecAttrAccessControl as String: access as Any,
                                kSecUseAuthenticationContext as String: context,
                                kSecValueData as String: credential_hash]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeychainError(status: status) }
}


// Reads the stored credentials from keychain for the given server.
func readCredentials(server: String) throws -> Credentials {
    let context = LAContext()
    context.localizedReason = "Access your password on the keychain"
    let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                kSecAttrServer as String: server,
                                kSecMatchLimit as String: kSecMatchLimitOne,
                                kSecReturnAttributes as String: true,
                                kSecUseAuthenticationContext as String: context,
                                kSecReturnData as String: true]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else { throw KeychainError(status: status) }

    guard let existingItem = item as? [String: Any],
        let credentialData = existingItem[kSecValueData as String] as? Data,
        let credential_hash = String(data: credentialData, encoding: String.Encoding.utf8),
        let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError(status: errSecInternalError)
    }

    return Credentials(server: server, username: account, credential_hash: credential_hash)
}

