//
//  AppDelegate.swift
//  D-Day
//
//  Created by Moon Hayden on 2014. 10. 28..
//  Copyright (c) 2014년 Hayden. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let controller = masterNavigationController.topViewController as! MasterViewController
        controller.managedObjectContext = self.managedObjectContext
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController!, ontoPrimaryViewController primaryViewController:UIViewController!) -> Bool {
        if let secondaryAsNavController = secondaryViewController as? UINavigationController {
            if let topAsDetailController = secondaryAsNavController.topViewController as? DdayViewController {
                if topAsDetailController.detailItem == nil {
                    // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                    return true
                }
            }
        }
        return false
    }
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("D_Day", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//            let iCloudEnabledAppID = "iCloud.\(NSBundle.mainBundle().bundleIdentifier!)"
            let iCloudEnabledAppID = "dataStore"
            let dataFileName = "D_Day.sqlite"
            
            let iCloudDataDirectoryName = "Data.nosync"
            let iCloudLogsDirectoryName = "Logs"
            let fileManager = NSFileManager.defaultManager()
            let localStore = self.applicationDocumentsDirectory.URLByAppendingPathComponent(dataFileName)
            
            if let iCloud = fileManager.URLForUbiquityContainerIdentifier(nil) as NSURL! {
                
                NSLog("iCloud is working")
                let pathString = (iCloud.path! as NSString).stringByAppendingPathComponent(iCloudLogsDirectoryName) as String!
                let iCloudLogsPath:NSURL = NSURL(fileURLWithPath:pathString)!
                NSLog("iCloudEnabledAppID = %@",iCloudEnabledAppID)
                NSLog("dataFileName = %@", dataFileName)
                NSLog("iCloudDataDirectoryName = %@", iCloudDataDirectoryName)
                NSLog("iCloudLogsDirectoryName = %@", iCloudLogsDirectoryName)
                NSLog("iCloud = %@", iCloud)
                NSLog("iCloudLogsPath = %@", iCloudLogsPath)
                if fileManager.fileExistsAtPath((iCloud.path! as NSString).stringByAppendingPathComponent(iCloudDataDirectoryName)) == false {
                    var fileSystemError:NSError?
                    let pathString2:String! = NSString(string: iCloud.path! ).stringByAppendingPathComponent(iCloudDataDirectoryName) as String
                    fileManager.createDirectoryAtPath(pathString2, withIntermediateDirectories: true, attributes: nil, error: &fileSystemError)
                    if let error = fileSystemError {
                        NSLog("Error creating database directory %@", error)
                    }
                }
                
                let iCloudData = NSString(string:iCloud.path!).stringByAppendingPathComponent(iCloudDataDirectoryName).stringByAppendingPathComponent(dataFileName)
                
                
                NSLog("iCloudData = %@", iCloudData)
                
                var options:NSMutableDictionary = NSMutableDictionary()
                options.setObject(NSNumber(bool: true), forKey: NSMigratePersistentStoresAutomaticallyOption)
                options.setObject(NSNumber(bool:true), forKey: NSInferMappingModelAutomaticallyOption)
                options.setObject(iCloudEnabledAppID, forKey: NSPersistentStoreUbiquitousContentNameKey)
                options.setObject(iCloudLogsPath, forKey: NSPersistentStoreUbiquitousContentURLKey)
                coordinator?.performBlockAndWait({ () -> Void in
                    coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:NSURL(fileURLWithPath:iCloudData), options:options as [NSObject : AnyObject], error:nil)
                    return
                })
            }
            else {
                NSLog("iCloud is NOT working - using a local store")
                var options:NSMutableDictionary = NSMutableDictionary()
                options.setObject(NSNumber(bool: true), forKey:NSMigratePersistentStoresAutomaticallyOption)
                options.setObject(NSNumber(bool: true), forKey:NSInferMappingModelAutomaticallyOption)
                
                coordinator?.lock()
                
                coordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration:nil, URL:localStore, options:options as [NSObject : AnyObject], error:nil)
                coordinator?.unlock()
                
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("SomethingChanged", object:self, userInfo:nil)
            });
        });

        
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

    
    func mergeChangesFrom_iCloud(notification:NSNotification) {
    
        NSLog("Merging in changes from iCloud...")
        
        let moc:NSManagedObjectContext = self.managedObjectContext!
    
        moc.performBlockAndWait { () -> Void in
            moc.mergeChangesFromContextDidSaveNotification(notification)
            var refreshNotification:NSNotification = NSNotification(name: "SomethingChanged", object: self, userInfo: notification.userInfo)
            NSNotificationCenter.defaultCenter().postNotification(refreshNotification)
        }
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}

