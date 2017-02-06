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
class AppDelegate: UIResponder, UIApplicationDelegate, ServiceDelegate {

    var window: UIWindow?
    var applicationModule: ApplicationModule?
    var service: Service?
    var keyChain: KeyChain?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        self.keyChain = KeyChain(serviceName: "im.intercambio.nube")
        
        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.nube")!
        service = Service(directory: directory)
        service?.delegate = self
        service?.start { (error) in
            DispatchQueue.main.async {
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    let screen = UIScreen.main
                    self.window = UIWindow(frame: screen.bounds)
                    self.window?.screen = screen
                    self.applicationModule = ApplicationModule(window: self.window!, service: self.service!)
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
    
    func service(_ service: Service, needsPasswordFor account: Account, completionHandler: @escaping (String?) -> Void) {
        guard
            let keyChain = self.keyChain,
            let passwordPromt = window?.rootViewController as? PasswordPromt,
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
            passwordPromt.requestPassword(for: account) { password in
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

