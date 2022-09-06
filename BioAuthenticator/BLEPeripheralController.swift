//
//  BLEPeripheralController.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/30.
//

import Foundation
import CoreBluetooth
import SwiftUI
import UIKit
import LocalAuthentication


class BLEPeripheralController: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    @Published var statusMessage = ""
    //@Published var bioSwitchFlag = "OFF"
    //@Published var bioVerifyResult = "NG"
    private var bioSwitchFlag = "OFF"
    private var bioVerifyResult = "NG"
    private var bioCredentialContent = ""
    private var accountInfo = BioAccountInformation(bio_switch_flag: "OFF", mode: "", server_name: "", user_name: "")
    
    //GATT UUID Definition
    let DEVICE_NAME = "BioAuth"
    let SERVICE_UUID = "e593247c-bc00-41a3-93d0-3ad4b64b27cb"                           // Service UUID
    let SWITCHFLAG_CHARACTERISTIC_UUID = "97a1c8e5-e399-4124-a363-750d1c7102af"         // Turn ON/OFF Biometrics Process UUID
    let VERIFYRESULT_CHARACTERISTIC_UUID = "4e4a3a1b-fd4a-40a5-a08f-586078499da9"       // Notify for Biometrics Verify Result UUID
    let CREDENTIALCONTENT_CHARACTERISTIC_UUID = "92f59a03-0e61-41eb-b758-64460c72706a"  // Credential Content Data UUID

    var peripheralManager : CBPeripheralManager?
    var charDictionary = [String: CBMutableCharacteristic]()
    var codeContent: QRCodeContent?

    func start(qrCode: String) {
        statusMessage = "Start Peripheral Manager"
        
        let decoder = JSONDecoder()
        let jsonData = qrCode.data(using: String.Encoding.utf8, allowLossyConversion: true)
        do {
            self.codeContent = try decoder.decode(QRCodeContent.self, from: jsonData!)
            
        }
        catch {
            print("QRCodeContent Decode Exception: " + error.localizedDescription)
            
            return
        }
        
        peripheralManager = .init(delegate: self, queue: .main)
        //peripheralManager?.delegate = self
    }
    
    func writeVerifyResult(result: String) {
        do {
            let data = result.data(using: .utf8)
            try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
            self.bioVerifyResult = result
        }
        catch {
            print(error)
            statusMessage = "setData Exception: " + error.localizedDescription
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState")
        guard peripheral.state == .poweredOn else {
            print(peripheral.state.rawValue)
            statusMessage = "Peripheral State Raw Value: " + String(peripheral.state.rawValue)
            return
        }
        
        var service: CBMutableService
        var characteristic: CBMutableCharacteristic
        var charArray = [CBCharacteristic]()
        
        // Start to setup service and characteristic
        service = CBMutableService(type: CBUUID(string: SERVICE_UUID), primary: true)

        // Register Biometrics Switch Flag characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: SWITCHFLAG_CHARACTERISTIC_UUID),
            properties: [.read, .write, .notify],
            value: nil,
            //permissions: [.writeable, .readable]
            permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        
        charDictionary[SWITCHFLAG_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        // Register Biometrics Verify Result characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: VERIFYRESULT_CHARACTERISTIC_UUID),
            properties: [.read, .write, .notify, .indicate],
            value: nil,
            //permissions: [.writeable, .readable]
            permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        charDictionary[VERIFYRESULT_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        // Register Credential Content characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: CREDENTIALCONTENT_CHARACTERISTIC_UUID),
            properties: [.read, .write],
            value: nil,
            //permissions: [.writeable, .readable]
            permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        charDictionary[CREDENTIALCONTENT_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        statusMessage = "Create Service & Characteristics"
        service.characteristics = charArray
        peripheralManager?.add(service)
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("peripheralManager didAdd service")
        guard error == nil else {
            //print("ERROR:{\(#file, #function)}\n")
            print(error!.localizedDescription)
            statusMessage = error!.localizedDescription
            return
        }
        
        do {
            let data = self.bioSwitchFlag.data(using: .utf8)
            try setData(data!, uuidString: SWITCHFLAG_CHARACTERISTIC_UUID)
        }
        catch {
            print(error)
            statusMessage = "peripheralManager didAdd SWITCHFLAG_CHARACTERISTIC setData Exception: " + error.localizedDescription
        }

        do {
            let data = self.bioVerifyResult.data(using: .utf8)
            try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
        }
        catch {
            print(error)
            statusMessage = "peripheralManager didAdd VERIFYRESULT_CHARACTERISTIC setData Exception: " + error.localizedDescription
        }
        
        do {
            let data = self.bioCredentialContent.data(using: .utf8)
            try setData(data!, uuidString: CREDENTIALCONTENT_CHARACTERISTIC_UUID)
        }
        catch {
            print(error)
            statusMessage = "peripheralManager didAdd CREDENTIALCONTENT_CHARACTERISTIC setData Exception: " + error.localizedDescription
        }

        peripheral.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service.uuid],
             CBAdvertisementDataLocalNameKey: DEVICE_NAME]
        )
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Start Advertising...")
        statusMessage = "Start Advertising..."
        httpReportUUID(codeContent: self.codeContent!, reportCallback: httpReportUUIDCallback)
    }
    
    // Set data to Characteristic
    func setData(_ data: Data, uuidString: String) throws {
        guard let characteristic = charDictionary[uuidString] else {
            // No such the uuid
            print("Characteristic Not Found")
            
            statusMessage = "Characteristic Not Found"
            return
        }
        
        let dataString = String(data: data, encoding: String.Encoding.utf8)!
        //self.textView.string = self.textView.string + dataString! + "\n"
        print("Set Data to Characteristic: " + dataString)
        DispatchQueue.main.async {
            self.statusMessage = "Set Data to Characteristic: " + dataString
        }
        
        peripheralManager?.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil
        )
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("PeripheralManager didScribeTo: " + characteristic.uuid.uuidString)
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
            print("Stop Advertising")
            statusMessage = "Stop Advertising"
        }
        
        if characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            print("Central Subscribes to BioVerifyResult Characteristic")
            statusMessage = "Central Subscribes to BioVerifyResult Characteristic"
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("PeripheralManager didUnscribeFrom: " + characteristic.uuid.uuidString)
        
        if characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            print("Central UnSubscribes to BioVerifyResult Characteristic")
            statusMessage = "Central UnSubscribes to BioVerifyResult Characteristic"
        }
    }

    // Central write data to Peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Receive Write Request")
        statusMessage = "Receive Write Request"
        guard let at = requests.first else {
            print("Write Request is null")
            statusMessage = "Write Request is null"
            return
        }
        
        guard let data = at.value else {
            print("Write Request value is null")
            statusMessage = "Write Request value is null"
            return
        }
        
        print("Write Request Characteristic: " + at.characteristic.uuid.uuidString)
        
        if at.characteristic.uuid.uuidString.lowercased() == SWITCHFLAG_CHARACTERISTIC_UUID {
            /*
            do {
                let decoder = JSONDecoder()
                self.accountInfo = try decoder.decode(BioAccountInformation.self, from: data)
            }
            catch {
                print("BioAccountInformation json decode exception: " + error.localizedDescription)
                return
            }
            
            let switch_flag = self.accountInfo.bio_switch_flag
            self.bioSwitchFlag = switch_flag
            print("BioSwitchFlag Characteristic Received Switch Flag data: " + switch_flag)
            statusMessage = "BioSwitchFlag Characteristic Received Switch Flag data: " + switch_flag

            do {
                let writeData = switch_flag.data(using: .utf8)!
                try setData(writeData, uuidString: SWITCHFLAG_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                statusMessage = "peripheralManager didReceiveWrite setData Exception: " + error.localizedDescription
            }

            if switch_flag == "ON" {
                if self.accountInfo.mode == "Register" {
                    biometricsVerify(biometricsVerifyResultCallback: biometricsVerifyResultCallback)
                }
                else if self.accountInfo.mode == "Connect" {
                    do {
                        let credentials = try readCredentials(server: self.accountInfo.server_name)
                        print("Read Credential from Keychain Successful: " + credentials.credential_hash)
                        DispatchQueue.main.async {
                            self.statusMessage = "Read Credential from Keychain Successful: " + credentials.credential_hash
                        }
                        
                        self.bioCredentialContent = credentials.credential_hash
                        do {
                            let data = self.bioCredentialContent.data(using: .utf8)
                            try setData(data!, uuidString: CREDENTIALCONTENT_CHARACTERISTIC_UUID)
                        }
                        catch {
                            print(error)
                            DispatchQueue.main.async {
                                self.statusMessage = "peripheralManager httpCredentialRequestCallback setData Exception: " + error.localizedDescription
                            }
                        }

                    } catch {
                        if let error = error as? KeychainError {
                            print("Read Credential from Keychain Error: " + error.localizedDescription)
                            DispatchQueue.main.async {
                                self.statusMessage = "Read Credential from Keychain Error: " + error.localizedDescription
                            }
                        }
                    }
                }
                else {
                    print("BioSwitch Mode Error: " + self.accountInfo.mode)
                    DispatchQueue.main.async {
                        self.statusMessage = "BioSwitch Mode Error: " + self.accountInfo.mode
                    }
                }
            }

            peripheral.respond(to: at, withResult: .success)
            */

            let string = String(data: data, encoding: .utf8)!
            self.bioSwitchFlag = string
            print("BioSwitchFlag Characteristic Received Switch Flag data: " + string)
            statusMessage = "BioSwitchFlag Characteristic Received Switch Flag data: " + string
            if string == "ON" {
                do {
                    let writeData = string.data(using: .utf8)!
                    try setData(writeData, uuidString: SWITCHFLAG_CHARACTERISTIC_UUID)
                }
                catch {
                    print(error)
                    statusMessage = "peripheralManager didReceiveWrite setData Exception: " + error.localizedDescription
                    return
                }

                biometricsVerify(biometricsVerifyResultCallback: biometricsVerifyResultCallback)
            }

            peripheral.respond(to: at, withResult: .success)
        }

        if at.characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            let string = String(data: data, encoding: .utf8)!
            self.bioVerifyResult = string
            print("BioVerifyResult Characteristic Received Switch Flag data: " + string)
            statusMessage = "BioVerifyResult Characteristic Received Switch Flag data: " + string
            
            do {
                let writeData = string.data(using: .utf8)!
                try setData(writeData, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                statusMessage = "peripheralManager didReceiveWrite setData Exception: " + error.localizedDescription
            }

            peripheral.respond(to: at, withResult: .success)
        }
        
        if at.characteristic.uuid.uuidString.lowercased() == CREDENTIALCONTENT_CHARACTERISTIC_UUID {
            let string = String(data: data, encoding: .utf8)!
            self.bioCredentialContent = string
            print("BioCredentialContent Characteristic Received data: " + string)
            statusMessage = "BioCredentialContent Characteristic Received data: " + string

            do {
                let writeData = string.data(using: .utf8)!
                try setData(writeData, uuidString: CREDENTIALCONTENT_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                statusMessage = "peripheralManager didReceiveWrite setData Exception: " + error.localizedDescription
            }

            peripheral.respond(to: at, withResult: .success)
        }
 
    }
    
    // Central read data from Peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = nil
        print("Receive Read Request")
        statusMessage = "Receive Read Request"
        
        print("Write Request Characteristic: " + request.characteristic.uuid.uuidString)
        
        if request.characteristic.uuid.uuidString.lowercased() == SWITCHFLAG_CHARACTERISTIC_UUID {
            print("Read SwitchFlag Value")
            statusMessage = "Read SwitchFlag Value"
            let data = self.bioSwitchFlag.data(using: .utf8)
            request.value = data
        }

        if request.characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            print("Read VerifyResult Value")
            statusMessage = "Read VerifyResult Value"
            let data = self.bioVerifyResult.data(using: .utf8)
            request.value = data
        }

        if request.characteristic.uuid.uuidString.lowercased() == CREDENTIALCONTENT_CHARACTERISTIC_UUID {
            print("Read CredentialContent Value")
            statusMessage = "Read CredentialContent Value"
            let data = self.bioCredentialContent.data(using: .utf8)
            request.value = data
        }

        peripheral.respond(to: request, withResult: .success)
    }

    /*
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveNotify request: CBATTRequest) {
        if request.characteristic.uuid.uuidString.lowercased() == SWITCHFLAG_CHARACTERISTIC_UUID {
            print("Receive BioSwitchFlag Notification!")
            guard let data = request.value else {
                print("Notification Request value is null")
                statusMessage = "Notification Request value is null"
                return
            }
            
            let string = String(data: data, encoding: .utf8)!
            print("Received Switch Flag data is: " + string)
            statusMessage = "Received Switch Flag data is: " + string
            
            if string == "ON" {
                biometricsVerify(biometricsVerifyResultCallback: biometricsVerifyResultCallback)
            }
        }
    }
    */
    
    func biometricsVerifyResultCallback(result: Bool) {
        print("Enter biometricsVerifyResultCallback")
        if result {
            print("biometricsVerifyResultCallback Verify OK")
            do {
                let data = "OK".data(using: .utf8)
                try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
                self.bioVerifyResult = "OK"
                DispatchQueue.main.async {
                    self.statusMessage = "biometricsVerifyResultCallback Verify OK"
                }
                
                // After Biometrics Verify OK, write credential content to Keychain
                let credentials = Credentials(server: self.accountInfo.server_name, username: self.accountInfo.user_name, credential_hash: self.bioCredentialContent)

                do {
                    try addCredentials(credentials)
                    print("Added Credential to Keychain Successful")
                    DispatchQueue.main.async {
                        self.statusMessage = "Added Credential to Keychain Successful"
                    }
                    
                } catch {
                    if let error = error as? KeychainError {
                        print("Add Credential to Keychain Error: " + error.localizedDescription)
                        DispatchQueue.main.async {
                            self.statusMessage = "Add Credential to Keychain Error: " + error.localizedDescription
                        }
                    }
                }

            }
            catch {
                print(error)
                DispatchQueue.main.async {
                    self.statusMessage = "biometricsVerifyResultCallback setData Exception: " + error.localizedDescription
                }
            }

        }
        else {
            print("biometricsVerifyResultCallback Verify NG")
            do {
                let data = "NG".data(using: .utf8)
                try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
                self.bioVerifyResult = "NG"
                DispatchQueue.main.async {
                    self.statusMessage = "biometricsVerifyResultCallback Verify NG"
                }
            }
            catch {
                print(error)
                DispatchQueue.main.async {
                    self.statusMessage = "biometricsVerifyResultCallback setData Exception: " + error.localizedDescription
                }
                
            }
        }
    }
    
    func httpReportUUIDCallback(result: String) {
        print("BLEPeripheralController Receive httpReportUUIDCallback")
        if result == "OK" {
            httpRequestCredential(codeContent: self.codeContent!, requestCallback: httpCredentialRequestCallback)
        }
    }

    func httpCredentialRequestCallback(result: String, reply: HttpCredentialReply) {
        print("BLEPeripheralController Receive httpCredentialRequestCallback")
        if result == "OK" {
            // Start to write Credential Content into CREDENTIALCONTENT_CHARACTERISTIC
            self.bioCredentialContent = reply.credential
            do {
                let data = self.bioCredentialContent.data(using: .utf8)
                try setData(data!, uuidString: CREDENTIALCONTENT_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                DispatchQueue.main.async {
                    self.statusMessage = "peripheralManager httpCredentialRequestCallback setData Exception: " + error.localizedDescription
                }
                
            }
        }
    }

}
