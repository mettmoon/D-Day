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
    private var date:NSDate!
    private var subject:NSString!
    private var memo:NSString!
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
            rows++
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
        dateFormatter2.dateFormat = "yyyy. MM. dd"
        return dateFormatter2
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("TextInputCell", forIndexPath: indexPath) as TextInputCell
            cell.textField.placeholder = "Subject"
            cell.textField.text = subject
            cell.textField.delegate = self
            return cell
        case 1:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("DateValueCell", forIndexPath: indexPath) as KeyValueCell
                cell.keyLabel.text = "D-Day"
                cell.valueLabel.text = dateFormatter.stringFromDate(date)
                return cell
            }else if indexPath.row == 1{
                let cell = tableView.dequeueReusableCellWithIdentifier("DatePickerCell", forIndexPath: indexPath) as DatePickerCell
                cell.datePicker.addTarget(self, action: "datePickerValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
                cell.datePicker.date = date
                return cell
            }else{
                abort()
            }
        case 2:
            if indexPath.row < eventArray.count {
                let cell = tableView.dequeueReusableCellWithIdentifier("KeyValueCell", forIndexPath: indexPath) as KeyValueCell
                let dict = eventArray.objectAtIndex(indexPath.row) as NSDictionary
                cell.keyLabel.text = dict.valueForKey("interval")?.stringValue
                cell.valueLabel.text = dict.valueForKey("message") as String?
                return cell
            }else{
                let cell = tableView.dequeueReusableCellWithIdentifier("ButtonCell", forIndexPath: indexPath) as ButtonCell
                cell.buttonLabel.text = "Add Event.."
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
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(indexPath.section==1 && indexPath.row==1){
            return 163
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
        let addMoreIndexPath = NSIndexPath(forRow: eventArray.count, inSection: 2)
        if addMoreIndexPath.compare(indexPath) == .OrderedSame{
            eventArray .addObject(["interval":NSNumber(int:404),"message":"hi"])
            tableView .insertRowsAtIndexPaths([NSIndexPath(forRow: eventArray.count-1, inSection: 2)], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            if let cell = cell as? TextViewCell {
                cell.textView.becomeFirstResponder()
            }else if let cell = cell as? TextInputCell {
                cell.textField.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - IBAction
    @IBAction func cancelButtonAction(sender: AnyObject) {
        delegate?.addDdayViewControllerDidCancel!(self)
    }
    
    @IBAction func addButtonAction(sender: AnyObject) {
        delegate?.addDdayViewController!(self, didCreateItem: "2")
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        memo = textView.text
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
