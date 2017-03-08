//
//  DocumentPickerViewController.swift
//  Picker
//
//  Created by Tobias Kräntzer on 03.03.17.
//  Copyright © 2017 Tobias Kräntzer. All rights reserved.
//

import UIKit
import CloudUI
import CloudService
import KeyChain

class DocumentPickerViewController: UIDocumentPickerExtensionViewController, CloudServiceDelegate, AccountListRouter, ResourceListRouter {

    let cloudService: CloudService = {
        let keyChain = KeyChain(serviceName: "im.intercambio")
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.im.intercambio.documents")!
        let resourcesDirectory = directory.appendingPathComponent("resources", isDirectory: true)
        try! FileManager.default.createDirectory(at: resourcesDirectory, withIntermediateDirectories: true, attributes: nil)
        return CloudService(directory: resourcesDirectory, keyChain: keyChain)
    }()
    
    lazy var accountListModule: AccountListModule = {
        let module = AccountListModule(cloudService: self.cloudService)
        module.router = self
        return module
    }()
    
    lazy var resourceListModule: ResourceListModule = {
        let module = ResourceListModule(cloudService: self.cloudService)
        module.router = self
        return module
    }()
    
    override func prepareForPresentation(in mode: UIDocumentPickerMode) {
        cloudService.delegate = self
        cloudService.start { (error) in
            DispatchQueue.main.async {
                if error != nil {
                    NSLog("Failed to setup service: \(error)")
                } else {
                    self.rootViewController = self.accountListModule.makeViewController()
                }
            }
        }
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

    // MARK: - CloudServiceDelegate
    
    func service(_ service: CloudService, needsPasswordFor account: Account, completionHandler: @escaping (String?) -> Void) {
    }
    
    func serviceDidBeginActivity(_ service: CloudService) {
    }
    
    func serviceDidEndActivity(_ service: CloudService) {
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
            NSLog("Failed to get resource: \(error)")
        }
    }
    
    public func presentSettings(for account: Account) {
        
    }
    
    func present(_ resource: Resource) {
        guard
            let navigationController = self.navigationController,
            let viewController = makeViewController(for: resource)
            else {
                return
        }
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func presentNewAccount() {
    }
    
    private func makeViewController(for resource: Resource) -> UIViewController? {
        var viewController: UIViewController? = nil
        if resource.properties.isCollection == true {
            viewController = resourceListModule.makeViewController()
        } else {
            return nil
        }
        if let resourcePresenter = viewController as? ResourceUserInterface {
            resourcePresenter.present(resource, animated: false)
        }
        return viewController
    }
}
