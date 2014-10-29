//
//  AddDdayViewController.swift
//  D-Day
//
//  Created by Moon Hayden on 2014. 10. 28..
//  Copyright (c) 2014년 Hayden. All rights reserved.
//

import UIKit
import CoreData
@objc protocol AddDdayViewControllerDelegate: NSObjectProtocol{
    
    optional func addDdayViewController(viewController:AddDdayViewController, didCreateItem:AnyObject)
    optional func addDdayViewControllerDidCancel(viewController:AddDdayViewController)
}

class AddDdayViewController: UITableViewController, UITextViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    var delegate: AddDdayViewControllerDelegate?
    let DDayDateIndexPath:NSIndexPath! = NSIndexPath(forRow: 0, inSection: 1)
    var eventArray:NSMutableArray!
    var managedObjectContext:NSManagedObjectContext?
    var date:NSDate!
    var subject:NSString!
    var memo:NSString!
    var openDateIndexPath:NSIndexPath?
    var datePickerIndexPath:NSIndexPath?{
        get {
            if let indexPath = self.openDateIndexPath {
                return NSIndexPath(forRow: indexPath.row+1, inSection: indexPath.section)
            }else{
                return nil
            }
        }
        set {
            if let indexPath = newValue {
                if indexPath.row != 0 {
                    openDateIndexPath = NSIndexPath(forRow: indexPath.row-1, inSection: indexPath.section)
                }
            }
            openDateIndexPath = nil
        }
    
    }
   
    func datePickerValueChanged(datePicker:UIDatePicker){
        date = datePicker.date
        if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? KeyValueCell {
            cell.valueLabel.text = dateFormatter.stringFromDate(date)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        eventArray = NSMutableArray(objects: ["interval":NSNumber(int: 1),"message":"ff"])
        date = NSDate()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            var rows = 1
            if let indexPath = openDateIndexPath {
                if indexPath.section == section {
                    rows++
                }
            }
            return rows
        case 2:
            return eventArray.count+1
        case 3:
            return 1
        default:
            return 0
        }
    }

    var dateFormatter:NSDateFormatter{
        var dateFormatter2 = NSDateFormatter()
        dateFormatter2.dateFormat = "yyyy. MM. dd."
        return dateFormatter2
    }
    var isFirstViewDidAppear:Bool = true
    
    func targetIndexPath (indexPath:NSIndexPath!) -> NSIndexPath!{
        var targetIndexPath = indexPath
        if let openDateIndexPath = openDateIndexPath {
            if indexPath.section == openDateIndexPath.section {
                if indexPath.row > openDateIndexPath.row {
                    return NSIndexPath(forRow: indexPath.row-1, inSection: indexPath.section)
                }
            }
        }
        return indexPath
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let datePickerIndexPath = datePickerIndexPath {
            if(indexPath.compare(datePickerIndexPath) == .OrderedSame){
                let cell = tableView.dequeueReusableCellWithIdentifier("DatePickerCell", forIndexPath: indexPath) as DatePickerCell
                cell.datePicker.addTarget(self, action: "datePickerValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.datePicker.date = date
                cell.datePicker.datePickerMode = .Date
                return cell
            }
        }
        
        let targetIndexPath = self.targetIndexPath(indexPath)
        switch targetIndexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextInputCell", forIndexPath: targetIndexPath) as TextInputCell
            cell.textField.placeholder = "Subject"
            cell.textField.text = subject
            cell.textField.delegate = self
            cell.textField.returnKeyType = .Done
            if(isFirstViewDidAppear){
                cell.textField.becomeFirstResponder()
                isFirstViewDidAppear = false
            }
            return cell
        case 1:
            if targetIndexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("DateValueCell", forIndexPath: targetIndexPath) as KeyValueCell
                cell.keyLabel.text = "D-Day"
                cell.valueLabel.text = dateFormatter.stringFromDate(date)
                return cell
            }else{
                abort()
            }
        case 2:
            if targetIndexPath.row < eventArray.count {
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyValueCell", forIndexPath: targetIndexPath) as KeyValueCell
                let dict = eventArray.objectAtIndex(targetIndexPath.row) as NSDictionary
                cell.keyLabel.text = dict.valueForKey("interval")?.stringValue
                cell.valueLabel.text = dict.valueForKey("message") as String?
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier("ButtonCell", forIndexPath: targetIndexPath) as ButtonCell
                cell.buttonLabel.text = "Add Event.."
                return cell
            }
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: targetIndexPath) as TextViewCell
            cell.textView.text = memo
            cell.keyLabel.text = "Memo"
            cell.textView.delegate = self
            return cell
        default:
            abort()
            
        }
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let datePickerIndexPath = datePickerIndexPath {
            if(indexPath.compare(datePickerIndexPath) == .OrderedSame){
                return 163
            }
        }

        switch indexPath.section {
        case 0,1,2:
            return 44
        case 3:
            return 172
        default:
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let openDateIndexPath = openDateIndexPath {
            if openDateIndexPath.compare(indexPath) == .OrderedSame {
                hideDatePicker()
                return
            }
        }
        let targetIndexPath = self.targetIndexPath(indexPath)
        let addMoreIndexPath = NSIndexPath(forRow: eventArray.count, inSection: 2)
        let ddayIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        if addMoreIndexPath.compare(targetIndexPath) == .OrderedSame{
            eventArray .addObject(["interval":NSNumber(int:404),"message":"hi"])
            tableView .insertRowsAtIndexPaths([NSIndexPath(forRow: eventArray.count-1, inSection: 2)], withRowAnimation: .Fade)
        }else if ddayIndexPath.compare(targetIndexPath) == .OrderedSame {
            openDateIndexPath = indexPath
            tableView.insertRowsAtIndexPaths([datePickerIndexPath!], withRowAnimation: .Fade)
            self.tableView .endEditing(true)
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if let cell = cell as? TextViewCell {
                cell.textView.becomeFirstResponder()
            }else if let cell = cell as? TextInputCell {
                cell.textField.becomeFirstResponder()
            }
        }
    }
    func hideDatePicker(){
        if let indexPath = openDateIndexPath{
            let hideIndexPath = datePickerIndexPath
            self.openDateIndexPath = nil
            tableView.deleteRowsAtIndexPaths([hideIndexPath!], withRowAnimation: .Fade)
        }
    }
    // MARK: - IBAction
    @IBAction func cancelButtonAction(sender: AnyObject) {
        delegate?.addDdayViewControllerDidCancel!(self)
    }
    
    @IBAction func addButtonAction(sender: AnyObject) {
        if managedObjectContext == nil{
            NSLog("managedObjectText가 없음")
            return
        }
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName("DDay", inManagedObjectContext: managedObjectContext!) as NSManagedObject
        newManagedObject.setValue(date, forKey: "date")
        newManagedObject.setValue(subject, forKey: "title")
        newManagedObject.setValue(memo, forKey: "memo")
        var error: NSError? = nil
        if !managedObjectContext!.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        delegate?.addDdayViewController!(self, didCreateItem: newManagedObject)
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        memo = textView.text
    }
    func textViewDidBeginEditing(textView: UITextView) {
        hideDatePicker()
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.placeholder == "Subject" {
            self.tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 1))
        }
        textField.resignFirstResponder()
        return true
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        subject = (textField.text as NSString) .stringByReplacingCharactersInRange(range, withString: string)
        return true
    }
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        hideDatePicker()
        return true
    }
    
}
