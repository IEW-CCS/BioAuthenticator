//
//  BLEPeripheralController.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/30.
//

import Foundation
import CoreBluetooth
import UIKit
import LocalAuthentication


class BLEPeripheralController: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    @Published var statusMessage = ""
    //@Published var bioSwitchFlag = "OFF"
    //@Published var bioVerifyResult = "NG"
    private var bioSwitchFlag = "OFF"
    private var bioVerifyResult = "NG"
    private var bioCredentialContent = "3gajd783jd9jd378f262"
    
    //GATT UUID Definition
    let DEVICE_NAME = "BioAuth"
    let SERVICE_UUID = "e593247c-bc00-41a3-93d0-3ad4b64b27cb"                           // Service UUID
    let SWITCHFLAG_CHARACTERISTIC_UUID = "97a1c8e5-e399-4124-a363-750d1c7102af"         // Turn ON/OFF Biometrics Process UUID
    let VERIFYRESULT_CHARACTERISTIC_UUID = "4e4a3a1b-fd4a-40a5-a08f-586078499da9"       // Notify for Biometrics Verify Result UUID
    let CREDENTIALCONTENT_CHARACTERISTIC_UUID = "92f59a03-0e61-41eb-b758-64460c72706a"  // Credential Content Data UUID


    var peripheralManager : CBPeripheralManager?
    var charDictionary = [String: CBMutableCharacteristic]()

    func start() {
        statusMessage = "Start Peripheral Manager"
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
            statusMessage = "peripheralManager didAdd sendData Exception: " + error.localizedDescription
        }

        do {
            let data = self.bioVerifyResult.data(using: .utf8)
            try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
        }
        catch {
            print(error)
            statusMessage = "peripheralManager didAdd sendData Exception: " + error.localizedDescription
        }
        
        do {
            let data = self.bioCredentialContent.data(using: .utf8)
            try setData(data!, uuidString: CREDENTIALCONTENT_CHARACTERISTIC_UUID)
        }
        catch {
            print(error)
            statusMessage = "peripheralManager didAdd sendData Exception: " + error.localizedDescription
        }

        peripheral.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service.uuid],
             CBAdvertisementDataLocalNameKey: DEVICE_NAME]
        )
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Start Advertising...")
        statusMessage = "Start Advertising..."
        httpReportUUID()
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
        statusMessage = "Set Data to Characteristic: " + dataString
        
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
            let string = String(data: data, encoding: .utf8)!
            self.bioSwitchFlag = string
            print("BioSwitchFlag Characteristic Received Switch Flag data: " + string)
            statusMessage = "BioSwitchFlag Characteristic Received Switch Flag data: " + string

            do {
                let writeData = string.data(using: .utf8)!
                try setData(writeData, uuidString: SWITCHFLAG_CHARACTERISTIC_UUID)
            }
            catch {
                print(error)
                statusMessage = "peripheralManager didReceiveWrite setData Exception: " + error.localizedDescription
            }

            if string == "ON" {
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
                statusMessage = "biometricsVerifyResultCallback Verify OK"
            }
            catch {
                print(error)
                statusMessage = "biometricsVerifyResultCallback setData Exception: " + error.localizedDescription
            }

        }
        else {
            print("biometricsVerifyResultCallback Verify NG")
            do {
                let data = "NG".data(using: .utf8)
                try setData(data!, uuidString: VERIFYRESULT_CHARACTERISTIC_UUID)
                self.bioVerifyResult = "NG"
                statusMessage = "biometricsVerifyResultCallback Verify NG"
            }
            catch {
                print(error)
                statusMessage = "biometricsVerifyResultCallback setData Exception: " + error.localizedDescription
            }
        }
    }

}
