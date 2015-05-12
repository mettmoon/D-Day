//
//  TodayViewController.swift
//  SummaryWidget
//
//  Created by Moon Hayden on 2015. 5. 12..
//  Copyright (c) 2015년 Hayden. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var titleLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        println("load start")
        let fetchRequest = NSFetchRequest()
        // Edit the entity name ase appropriate.
        var moc = self.managedObjectContext
        let entity = NSEntityDescription.entityForName("DDay", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        var error:NSError?
        var result = self.managedObjectContext?.executeFetchRequest(fetchRequest, error: &error)
        if let object = result?.first as? NSManagedObject {
            titleLabel.text = object.valueForKey("title") as? String
            println("load success")
        }else{
            if let error = error {
                println(error.description)
            }
            titleLabel.text = "failed"
        }
        
        // Do any additional setup after loading the view from its nib.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        println("viewDidAppear");
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.WEJOApps.D-Day")
        return urls!
//        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
//        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        
        let modelURL = NSBundle(forClass: object_getClass(self)).URLForResource("D_Day", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            //            let iCloudEnabledAppID = "iCloud.\(NSBundle.mainBundle().bundleIdentifier!)"
        let dataFileName = "D_Day.sqlite"
        let localStore = self.applicationDocumentsDirectory.URLByAppendingPathComponent(dataFileName)
        var options:NSMutableDictionary = NSMutableDictionary()
        options.setObject(NSNumber(bool: true), forKey:NSMigratePersistentStoresAutomaticallyOption)
        options.setObject(NSNumber(bool: true), forKey:NSInferMappingModelAutomaticallyOption)
        coordinator?.lock()
        coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:localStore, options:options as [NSObject : AnyObject], error:nil)
        coordinator?.unlock()
        NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object:self, userInfo:nil)
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        
        if let coordinator = self.persistentStoreCoordinator {
            //            var managedObjectContext = NSManagedObjectContext()
            //            managedObjectContext.persistentStoreCoordinator = coordinator
            
            var managedObjectContext = NSManagedObjectContext(concurrencyType:NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
            managedObjectContext.performBlockAndWait({ () -> Void in
                managedObjectContext.persistentStoreCoordinator = coordinator
                NSNotificationCenter.defaultCenter().addObserver(self, selector:"mergeChangesFrom_iCloud:", name:NSPersistentStoreDidImportUbiquitousContentChangesNotification, object:coordinator)
            })
            self.managedObjectContext = managedObjectContext
            return managedObjectContext
        }else{
            return nil
        }
        }()
    

}