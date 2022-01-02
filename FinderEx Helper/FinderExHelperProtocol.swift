//
//  FinderExHelperProtocol.swift
//  FinderEx Helper
//
//  Created by Yanto Suryono on 2021/12/31.
//

import Foundation

@objc public protocol FinderExHelperProtocol {
    func homeDir(withReply reply: @escaping (String) -> Void)
    func loadConfig(user: Bool, withReply reply: @escaping (String) -> Void)
    func saveConfig(content: String, withReply reply: @escaping (Bool) -> Void)
    func run(exec: String, input: String, args: [String], withReply reply: @escaping (String?, Int32) -> Void)
}

