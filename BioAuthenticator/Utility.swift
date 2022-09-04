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

func httpRequestCredential() {
    print("Start to Request Credential...")
    var jsonData: Data?
    
    
    //let url = "http://10.0.1.25:5000/CredentialRequest"
    let url = "http://172.20.10.14:5000/CredentialRequest"
    
    var UrlRequest = URLRequest(url: URL(string: url)!)
    
    //hard code request body
    do {
        let httpBody = HttpCredentialRequest(server: "CredentialRequest", user_name: "james001", public_key: "1234abcd", process_step: "CREQ")
        
        jsonData = try JSONEncoder().encode(httpBody)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        print("Credential Request JSON string: " + jsonString)

        UrlRequest.httpMethod = "POST"
        UrlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        UrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        UrlRequest.httpBody = jsonData
    }
    catch {
        print("HttpCredentialRequest JSON encode exception: " + error.localizedDescription)
        return
    }
    
    let task = URLSession.shared.dataTask(with: UrlRequest) {(data, response, error) in
        do {
            
            if error != nil{
                print("Credential Request Error: \(error?.localizedDescription ?? "Error")")
                
                return
            }
            else {
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        
                    let errorResponse = response as? HTTPURLResponse
                    let message: String = String(errorResponse!.statusCode) + " - " + HTTPURLResponse.localizedString(forStatusCode: errorResponse!.statusCode)
                    print("httpResponse message: " + message)

                    return
                }
                
                let outputStr  = String(data: data!, encoding: String.Encoding.utf8) as String?
                let jsonData = outputStr!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                let decoder = JSONDecoder()
                let httpReply = try decoder.decode(HttpCredentialReply.self, from: jsonData!)
                print("json decoding seems OK!!")
                print("httpReply Credential: " + httpReply.credential_hash)
            }
        }
        catch {
            print("Cannot connect to server")
            print(error.localizedDescription)
            return
        }
    }
    task.resume()
    
    return
}

func httpReportUUID() {
    print("Start to Report Service UUID...")
    var jsonData: Data?
        
    //let url = "http://10.0.1.25:5000/UploadUUID"
    let url = "http://172.20.10.14:5000/UploadUUID"
    var UrlRequest = URLRequest(url: URL(string: url)!)
    //hard code request body
    do {
        //let httpBody = HttpUUIDReport(server: "CredentialRequest", user_name: "james001", process_step: "CREQ", device_uuid: "a7gf67292-0001-00a2")
        
        let httpBody2 = HttpUUIDReport2(serverURL: "UUID_Report", clientID: "client_james", processStep: "UUIDREPORT", serviceUUID: "e593247c-bc00-41a3-93d0-3ad4b64b27cb")
        
        jsonData = try JSONEncoder().encode(httpBody2)
        let jsonString = String(data: jsonData!, encoding: .utf8)!
        print("UUID Report JSON string: " + jsonString)

        UrlRequest.httpMethod = "POST"
        UrlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        UrlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        UrlRequest.httpBody = jsonData
    }
    catch {
        print("HttpUUIDReport JSON encode exception: " + error.localizedDescription)
        return
    }
    
    let task = URLSession.shared.dataTask(with: UrlRequest) {(data, response, error) in
        do {
            
            if error != nil{
                print("UUID Report Error: \(error?.localizedDescription ?? "Error")")
                
                return
            }
            else {
                guard let httpResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpResponse.statusCode) else {
                        
                    let errorResponse = response as? HTTPURLResponse
                    let message: String = String(errorResponse!.statusCode) + " - " + HTTPURLResponse.localizedString(forStatusCode: errorResponse!.statusCode)
                    print("httpResponse message: " + message)

                    return
                }
                
                let outputStr  = String(data: data!, encoding: String.Encoding.utf8) as String?
                let jsonData = outputStr!.data(using: String.Encoding.utf8, allowLossyConversion: true)
                let decoder = JSONDecoder()
                let httpReply = try decoder.decode(HttpUUIDReply2.self, from: jsonData!)
                print("json decoding seems OK!!")
                print("HttpUUIDReply Result: " + httpReply.replyResult)
                
                if httpReply.replyResult == "OK" {
                    httpRequestCredential()
                }
            }
        }
        catch {
            print("Cannot connect to server")
            print(error.localizedDescription)
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
