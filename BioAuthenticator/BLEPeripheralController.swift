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
    public var startMode = CONNECT_MODE_REGISTER
    
    //GATT UUID Definition
    let DEVICE_NAME = "BioAuth2"
    //let SERVICE_UUID = "e593247c-bc00-41a3-93d0-3ad4b64b27cb"                           // Service UUID
    //let SWITCHFLAG_CHARACTERISTIC_UUID = "97a1c8e5-e399-4124-a363-750d1c7102af"         // Turn ON/OFF Biometrics Process UUID
    //let VERIFYRESULT_CHARACTERISTIC_UUID = "4e4a3a1b-fd4a-40a5-a08f-586078499da9"       // Notify for Biometrics Verify Result UUID
    //let CREDENTIALCONTENT_CHARACTERISTIC_UUID = "92f59a03-0e61-41eb-b758-64460c72706a"  // Credential Content Data UUID


    let SERVICE_UUID = "49a92bf1-b243-4b92-9537-815476f2d06b"                           // Service UUID
    let SWITCHFLAG_CHARACTERISTIC_UUID = "d24385a6-60e8-4976-bb20-c89567a79527"         // Turn ON/OFF Biometrics Process UUID
    let VERIFYRESULT_CHARACTERISTIC_UUID = "ab3d255f-fd36-42d8-a575-8cc27b651bec"       // Notify for Biometrics Verify Result UUID
    let CREDENTIALCONTENT_CHARACTERISTIC_UUID = "59f87364-6a96-4c25-8e3b-7424d7a56bc8"  // Credential Content Data UUID

    var peripheralManager : CBPeripheralManager?
    var charDictionary = [String: CBMutableCharacteristic]()
    var codeContent: QRCodeContent?

    func start_register(qrCode: String) {
        statusMessage = "Start Peripheral Manager"
        print("start_register: Start Peripheral Manager")
        
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
    
    func start_auth() {
        statusMessage = "Start Peripheral Manager"
        print("start_auth: Start Peripheral Manager")
        
        /*
        let decoder = JSONDecoder()
        let jsonData = qrCode.data(using: String.Encoding.utf8, allowLossyConversion: true)
        do {
            self.codeContent = try decoder.decode(QRCodeContent.self, from: jsonData!)
            
        }
        catch {
            print("QRCodeContent Decode Exception: " + error.localizedDescription)
            
            return
        }
        */
        
        peripheralManager = .init(delegate: self, queue: .main)
    }
    
    func start_test() {
        statusMessage = "Start Peripheral Manager"
        print("start_test: Start Peripheral Manager")
        
        if peripheralManager == nil {
            print("start_test: peripheralManager is nil")
            peripheralManager = .init(delegate: self, queue: .main)
        }
        else {
            print("start_test: peripheralManager is non-nil")
        }
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
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("peripheralManagerDidUpdateState: " + String(peripheral.state.rawValue))
        guard peripheral.state == .poweredOn else {
            print(peripheral.state.rawValue)
            statusMessage = "Peripheral State Raw Value: " + String(peripheral.state.rawValue)
            return
        }
        
        peripheralManager?.removeAllServices()

        var service: CBMutableService
        var characteristic: CBMutableCharacteristic
        var charArray = [CBCharacteristic]()
        
        // Start to setup service and characteristic
        service = CBMutableService(type: CBUUID(string: SERVICE_UUID), primary: true)

        // Register Biometrics Switch Flag characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: SWITCHFLAG_CHARACTERISTIC_UUID),
            properties: [.read, .write],
            value: nil,
            permissions: [.writeable, .readable]
            //permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        
        charDictionary[SWITCHFLAG_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        // Register Biometrics Verify Result characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: VERIFYRESULT_CHARACTERISTIC_UUID),
            //properties: [.read, .write, .notify, .indicate],
            properties: [.read, .write, .indicate],
            value: nil,
            permissions: [.writeable, .readable]
            //permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        charDictionary[VERIFYRESULT_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        // Register Credential Content characteristic
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: CREDENTIALCONTENT_CHARACTERISTIC_UUID),
            properties: [.read, .write, .indicate],
            value: nil,
            permissions: [.writeable, .readable]
            //permissions: [.writeEncryptionRequired, .readEncryptionRequired]
        )
        charDictionary[CREDENTIALCONTENT_CHARACTERISTIC_UUID] = characteristic
        charArray.append(characteristic)

        print("Create Service & Characteristics")
        statusMessage = "Create Service & Characteristics"
        service.characteristics = charArray
        
        //peripheralManager?.remove(service)
        peripheralManager?.add(service)
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            //print("ERROR:{\(#file, #function)}\n")
            print(error!.localizedDescription)
            statusMessage = error!.localizedDescription
            return
        }
        
        //print("peripheralManager remove service first")
        //peripheralManager?.remove(service as! CBMutableService)
        
        print("peripheralManager start to add service")
        
        
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
        if startMode == CONNECT_MODE_REGISTER {
            print("Register Mode to send httpReportUUID transaction")
            statusMessage = "Register Mode to send httpReportUUID transaction"
            httpReportUUID(codeContent: self.codeContent!, reportCallback: httpReportUUIDCallback)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("PeripheralManager didSubscribeTo: " + characteristic.uuid.uuidString)
        
        /*
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
            print("Stop Advertising")
            statusMessage = "Stop Advertising"
        }*/
        
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
        
        //print("Write Request Characteristic: " + at.characteristic.uuid.uuidString)
        
        if at.characteristic.uuid.uuidString.lowercased() == SWITCHFLAG_CHARACTERISTIC_UUID {
            print("Write Request from SWITCHFLAG_CHARACTERISTIC Characteristic")
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
                    statusMessage = "peripheralManager didReceiveWrite for BioSwitchFlag Characteristic setData Exception: " + error.localizedDescription
                    return
                }

                biometricsVerify(biometricsVerifyResultCallback: biometricsVerifyResultCallback)
            }

            peripheral.respond(to: at, withResult: .success)

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

        }

        if at.characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            print("Write Request from VERIFYRESULT_CHARACTERISTIC Characteristic")
            let string = String(data: data, encoding: .utf8)!
            self.bioVerifyResult = string
            print("BioVerifyResult Characteristic Received Verify Result: " + string)
            statusMessage = "BioVerifyResult Characteristic Received Verify Result: " + string
            
            do {
                let writeData = string.data(using: .utf8)!
                try setData(writeData, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                statusMessage = "peripheralManager didReceiveWrite for BioVerifyResult CharacteristicsetData Exception: " + error.localizedDescription
            }

            peripheral.respond(to: at, withResult: .success)
        }
        
        if at.characteristic.uuid.uuidString.lowercased() == CREDENTIALCONTENT_CHARACTERISTIC_UUID {
            print("Write Request from CREDENTIALCONTENT_CHARACTERISTIC Characteristic")
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
                statusMessage = "peripheralManager didReceiveWrite for BioCredentialContent CharacteristicsetData setData Exception: " + error.localizedDescription
            }

            peripheral.respond(to: at, withResult: .success)
        }
 
    }
    
    // Central read data from Peripheral
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        request.value = nil
        print("Receive Read Request")
        statusMessage = "Receive Read Request"
        
        print("Read Request Characteristic: " + request.characteristic.uuid.uuidString)
        
        if request.characteristic.uuid.uuidString.lowercased() == SWITCHFLAG_CHARACTERISTIC_UUID {
            print("Read Request from SWITCHFLAG_CHARACTERISTIC Characteristic")
            print("Read SwitchFlag Value: " + self.bioSwitchFlag)
            statusMessage = "Read SwitchFlag Value"
            let data = self.bioSwitchFlag.data(using: .utf8)
            request.value = data
        }

        if request.characteristic.uuid.uuidString.lowercased() == VERIFYRESULT_CHARACTERISTIC_UUID {
            print("Read Request from VERIFYRESULT_CHARACTERISTIC Characteristic")
            print("Read VerifyResult Value: " + self.bioVerifyResult)
            statusMessage = "Read VerifyResult Value"
            let data = self.bioVerifyResult.data(using: .utf8)
            request.value = data
        }

        if request.characteristic.uuid.uuidString.lowercased() == CREDENTIALCONTENT_CHARACTERISTIC_UUID {
            print("Read Request from CREDENTIALCONTENT_CHARACTERISTIC Characteristic")
            print("Read CredentialContent Value: " + self.bioCredentialContent)
            statusMessage = "Read CredentialContent Value"
            let data = self.bioCredentialContent.data(using: .utf8)
            request.value = data
        }

        peripheral.respond(to: request, withResult: .success)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if ((error) != nil) {
            print("Error changing notification state: " + error!.localizedDescription)
        }
        if characteristic.isNotifying {
            print("Notification Updated")
        }
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
                    print("biometricsVerifyResultCallback Verify OK")
                    self.statusMessage = "biometricsVerifyResultCallback Verify OK"
                }
                
                /*
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
                }*/

            }
            catch {
                print("biometricsVerifyResultCallback setData Exception: " + error.localizedDescription)
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
                    print("biometricsVerifyResultCallback Verify NG")
                    self.statusMessage = "biometricsVerifyResultCallback Verify NG"
                }
            }
            catch {
                print("biometricsVerifyResultCallback setData Exception: " + error.localizedDescription)
                DispatchQueue.main.async {
                    self.statusMessage = "biometricsVerifyResultCallback setData Exception: " + error.localizedDescription
                }
             }
        }
    }
    
    func httpReportUUIDCallback(result: String) {
        print("BLEPeripheralController Receive httpReportUUIDCallback")
        if result == "OK" {
            print("httpReportUUIDCallback receive result: OK")
            httpRequestCredential(codeContent: self.codeContent!, requestCallback: httpCredentialRequestCallback)
        }
    }

    func httpCredentialRequestCallback(result: String, reply: HttpCredentialReply) {
        print("BLEPeripheralController Receive httpCredentialRequestCallback")
        
        if result == "OK" {
            print("httpCredentialRequestCallback receive result: OK")
            // Start to write Credential Content into CREDENTIALCONTENT_CHARACTERISTIC
            self.bioCredentialContent = reply.CredentialSign
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                do {
                    let data = self.bioCredentialContent.data(using: .utf8)
                    try self.setData(data!, uuidString: self.CREDENTIALCONTENT_CHARACTERISTIC_UUID)
                    
                }
                catch {
                    print("peripheralManager httpCredentialRequestCallback setData Exception: " + error.localizedDescription)
                    DispatchQueue.main.async {
                        self.statusMessage = "peripheralManager httpCredentialRequestCallback setData Exception: " + error.localizedDescription
                    }
                }
            }
        }
    }

}
