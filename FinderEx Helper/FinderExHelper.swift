//
//  FinderExHelper.swift
//  FinderEx Helper
//
//  Created by Yanto Suryono on 2021/12/31.
//

import Foundation

class FinderExHelper: NSObject, FinderExHelperProtocol {
    
    static let configFile = "Library/FinderEx/config.yaml"
    
    func homeDir(withReply reply: @escaping (String) -> Void) {
        reply(NSHomeDirectory())
    }
    
    func loadConfig(user: Bool, withReply reply: @escaping (String) -> Void) {
        
        var filepath: URL
        
        if user {
            filepath = URL(fileURLWithPath: NSHomeDirectory())
        }
        else {
            filepath = URL(fileURLWithPath: "/")
        }
        filepath = filepath.appendingPathComponent(Self.configFile)
        
        if let content = try? String(contentsOf: filepath) {
            reply(content)
        }
        else {
            reply("")
        }
    }
    
    func saveConfig(content: String, withReply reply: @escaping (Bool) -> Void) {

        let filepath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(Self.configFile)
        let dir = filepath.deletingLastPathComponent()
        
        // Create file path if it does not exist
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(atPath: dir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                reply(false)
                return
            }
        }
        
        // Create file if it does not exist
        if !FileManager.default.fileExists(atPath: filepath.path) {
            FileManager.default.createFile(atPath: filepath.path, contents:Data("".utf8), attributes: nil)
        }
        
        // Open file for writing and clear its content
        guard let fileHandle = FileHandle(forWritingAtPath: filepath.path) else {
            reply(false)
            return
        }
        fileHandle.truncateFile(atOffset: 0)
        
        // Write file content and close
        fileHandle.write(content.data(using: String.Encoding.utf8)!)
        fileHandle.closeFile()
        
        reply(true)
    }

    func run(exec: String, input: String, args: [String], withReply reply: @escaping (String?, Int32) -> Void) {
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: exec)
        task.arguments = args
        
        let pipeIn = Pipe()
        let pipeOut = Pipe()

        task.standardInput = pipeIn
        task.standardOutput = pipeOut
        task.standardError = pipeOut

        pipeIn.fileHandleForWriting.write(input.data(using: .utf8)!)
        pipeIn.fileHandleForWriting.closeFile()
        
        task.launch()
        task.waitUntilExit()
        
        let data = pipeOut.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        
        reply(output, task.terminationStatus)
    }
}
