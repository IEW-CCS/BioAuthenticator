//
//  ContentView.swift
//  BioAuthenticator
//
//  Created by Lo Fang Chou on 2022/8/16.
//

import SwiftUI
import CoreData

struct ContentView: View {
    //Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var blePeripheralController: BLEPeripheralController
    @State private var isPresentingScanner = false
    @State private var scannedCode: String?
    @State private var registerState = true
    
    //@FetchRequest(
    //    sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
    //    animation: .default)
    //private var items: FetchedResults<Item>

    var body: some View {
        GeometryReader { proxy in
            VStack {

                Toggle(isOn: $registerState) {
                    Text(registerState ? "Register Phase" : "Authentication Phase")
                }
                .padding()
                
                if registerState {
                    Button(action: { isPresentingScanner = true }) {
                        Text("Scan to Register")
                            .frame(width: proxy.size.width / 1.1,
                                   height: 50,
                                   alignment: .center)
                            .foregroundColor(Color.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2))
                    }
                        .padding()
                    
                    Text("\(scannedCode ?? "")")
                        .padding()
                }
                else {
                    Button(action: {
                        //blePeripheralController.startMode = CONNECT_MODE_AUTHENTICATION
                        //blePeripheralController.start_auth()
                        blePeripheralController.startMode = CONNECT_MODE_TEST
                        blePeripheralController.start_test()

                    }) {
                        Image(systemName: "faceid")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(width: proxy.size.width / 4,
                           height: proxy.size.width / 4,
                           alignment: .center)
                        .padding()
                }
                
                Spacer()
                
                Text("\(blePeripheralController.statusMessage)")
                    .padding()
            }
            .sheet(isPresented: $isPresentingScanner) {
                CodeScannerView(codeTypes: [.qr], showViewfinder: true) { response in
                    if case let .success(result) = response {
                        scannedCode = result.string
                        isPresentingScanner = false
                        blePeripheralController.startMode = CONNECT_MODE_REGISTER
                        blePeripheralController.start_register(qrCode: scannedCode!)
                    }
                }
            }
            
            Spacer()
        }
        

        /*
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                    } label: {
                        Text(item.timestamp!, formatter: itemFormatter)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
        */
    }

    
    /*
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    */
}

/*
private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
*/

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
       
    }
}
