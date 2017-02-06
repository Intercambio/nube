//
//  DocumentPickerViewController.swift
//  documents
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudStore
import KeyChain

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, AccountListRouter, ResourceListRouter, ServiceDelegate {
    
    let service: Service
    var keyChain: KeyChain
    
    var accountListModule: AccountListModule!
    var resourceListModule: ResourceListModule!
    var resourceModule: ResourceModule!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        keyChain = KeyChain(serviceName: "im.intercambio.nube")
        
        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.nube")!
        service = Service(directory: directory)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        service.delegate = self
        service.start { [weak self] (error) in
            DispatchQueue.main.async {
                guard let this = self else { return }
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    this.accountListModule = AccountListModule(accountManager: this.service.accountManager)
                    this.resourceListModule = ResourceListModule(service: this.service)
                    this.resourceModule = ResourceModule()
                    
                    this.accountListModule.router = this
                    this.resourceListModule.router = this
                    
                    this.rootViewController = this.accountListModule.makeViewController()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        
    }
    
    // MARK: Root View Controller
    
    var rootViewController: UIViewController? {
        didSet {
            if let viewController = rootViewController {
                addChildViewController(viewController)
                viewController.view.frame = view.bounds
                viewController.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                viewController.view.translatesAutoresizingMaskIntoConstraints = true
                view.addSubview(viewController.view)
                viewController.didMove(toParentViewController: self)
            }
        }
    }
    
    // MARK: AccountListRouter, ResourceListRouter
    
    
    public func present(resourceAt path: [String], of account: Account) {
        do {
            let resourceManager = service.resourceManager(for: account)
            
            guard
                let resource = try resourceManager.resource(at: path)
                else { return }
            
            self.present(resource)
            
        } catch {
            NSLog("Failed to get resource manager: \(error)")
        }
    }
    
    func present(_ resource: Resource) {
        present(resource, animated: true)
    }
    
    func presentNewAccount() {}
    
    // MARK: ServiceDelegate
    
    func service(_ service: Service, needsPasswordFor account: Account, completionHandler: @escaping (String?) -> Void) {
        guard
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
            let password = try keyChain.passwordForItem(with: identifier)
            completionHandler(password)
        } catch {
            NSLog("/(error)")
        }
    }
}

extension DocumentPickerViewController: ResourcePresenter {
    
    public var resource: Resource? {
        guard
            let navigationController = self.navigationController,
            let resourcePresenter = navigationController.topViewController as? ResourcePresenter
            else {
                return nil
        }
        return resourcePresenter.resource
    }
    
    public func present(_ resource: Resource, animated: Bool) {
        guard
            let navigationController = self.navigationController,
            let viewController = makeViewController(for: resource)
            else {
                return
        }
        navigationController.pushViewController(viewController, animated: animated)
    }
    
    private func makeViewController(for resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource.isCollection == true {
            viewController = resourceListModule.makeViewController()
        } else {
            viewController = resourceModule.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourcePresenter {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}
