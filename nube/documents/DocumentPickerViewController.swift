//
//  DocumentPickerViewController.swift
//  documents
//
//  Created by Tobias Kraentzer on 06.02.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudService
import KeyChain

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, AccountListRouter, ResourceListRouter, CloudServiceDelegate {
    
    let cloudService: CloudService
    
    var accountListModule: AccountListModule!
    var resourceListModule: ResourceListModule!
    var resourceDetailsModule: ResourceDetailsModule!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {

        let keyChain = KeyChain(serviceName: "im.intercambio.nube")
        
        let fileManager = FileManager.default
        let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.nube")!
        
        let resourcesDirectory = directory.appendingPathComponent("resources", isDirectory: true)
        try! FileManager.default.createDirectory(at: resourcesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        cloudService = CloudService(directory: resourcesDirectory, keyChain: keyChain)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        cloudService.delegate = self
        cloudService.start { [weak self] (error) in
            DispatchQueue.main.async {
                guard let this = self else { return }
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    this.accountListModule = AccountListModule(cloudService: this.cloudService)
                    this.resourceListModule = ResourceListModule(cloudService: this.cloudService)
                    this.resourceDetailsModule = ResourceDetailsModule(cloudService: this.cloudService)
                    
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
            let resourceID = ResourceID(accountID: account.identifier, path: Path(components: path))
            guard
                let resource = try cloudService.resource(with: resourceID)
                else { return }
            self.present(resource)
        } catch {
            NSLog("Failed to get resource manager: \(error)")
        }
    }
    
    public func presentSettings(for account: Account) {
        
    }
    
    func present(_ resource: Resource) {
        present(resource, animated: true)
    }
    
    func presentNewAccount() {}
    
    // MARK: ServiceDelegate
    
    func service(_ service: CloudService,
                 needsPasswordFor account: Account,
                 completionHandler: @escaping (String?) -> Void) {
    }
    
    
    func serviceDidBeginActivity(_ service: CloudService) {
        
    }
    
    func serviceDidEndActivity(_ service: CloudService) {
        
    }
}

extension DocumentPickerViewController: ResourceUserInterface {
    
    public var resource: Resource? {
        guard
            let navigationController = self.navigationController,
            let resourcePresenter = navigationController.topViewController as? ResourceUserInterface
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
        if resource.properties.isCollection == true {
            viewController = resourceListModule.makeViewController()
        } else {
            viewController = resourceDetailsModule.makeViewController()
        }
        if let resourcePresenter = viewController as? ResourceUserInterface {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}
