//
//  FinderSync.swift
//  FinderEx Context Menu
//
//  Created by Yanto Suryono on 2021/12/28.
//

import Cocoa
import FinderSync

extension Menu {
    
    func run(input: [String]) {
    
        if let a = action, let c = content {
            
            let exec: String = "/usr/bin/env"
            var args: [String]
            var stdin: String
            
            switch a {
            case "bash":
                // bash [options] [file]
                if fromfile {
                    if path == nil { return }
                    if path!.isEmpty { return }
                    args = ["bash", path!] + input
                    stdin = ""
                }
                else {
                    args = ["bash", "/dev/stdin"] + input
                    stdin = c
                }
            case "applescript":
                // osascript [-l language] [-i] [-s flags] [-e statement | programfile] [argument ...]
                if fromfile {
                    if path == nil { return }
                    if path!.isEmpty { return }
                    args = ["osascript", path!] + input
                    stdin = ""
                }
                else {
                    args = ["osascript", "-"] + input
                    stdin = c
                }
            case "workflow":
                // automator [-v] [-i input] [-D name=value ...] workflow
                if !fromfile { return }
                if path == nil { return }
                if path!.isEmpty { return }
                args = ["automator", "-i", "-", path!]
                stdin = input.joined(separator: "\n")
            default:
                return
            }
            XPCWrapper.run(exec: exec, input: stdin, args: args)
        }
    }
}

class FinderSync: FIFinderSync {

    var config: [ConfigItem] = []
    var menus: [Menu] = []
    var folder: URL?
    var items: [URL] = []
    let alwaysLoadConfig = true
    
    override init() {
        
        super.init()
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)

        config = loadConfig()
        
        let fs = FIFinderSyncController.default()

        // Monitor all currently visible mounted volumes
        // TODO: make this user configurable
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: .skipHiddenVolumes) {
            fs.directoryURLs = Set<URL>(mountedVolumes)
        }
        
        // Also handle changes in mounted volumes
        // TODO: make this user configurable
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(forName: NSWorkspace.didMountNotification, object: nil, queue: .main) { n in
            if let url = n.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                fs.directoryURLs.insert(url)
            }
        }
        nc.addObserver(forName: NSWorkspace.didUnmountNotification, object: nil, queue: .main) { n in
            if let url = n.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                fs.directoryURLs.remove(url)
            }
        }
        nc.addObserver(forName: NSWorkspace.didRenameVolumeNotification, object: nil, queue: .main) { n in
            if let url = n.userInfo?[NSWorkspace.oldVolumeURLUserInfoKey] as? URL {
                fs.directoryURLs.remove(url)
            }
            if let url = n.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                fs.directoryURLs.insert(url)
            }
        }
    }
    
    private func loadConfig() -> [ConfigItem] {
        return ConfigManager.loadConfigAsArray(includeSystemWide: true)
    }
 
    private func askFolder(withReply reply: @escaping (URL?) -> Void) {
        
        // Need to steal active state in order to open dialog
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            
            let dialog = NSOpenPanel()
            
            dialog.title = "Select folder ..."
            dialog.showsResizeIndicator = true
            dialog.showsHiddenFiles = false
            dialog.allowsMultipleSelection = false
            dialog.canChooseDirectories = true
            dialog.canChooseFiles = false

            if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
                reply(dialog.url)
            }
            else {
                reply(nil)
            }
        }
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        
        let menu = NSMenu(title: "")
        let target = FIFinderSyncController.default().targetedURL()
        let items = FIFinderSyncController.default().selectedItemURLs()
        
        func addMenuItem(forType: String) {
            var item : ConfigItem?
            for c in config {
                if c.type == forType {
                    item = c
                }
            }
            if let i = item {
                for j in 0..<i.menus.count {
                    let m = i.menus[j]
                    if m.valid() {
                        let item = NSMenuItem(title: m.title!, action: #selector(actionMenu(_:)), keyEquivalent: "")
                        item.tag = self.menus.count
                        self.menus.append(m)
                        menu.addItem(item)
                    }
                }
            }
        }
        
        func addMenuItem(forItem: ConfigItem) {
            for j in 0..<forItem.menus.count {
                let m = forItem.menus[j]
                if m.valid() {
                    let item = NSMenuItem(title: m.title!, action: #selector(actionMenu(_:)), keyEquivalent: "")
                    item.tag = self.menus.count
                    self.menus.append(m)
                    menu.addItem(item)
                }
            }
        }
        
        if alwaysLoadConfig {
            config = loadConfig()
        }
        
        self.menus = []
        
        switch menuKind {
        case .contextualMenuForContainer:
            // items == target: folder
            if target != nil {
                self.folder = target
                self.items = [target!]
            
                // Add menu items for container
                addMenuItem(forType: "c")
            }
            return menu
        case .contextualMenuForItems:
            // items: items selected (can be multiple)
            // target: folder where the items reside
            if target == nil {
                return menu
            }
            self.folder = target
            self.items = items ?? []
            
            // Add menu items for all items (folders and files)
            addMenuItem(forType: "a")
            
            if self.items.count > 0 {
                
                var type: String?
                var isDir: ObjCBool = true
                
                // Test if selected items are all folders or all files
                for item in self.items {
                    if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir) {
                        let thisType = isDir.boolValue ? "d" : "f"
                        if thisType != type {
                            if type == nil {
                                type = thisType
                            }
                            else {
                                type = nil
                                break
                            }
                        }
                    }
                }
                
                // Only proceed if selected items are all folders or all files
                if let t = type {
                    
                    // Add menu items for folders / files
                    addMenuItem(forType: t)
                    
                    // Only proceed if all selected items are files
                    if t == "f" {
                        
                        // Check if all selected items are member of a category
                        // If yes, then add menu items for the category
                        for i in 0..<config.count {
                            let isMember = self.items.map { config[i].isMember(path: $0.path) }
                            if isMember.reduce(true, { x, y in x && y }) {
                                addMenuItem(forItem: config[i])
                            }
                        }
                    }
                }
            }
        default:
            return menu
        }
        
        return menu
    }
    
    @objc func actionMenu(_ sender: AnyObject?) {
        
        let item = sender as! NSMenuItem
        if item.tag < 0 || item.tag >= self.menus.count {
            // TODO: handle error
            return
        }
        let menu = self.menus[item.tag]
        
        var items: [String] = []
        for i in self.items {
            items.append(i.path)
        }
        
        if menu.askfolder {
            askFolder() { response in
                if let folder = response {
                    // Prepend folder to items
                    items = [folder.path] + items
                    menu.run(input: items)
                }
            }
        }
        else {
            menu.run(input: items)
        }
    }
}

