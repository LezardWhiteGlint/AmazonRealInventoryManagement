//
//  ViewController.swift
//  AmazonRealInventoryManagement
//
//  Created by Lezardvaleth on 2020/4/6.
//  Copyright © 2020 Lezardvaleth. All rights reserved.
//

import Cocoa
import CoreData

class AmazonRealInventoryManagement: NSViewController {
    var inventory = [Inventory]()
    var context = AppDelegate.viewContext

    @IBOutlet weak var tableView: NSTableView!
    
    @IBAction func load(_ sender: Any) {
        inventory = loadDataFromTxt()
//        print(inventory)
        tableView.reloadData()
    }
    
    @IBAction func setRealInventory(_ sender: NSTextField) {
        let selectedRow = tableView.selectedRow
        inventory[selectedRow].realInventory = Int16(sender.stringValue) ?? 0
        try? context.save()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        inventory = loadDataFromDataBase()
        tableView.reloadData()
        

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension AmazonRealInventoryManagement:NSTableViewDelegate{
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier {
        case NSUserInterfaceItemIdentifier(rawValue: "SKU"):
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SKU"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = inventory[row].sku ?? "notAProduct"
//            print(inventory[row].sku)
            return cell
        case NSUserInterfaceItemIdentifier(rawValue: "AmazonInventory"):
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AmazonInventory"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = String(inventory[row].amazonInventory)
//            print(inventory[row].amazonInventory)
            return cell
        case NSUserInterfaceItemIdentifier(rawValue: "RealInventory"):
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RealInventory"), owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = String(inventory[row].realInventory)
//            print(inventory[row].realInventory)
            return cell
        default:
            return nil
        }
    }
}

extension AmazonRealInventoryManagement:NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return inventory.count
    }
}

private func loadDataFromDataBase() -> [Inventory]{
    var inventory = [Inventory]()
    let request: NSFetchRequest<Inventory> = Inventory.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "sku", ascending: true)]
//    request.predicate = NSPredicate(format: "amount > %@", "0")
    let context = AppDelegate.viewContext
    let result = try? context.fetch(request)
    for inv in (result ?? []){
        inventory.append(inv)
    }
    return inventory
}



private func loadDataFromTxt() -> [Inventory]{
    let inventory = loadDataFromDataBase()
    var alreadyExistInventory = [String]()
    let context = AppDelegate.viewContext
    
    for inv in inventory{
        alreadyExistInventory.append(inv.sku ?? "notAProduct")
    }
    
    let dialog = NSOpenPanel()
//    set properties
    dialog.title = "选择库存TXT文档"
    dialog.showsHiddenFiles = false
    dialog.showsResizeIndicator = true
    dialog.canChooseDirectories = true
    dialog.canChooseFiles = true
    dialog.allowedFileTypes = ["txt"]
    dialog.allowsMultipleSelection = false
    let run = dialog.runModal()
//    if file is opened, get the url of the file
    if run.rawValue == 1{
        let result = dialog.url
//        read the txt file
        do {
            let text = try String(contentsOf: result!, encoding: .utf8)
            let lineByLine = text.split{$0.isNewline}
            for line in lineByLine{
                let data = line.split(separator: "\t")
                if data.count == 4 && !alreadyExistInventory.contains(String(data[0])){
                    print(!alreadyExistInventory.contains(String(data[0])))
                    let newInventory = Inventory(context: context)
                    newInventory.sku = String(data[0])
                    newInventory.amazonInventory = Int16(String(data[3])) ?? 9999  //9999 meaning encouter a bug
                    newInventory.realInventory = 0
                }else{
                    if data.count == 4{
                        // update the inventory according the data
                        // if newData > oldData, update the data
                        // if newData == oldData, do nothing
                        // if newData < oldData, find the difference and realInventory -= difference
                        for inv in inventory{
                            if Int16(String(data[3])) ?? 9999 >= inv.amazonInventory && inv.sku == String(data[0]){
                                inv.amazonInventory = Int16(String(data[3])) ?? 9999
                            }
                            if Int16(String(data[3])) ?? 9999 < inv.amazonInventory && inv.sku == String(data[0]){
                                let soldAmount = (Int16(String(data[3])) ?? 9999) - inv.amazonInventory
                                print("soldAmount is \(soldAmount)")
                                print("data is \(Int16(String(data[3])) ?? 9999)")
                                print("inv.amazonInventory is \(inv.amazonInventory)")
                                print("-----------------------------")
                                inv.realInventory += soldAmount
                                inv.amazonInventory = Int16(String(data[3])) ?? 9999
                            }
                            
                        }
                    }
                }
            }
            try? context.save()
            return inventory
        }
        catch{
            print("file reading error")
        }
//        print(result)
    }
    return inventory
}

