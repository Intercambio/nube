//
//  AppDelegate.swift
//  Documents
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudService
import KeyChain

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CloudServiceDelegate {
    
    var window: UIWindow?
    var applicationModule: ApplicationModule?
    var cloudService: CloudService?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        guard
            let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.documents")
        else { return false }
        
        let resourcesDirectory = directory.appendingPathComponent("resources", isDirectory: true)
        try! FileManager.default.createDirectory(at: resourcesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let keyChain = KeyChain(serviceName: "im.intercambio.documents")
        
        setupAccountListInteractorNotifications()
        setupResourceListInteractorNotifications()
        setupResourceDetailsInteractorNotifications()
        
        let bundleIdentifier = Bundle(for: AppDelegate.self).bundleIdentifier!
        
        cloudService = CloudService(directory: resourcesDirectory,
                                    keyChain: keyChain,
                                    bundleIdentifier: bundleIdentifier,
                                    sharedContainerIdentifier: "group.im.intercambio.documents")
        cloudService?.delegate = self
        cloudService?.start { error in
            DispatchQueue.main.async {
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    let screen = UIScreen.main
                    self.window = UIWindow(frame: screen.bounds)
                    self.window?.screen = screen
                    self.applicationModule = ApplicationModule(window: self.window!, cloudService: self.cloudService!)
                    self.applicationModule?.present()
                }
            }
        }
        
        let screen = UIScreen.main
        self.window = UIWindow(frame: screen.bounds)
        self.window?.screen = screen
        
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        guard
            let cloudService = self.cloudService
            else {
                completionHandler()
                return
        }
        
        cloudService.handleEvents(forBackgroundURLSession: identifier,
                                  completionHandler: completionHandler)
    }
    
    // MARK: ServiceDelegate
    
    func service(
        _: CloudService,
        needsPasswordFor account: Account,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard
            let prompt = window?.rootViewController as? PasswordUserInterface
        else {
            completionHandler(nil)
            return
        }
        
        prompt.requestPassword(forAccountWith: account.identifier, completion: completionHandler)
    }
    
    func serviceDidBeginActivity(_: CloudService) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func serviceDidEndActivity(_: CloudService) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
