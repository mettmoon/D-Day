//
//  DdayViewController.swift
//  D-Day
//
//  Created by Moon Hayden on 2014. 10. 28..
//  Copyright (c) 2014년 Hayden. All rights reserved.
//

import UIKit
import CoreData
@objc protocol DdayViewControllerDelegate: NSObjectProtocol{
    
    optional func ddayViewController(viewController:DdayViewController, didCreateItem:AnyObject)
    optional func ddayViewControllerDidCancel(viewController:DdayViewController)
}

class DdayViewController: UITableViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate{

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    var detailItem:NSManagedObject?
    var delegate: DdayViewControllerDelegate?
    let DDayDateIndexPath:NSIndexPath! = NSIndexPath(forRow: 0, inSection: 1)
    var eventArray:NSMutableArray!
    var managedObjectContext:NSManagedObjectContext?
    var date:NSDate!
    var subject:NSString!
    var memo:NSString!
    var targetEventIndex:Int?
    let AlertViewTagAddEvent = 1

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
        if managedObjectContext != nil {
            
            eventArray = NSMutableArray()
            if let managedObject = detailItem{
                date = managedObject.valueForKey("date") as? NSDate
                let set = managedObject.mutableSetValueForKey("event")
                if set.count > 0{
                    eventArray.addObjectsFromArray(set.allObjects)
                }
                memo = managedObject.valueForKey("memo") as? String
                subject = managedObject.valueForKey("title") as? String
            }else{
                date = NSDate()
                let addBarButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Bordered, target: self, action: "addButtonAction:")
                self.navigationItem.setRightBarButtonItem(addBarButton, animated: false)
                let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelButtonAction:")
                self.navigationItem.setLeftBarButtonItem(cancelButton, animated: false)
                
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if managedObjectContext != nil {
            return 4
        }else{
            return 0
        }
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
            var rows = eventArray.count
            rows++ //add
            if targetEventIndex != nil {
                rows++
            }
            return rows
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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            var indexTarget = indexPath.row
            if targetEventIndex != nil && targetEventIndex < indexPath.row {
                indexTarget--
            }
            if indexTarget < eventArray.count {
                tableView.beginUpdates()
                let object:AnyObject = self.eventArray.objectAtIndex(indexTarget)
                if let managedObject = object as? NSManagedObject {
                    managedObjectContext?.deleteObject(managedObject)
                    self.eventArray.removeObject(managedObject)
                } else if let event = object as? Event {
                    self.eventArray.removeObject(event)
                }
                if targetEventIndex == indexPath.row {
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: targetEventIndex! + 1, inSection: 2)], withRowAnimation: .Fade)
                    targetEventIndex = nil
                }else if targetEventIndex != nil && targetEventIndex > indexPath.row{
                    targetEventIndex!--
                }
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                tableView.endUpdates()
            }

            
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            var indexTarget = indexPath.row
            if targetEventIndex != nil && targetEventIndex < indexPath.row {
                indexTarget--
            }
            if indexTarget < eventArray.count {
                return true
            }
        }
        return false

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
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextInputCell", forIndexPath: indexPath) as TextInputCell
            cell.textField.placeholder = "Subject"
            cell.textField.text = subject
            cell.textField.delegate = self
            cell.textField.returnKeyType = .Done
            if self.detailItem == nil {
                if isFirstViewDidAppear {
                    cell.textField.becomeFirstResponder()
                    isFirstViewDidAppear = false
                }
            } else {
                cell.textField.userInteractionEnabled = false
            }
            return cell
        case 1:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("DateValueCell", forIndexPath: indexPath) as KeyValueCell
                cell.keyLabel.text = "D-Day"
                cell.valueLabel.text = dateFormatter.stringFromDate(date)
                return cell
            }else{
                abort()
            }
        case 2:
            var indexTarget = indexPath.row
            if targetEventIndex != nil && targetEventIndex < indexPath.row {
                indexTarget--
            }
            if targetEventIndex != nil && targetEventIndex!+1 == indexPath.row {
                let cell = tableView.dequeueReusableCellWithIdentifier("PickerViewCell", forIndexPath: indexPath) as PickerViewCell
                cell.pickerView.delegate = self
                cell.pickerView.dataSource = self

                var timeGap:NSTimeInterval = 0
                if let event = eventArray.objectAtIndex(indexTarget) as? Event {
                    timeGap = event.timeGap
                }else if let event = eventArray.objectAtIndex(indexTarget) as? NSManagedObject {
                    timeGap = event.valueForKey("timeGap")!.doubleValue
                }
                cell.pickerView.selectRow(Int(timeGap/60/60/24)-1, inComponent: 0, animated: true)
                return cell
            }
            if indexTarget < eventArray.count {
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyValueCell", forIndexPath: indexPath) as KeyValueCell
                var timeGap:NSTimeInterval = 0
                var titleString:String = ""
                if let event = eventArray.objectAtIndex(indexTarget) as? Event {
                    titleString = event.title
                    timeGap = event.timeGap
                }else if let event = eventArray.objectAtIndex(indexTarget) as? NSManagedObject {
                    titleString = event.valueForKey("title")! as String
                    timeGap = event.valueForKey("timeGap")!.doubleValue
                }
                cell.keyLabel.text = titleString
                cell.valueLabel.text = "\(Int(timeGap/24/60/60))일"
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier("ButtonCell") as ButtonCell
                cell.buttonLabel.text = "Add Event.."
                cell.buttonLabel.textColor = tableView.tintColor
                return cell
            }
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as TextViewCell
            cell.textView.text = memo
            cell.keyLabel.text = "Memo"
            cell.textView.delegate = self
            return cell
        default:
            abort()
        }
        abort()
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let datePickerIndexPath = datePickerIndexPath {
            if(indexPath.compare(datePickerIndexPath) == .OrderedSame){
                return 163
            }
        }

        switch indexPath.section {
        case 0,1:
            return 44
        case 2:
            if targetEventIndex != nil && targetEventIndex! + 1 == indexPath.row {
                return 163
            }else {
                return 44
            }
        case 3:
            return 172
        default:
            return 44
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.endEditing(true)
        if let openDateIndexPath = openDateIndexPath {
            if openDateIndexPath.compare(indexPath) == .OrderedSame {
                hideDatePicker()
                return
            }
        }
        if indexPath.section == 2 {
            
            if targetEventIndex == indexPath.row {
                tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: targetEventIndex! + 1, inSection: 2)], withRowAnimation: UITableViewRowAnimation.Fade)
                targetEventIndex = nil
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                tableView.endUpdates()
                return
            }
            var addIndex = eventArray.count
            if targetEventIndex != nil {
                addIndex++
            }
            if addIndex == indexPath.row{
                let alertView = UIAlertView(title: "입력", message: "이벤트이름을 입력해주세요", delegate: self, cancelButtonTitle: "취소", otherButtonTitles: "추가")
                alertView.tag = AlertViewTagAddEvent
                alertView.alertViewStyle = .PlainTextInput
                alertView.show()
                return
            }
        }
        let ddayIndexPath = NSIndexPath(forRow: 0, inSection: 1)
        if self.detailItem == nil {
            if ddayIndexPath.compare(indexPath) == .OrderedSame {
                openDateIndexPath = indexPath
                tableView.insertRowsAtIndexPaths([datePickerIndexPath!], withRowAnimation: .Fade)
                self.tableView .endEditing(true)
            }
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
    func cancelButtonAction(sender: AnyObject) {
        delegate?.ddayViewControllerDidCancel!(self)
    }
    
    func addButtonAction(sender: AnyObject) {
        self.tableView.endEditing(true)
        if managedObjectContext == nil{
            NSLog("managedObjectText가 없음")
            return
        }
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName("DDay", inManagedObjectContext: managedObjectContext!) as NSManagedObject
        newManagedObject.setValue(date, forKey: "date")
        newManagedObject.setValue(subject, forKey: "title")
        newManagedObject.setValue(memo, forKey: "memo")
        let events = newManagedObject.mutableSetValueForKey("event")
        for event in eventArray {
            if let event = event as? Event {
                let newEventManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Event", inManagedObjectContext: managedObjectContext!) as NSManagedObject
                newEventManagedObject.setValue(event.title, forKey: "title" )
                newEventManagedObject.setValue(event.timeGap, forKey: "timeGap" )
                events.addObject(newEventManagedObject)
            }
        }
        var error: NSError? = nil
        if !managedObjectContext!.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        delegate?.ddayViewController!(self, didCreateItem: newManagedObject)
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        memo = textView.text
    }
    func textViewDidBeginEditing(textView: UITextView) {
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.placeholder == "Subject" {
            self.tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 1))
        }
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidEndEditing(textField: UITextField) {
        self.subject = textField.text
    }
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }
    
    
    // MARK: - UIPickerViewDataSource
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 10000
        }else {
            return 1
        }
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if component == 0 {
            return "\(row+1)"
        }else{
            return "Day"
        }
    }
    
    // MARK: - UIPickerViewDelegate
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let object:AnyObject = self.eventArray.objectAtIndex(targetEventIndex!)
        if let managedObject = object as? NSManagedObject {
            managedObject.setValue((row + 1)*60*60*24, forKey: "timeGap")
        } else if let event = object as? Event {
            event.timeGap = Double((row + 1)*60*60*24)
        }
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: targetEventIndex!, inSection: 2)], withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == AlertViewTagAddEvent {
            if buttonIndex == 1 {
                tableView.beginUpdates()
                if targetEventIndex != nil {
                    tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: targetEventIndex!+1, inSection: 2)], withRowAnimation: .Fade)
                }
                if let item = detailItem {
                    let managedObject = NSEntityDescription.insertNewObjectForEntityForName("Event", inManagedObjectContext: managedObjectContext!) as NSManagedObject
                    managedObject.setValue(alertView.textFieldAtIndex(0)!.text, forKey: "title")
                    managedObject.setValue(1*60*60*24, forKey: "timeGap")
                    eventArray.addObject(managedObject)
                    item.mutableSetValueForKey("event").addObject(managedObject)
                    targetEventIndex = eventArray.indexOfObject(managedObject)
                }else{
                    let event = Event()
                    event.title = alertView.textFieldAtIndex(0)!.text
                    event.timeGap = 1*60*60*24
                    eventArray.addObject(event)
                    targetEventIndex = eventArray.indexOfObject(event)
                }
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: targetEventIndex!, inSection: 2), NSIndexPath(forRow: targetEventIndex!+1, inSection: 2)], withRowAnimation: .Fade)
                tableView.endUpdates()
            }
            var deselectedIndex = eventArray.count
            if targetEventIndex != nil{
                deselectedIndex++
            }
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: deselectedIndex, inSection: 2), animated: true)
        }
    }
    
    class Event:NSObject{
        var timeGap:NSTimeInterval = 0.0
        var title:String = ""
    }
}


