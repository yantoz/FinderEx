//
//  main.swift
//  FinderEx Helper
//
//  Created by Yanto Suryono on 2021/12/31.
//

import Foundation

class FinderExHelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = FinderExHelper()
        newConnection.exportedInterface = NSXPCInterface(with: FinderExHelperProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}

let delegate = FinderExHelperDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()

