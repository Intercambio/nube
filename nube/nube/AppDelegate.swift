//
//  AppDelegate.swift
//  nube
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudStore
import KeyChain

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CloudServiceDelegate {

    var window: UIWindow?
    var applicationModule: ApplicationModule?
    var cloudService: CloudService?
    var keyChain: KeyChain?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        guard
            let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.nube")
            else { return false }
        
        let resourcesDirectory = directory.appendingPathComponent("resources", isDirectory: true)
        try! FileManager.default.createDirectory(at: resourcesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        self.keyChain = KeyChain(serviceName: "im.intercambio.nube")
        
        cloudService = CloudService(directory: resourcesDirectory)
        cloudService?.delegate = self
        cloudService?.start { (error) in
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
    
    // MARK: ServiceDelegate
    
    func service(_ service: CloudService, needsPasswordFor account: CloudService.Account, completionHandler: @escaping (String?) -> Void) {
        
        guard
            let keyChain = self.keyChain,
            let prompt = window?.rootViewController as? PasswordPrompt,
            var accountURL = URLComponents(url: account.url, resolvingAgainstBaseURL: true)
            else {
                completionHandler(nil)
                return
        }
        
        accountURL.user = account.username
        
        guard
            let identifier = accountURL.url?.absoluteString
            else {
                completionHandler(nil)
                return
        }
        
        do {
            let item = KeyChainItem(identifier: identifier, invisible: false, options: [:])
            try keyChain.add(item)
        } catch {
            
        }
        
        do {
            let password = try keyChain.passwordForItem(with: identifier)
            completionHandler(password)
        } catch {
            prompt.requestPassword(for: account) { password in
                do {
                    try keyChain.setPassword(password, forItemWith: identifier)
                    completionHandler(password)
                } catch {
                    completionHandler(password)
                }
            }
        }
    }
    
}

