//
//  MasterViewController.swift
//  D-Day
//
//  Created by Moon Hayden on 2014. 10. 28..
//  Copyright (c) 2014년 Hayden. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, DdayViewControllerDelegate {

    var detailViewController: DdayViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    func stringFromDate(date:NSDate) -> String{
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy. MM. dd."
        return dateFormatter.stringFromDate(date)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DdayViewController
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "reloadFetchedResults:",
            name: "SomethingChanged",
            object: UIApplication.sharedApplication().delegate
        )
    }
    func reloadFetchedResults(note:NSNotification) {
    NSLog("Underlying data changed ... refreshing!")
        self.performFetch()
    }

    func performFetch() {
        var error:NSError? = nil
        self.fetchedResultsController.performFetch(&error)
        if let error = error {
            NSLog("[%@ %@] %@ (%@)", NSStringFromClass(self.classForCoder), __FUNCTION__, error.localizedDescription, error.localizedFailureReason!)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        performSegueWithIdentifier("addNewItem", sender: nil)
        return
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DdayViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.managedObjectContext = managedObjectContext
            }
        }else if segue.identifier == "addNewItem"{
            let viewController = (segue.destinationViewController as UINavigationController).topViewController as DdayViewController
            viewController.delegate = self
            viewController.managedObjectContext = managedObjectContext
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DDayCell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject)
                
            var error: NSError? = nil
            if !context.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 89
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
        if let cell = cell as? DDayCell {
            cell.titleLabel.text = object.valueForKey("title")? as? String
            let currnetCalendar = NSCalendar.currentCalendar()
            
            var targetDate:NSDate
            var eventName = "D"
            if let event = object.valueForKey("showEvent")? as? NSManagedObject {
                eventName = event.valueForKey("title")? as String
                targetDate = event.valueForKey("date")? as NSDate
            }else{
                targetDate = object.valueForKey("date")? as NSDate
            }
            cell.dateLabel.text = stringFromDate(targetDate)

            let date = targetDate
            let gap = targetDate.timeIntervalSinceDate(NSDate())
            let toDate = NSDate()

            let todayDateComponents = currnetCalendar.components(NSCalendarUnit.DayCalendarUnit, fromDate: targetDate, toDate: toDate, options: NSCalendarOptions.allZeros)
            if todayDateComponents.day == 0 {
                cell.ddayLabel.text = "D-Day!"
            }else if todayDateComponents.day > 0 {
                cell.ddayLabel.text = "\(eventName)+\(todayDateComponents.day)"
            } else {
                cell.ddayLabel.text = "\(eventName)\(todayDateComponents.day)"
            }
        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("DDay", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) {
    	     // Replace this implementation with code to handle the error appropriately.
    	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //println("Unresolved error \(error), \(error.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    func setFetchedResultsController(newfrc:NSFetchedResultsController) {
        let oldfrc:NSFetchedResultsController = self.fetchedResultsController
        if newfrc != oldfrc {
            _fetchedResultsController = newfrc
            newfrc.delegate = self;
            if (self.title != nil || self.title == oldfrc.fetchRequest.entity?.name?) && (self.navigationController != nil || self.navigationItem.title != nil) {
                self.title = newfrc.fetchRequest.entity?.name?
            }
//            if newfrc != nil {
//                if (self.debug) NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldfrc ? @"updated" : @"set");
                performFetch()
//            } else {
//                if self.debug != nil {
//                    NSLog("[%@ %@] reset to nil", NSStringFromClass(self.classForCoder), __FUNCTION__)
//                }
//                tableView.reloadData()
//            }
        }
    }


    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

    // MARK: - DdayViewControllerDelegate
    func ddayViewControllerDidCancel(viewController: DdayViewController) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        
    }
    func ddayViewController(viewController: DdayViewController, didCreateItem: AnyObject) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }
}

