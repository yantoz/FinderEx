//
//  XPCWrapper.swift
//  FinderEx
//
//  Created by Yanto Suryono on 2021/12/31.
//

import Foundation

class XPCWrapper {
    
    static let XPCProtocol: Protocol = FinderExHelperProtocol.self
    static let serviceName = "app.yantoz.FinderEx.Helper"
    static let connection: NSXPCConnection = XPCWrapper.initConnection()
    
    static func initConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(serviceName: XPCWrapper.serviceName)
        connection.remoteObjectInterface = NSXPCInterface(with: FinderExHelperProtocol.self)
        connection.resume()
        return connection
    }
    
    static func initSettings(connection: NSXPCConnection) -> FinderExHelperProtocol? {
        let service = connection.synchronousRemoteObjectProxyWithErrorHandler { error in
            NSLog("\(XPCWrapper.serviceName) error: %@", error.localizedDescription)
            print("Error establishing XPC connection:", error)
        } as? FinderExHelperProtocol
        return service
    }
    
    static let service: FinderExHelperProtocol? = XPCWrapper.initSettings(connection: XPCWrapper.connection)
    
    static func homeDir() -> String? {
        
        guard let service = Self.service else {
            return nil
        }
                
        let semaphore = DispatchSemaphore(value: 0)

        var ret: String? = nil
        service.homeDir() { data in
            defer {
                semaphore.signal()
            }
            ret = data
        }
        
        if !Thread.isMainThread {
            _ = semaphore.wait(timeout: .distantFuture)
        } else {
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        return ret
    }

    static func loadConfig(user: Bool) -> String? {
        
        guard let service = Self.service else {
            return nil
        }
                
        let semaphore = DispatchSemaphore(value: 0)

        var ret: String? = nil
        service.loadConfig(user: user) { data in
            defer {
                semaphore.signal()
            }
            ret = data
        }
        
        if !Thread.isMainThread {
            _ = semaphore.wait(timeout: .distantFuture)
        } else {
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        return ret
    }
    
    @discardableResult static func saveConfig(content: String) -> Bool? {
        
        guard let service = Self.service else {
            return nil
        }
                
        let semaphore = DispatchSemaphore(value: 0)

        var ret: Bool? = nil
        service.saveConfig(content: content) { data in
            defer {
                semaphore.signal()
            }
            ret = data
        }
        
        if !Thread.isMainThread {
            _ = semaphore.wait(timeout: .distantFuture)
        } else {
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        return ret
    }
    
    @discardableResult static func run(exec: String, input: String, args: [String]) -> Int32? {
        
        guard let service = Self.service else {
            return nil
        }
                
        let semaphore = DispatchSemaphore(value: 0)

        var ret: Int32? = nil
        service.run(exec: exec, input: input, args: args) { output, status in
            defer {
                semaphore.signal()
            }
            ret = status
        }
        
        if !Thread.isMainThread {
            _ = semaphore.wait(timeout: .distantFuture)
        } else {
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0))
            }
        }
        return ret
    }
}

