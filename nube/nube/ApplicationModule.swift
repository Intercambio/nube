//
//  ApplicationModule.swift
//  nube
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudStore

public class ApplicationModule: AccountListRouter, ResourceListRouter {
    
    public let window: UIWindow
    public let cloudService: CloudService
    
    let accountListModule: AccountListModule
    let resourceListModule: ResourceListModule
    let resourceModule: ResourceModule
    let resourceBrowserModule: ResourceBrowserModule
    
    let mainModule: MainModule
    
    public init(window: UIWindow, cloudService: CloudService) {
        self.window = window
        self.cloudService = cloudService
        
        accountListModule = AccountListModule(cloudService: cloudService)
        resourceListModule = ResourceListModule(cloudService: cloudService)
        resourceModule = ResourceModule()
        resourceBrowserModule = ResourceBrowserModule()
        mainModule = MainModule()
        
        resourceBrowserModule.accountListModule = accountListModule
        resourceBrowserModule.resourceListModule = resourceListModule
        resourceBrowserModule.resourceModule = resourceModule
        mainModule.resourceBrowserModule = resourceBrowserModule
        mainModule.resourceModule = resourceModule
        
        accountListModule.router = self
        resourceListModule.router = self
    }
    
    public func present() {
        window.backgroundColor = UIColor.white
        window.rootViewController = mainModule.makeViewController()
        window.makeKeyAndVisible()
    }
    
    // MARK: AccountListRouter, ResourceListRouter
    
    public func present(resourceAt path: [String], of account: CloudService.Account) {
        do {
            guard
                let resource = try cloudService.resource(of: account, at: path)
                else { return }
            self.present(resource)
        } catch {
            NSLog("Failed to get resource manager: \(error)")
        }
    }
    
    public func present(_ resource: CloudService.Resource) {
        guard
            let resourcePresenter = window.rootViewController as? ResourcePresenter
            else { return }
        resourcePresenter.present(resource, animated: true)
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
