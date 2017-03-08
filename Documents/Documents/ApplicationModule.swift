//
//  ApplicationModule.swift
//  Documents
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudService

public class ApplicationModule: AccountListRouter, ResourceListRouter {
    
    public let window: UIWindow
    public let cloudService: CloudService
    
    let accountListModule: AccountListModule
    let resourceListModule: ResourceListModule
    let resourceDetailsModule: ResourceDetailsModule
    let resourceBrowserModule: ResourceBrowserModule
    let settingsModule: SettingsModule
    
    let mainModule: MainModule
    
    public init(window: UIWindow, cloudService: CloudService) {
        self.window = window
        self.cloudService = cloudService
        
        accountListModule = AccountListModule(interactor: cloudService)
        resourceListModule = ResourceListModule(interactor: cloudService)
        resourceDetailsModule = ResourceDetailsModule(interactor: cloudService)
        resourceBrowserModule = ResourceBrowserModule()
        settingsModule = SettingsModule(interactor: cloudService)
        mainModule = MainModule(cloudService: cloudService)
        
        resourceBrowserModule.accountListModule = accountListModule
        resourceBrowserModule.resourceListModule = resourceListModule
        resourceBrowserModule.resourceDetailsModule = resourceDetailsModule
        mainModule.resourceBrowserModule = resourceBrowserModule
        mainModule.resourceDetailsModule = resourceDetailsModule
        mainModule.settingsModule = settingsModule
        
        accountListModule.router = self
        resourceListModule.router = self
    }
    
    public func present() {
        window.backgroundColor = UIColor.white
        window.rootViewController = mainModule.makeViewController()
        window.makeKeyAndVisible()
    }
    
    // MARK: AccountListRouter, ResourceListRouter
    
    public func present(resourceAt path: [String], of account: Account) {
        do {
            let resourceID = ResourceID(accountID: account.identifier, path: Path(components: path))
            guard
                let resource = try cloudService.resource(with: resourceID)
                else { return }
            self.present(resource)
        } catch {
            NSLog("Failed to get resource manager: \(error)")
        }
    }
    
    public func present(_ resource: Resource) {
        guard
            let resourceUserInterface = window.rootViewController as? ResourceUserInterface
            else { return }
        resourceUserInterface.present(resource, animated: true)
    }
    
    public func presentSettings(for account: Account) {
        guard
            let settingsUserInterface = window.rootViewController as? SettingsUserInterface
            else { return }
        settingsUserInterface.presentSettings(forAccountWith: account.identifier, animated: true)
    }
    
    public func presentNewAccount() {
        
        let title = "Add Account"
        let message = "Enter the url and username of your Nextcloud server"
        
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("https://could.example.com", comment: "")
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("Username", comment: "")
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: NSLocalizedString("Add", comment: ""), style: .default) {
            action in
            guard
                let urlString = alert.textFields?.first?.text,
                let url = URL(string: urlString),
                let username = alert.textFields?.last?.text
                else {
                    return
            }
            
            let _ = try! self.cloudService.addAccount(with: url, username: username)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) {
            action in
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        if let viewControler = window.rootViewController?.presentedViewController {
            viewControler.present(alert, animated: true, completion: nil)
        } else {
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
