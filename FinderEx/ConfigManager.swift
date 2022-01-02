//
//  ConfigManager.swift
//  FinderEx
//
//  Created by Yanto Suryono on 2021/12/24.
//

import Cocoa
import Yaml

extension StringProtocol {
    var lines: [SubSequence] {
        split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }
}

class Menu: NSObject {
    
    @objc dynamic var title: String?
    @objc dynamic var action: String?
    @objc dynamic var path: String?
    @objc dynamic var content: String?
    @objc dynamic var askfolder: Bool
    @objc dynamic var fromfile: Bool

    static let validActions = ["applescript", "bash", "workflow"]
    
    var initTitle: String?
    var initAction: String?
    var initPath: String?
    var initContent: String?
    var initAskFolder: Bool = false
    var initFromFile: Bool = false

    init(title: String?, action: String?, path: String?, content: String?, askfolder: Bool?, fromfile: Bool?) {
        self.title = title
        self.action = action
        self.path = path
        self.content = content
        self.askfolder = askfolder ?? false
        self.fromfile = fromfile ?? false
    }
    
    func valid() -> Bool {
        return (
            self.title != nil &&
            self.action != nil &&
            (
                (self.fromfile && self.path != nil) ||
                (!self.fromfile && self.content != nil)
            ) &&
            Self.validActions.contains(self.action!)
        )
    }
}

class ConfigItem: NSObject {
    
    @objc dynamic var name: String
    @objc dynamic var type: String
    @objc dynamic var ext: String
    @objc dynamic var allowedit: Bool
    
    var menus: [Menu] = []
    
    init(name: String, type: String, ext: String, allowedit: Bool) {
        self.name = name
        self.type = type
        self.ext = ext
        self.allowedit = allowedit
    }

    init(name: String, type: String, ext: String) {
        self.name = name
        self.type = type
        self.ext = ext
        self.allowedit = true
    }
    
    func isMember(path: String) -> Bool {
        for i in extensions {
            if path.hasSuffix(i) {
                return true
            }
        }
        return false
    }
    
    var extensions: [String] {
        get {
            return ext.split(separator: ";", omittingEmptySubsequences: true)
                .map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                .filter {
                    !$0.isEmpty
                }
        }
    }
}

class ConfigManager: NSObject {

    static func loadConfig(includeSystemWide: Bool) -> [Yaml] {
        
        var systemNodes: Yaml?
        var userNodes: Yaml?
        
        func loadConfigFromFile(user: Bool) -> Yaml? {
            var nodes: Yaml?
            if let yaml = XPCWrapper.loadConfig(user: user) {
                nodes = try! Yaml.load(yaml)
                if nodes == Yaml.null {
                    nodes = nil
                }
            }
            return nodes
        }
    
        if includeSystemWide {
            systemNodes = loadConfigFromFile(user: false)
        }
        userNodes = loadConfigFromFile(user: true)
        
        var nodes: [Yaml] = []
        
        // combine system and user nodes
        if systemNodes != nil {
            for n in systemNodes!.array! {
                nodes.append(n)
            }
        }
        if userNodes != nil {
            for n in userNodes!.array! {
                nodes.append(n)
            }
        }
        
        return nodes
    }
    
    static private func nodeAsArray(node: [Yaml]) -> [ConfigItem] {
    
        var configArray: [ConfigItem] = []
        
        for n in node {
            let item = ConfigItem(
                name: n["name"].string!,
                type: n["type"].string ?? "",
                ext: n["ext"].string ?? "")
            item.allowedit = n["allowedit"].bool ?? true
            if let menus = n["menus"].array {
                for menu in menus {
                    item.menus.append(Menu(
                        title: menu["title"].string,
                        action: menu["action"].string,
                        path: menu["path"].string,
                        content: menu["content"].string,
                        askfolder: menu["askfolder"].bool,
                        fromfile: menu["fromfile"].bool
                    ))
                }
            }
            configArray.append(item)
        }

        return configArray
    }
    
    static func loadConfigAsArray(includeSystemWide: Bool) -> [ConfigItem] {
        
        let node = Self.loadConfig(includeSystemWide: includeSystemWide)
        return Self.nodeAsArray(node: node)
    }
    
    static func generateDefault() -> [ConfigItem] {
    
        let yaml = """
            - name: "Container"
              type: c
              allowedit: false
            - name: "All Items"
              type: a
              allowedit: false
              menus:
                - title: "Show Selected Items ..."
                  action: applescript
                  content: |
                    on run argv
                            set theText to ""
                            repeat with theArg in argv
                                    set theText to (theText & theArg & "\\n")
                            end repeat
                            display dialog theText
                    end run

            - name: "Folders"
              type: d
              allowedit: false
            - name: "Files"
              type: f
              allowedit: false
            - name: "Image Files"
              ext: ".png;.gif;.jpg;.jpeg"
            """
        print(yaml)
        var node: [Yaml] = []
        for n in (try! Yaml.load(yaml)).array! {
            node.append(n)
        }
        return Self.nodeAsArray(node: node)
    }
    
    @discardableResult static func saveConfigFromArray(configArray: [ConfigItem]?) -> Bool {
        
        var content: String = ""
        
        func appendLine(str: String, indent: Int) {
            content += (String(repeating: " ", count: indent*2) + str + "\n")
        }

        if let config = configArray {
            for item in config {
                appendLine(str:String(format:"- name: \"%@\"", item.name), indent:0)
                if item.type != "" { // default is blank
                    appendLine(str:String(format:"  type: %@", item.type), indent:0)
                }
                if item.ext != "" { // default is blank
                    appendLine(str:String(format:"  ext: \"%@\"", item.ext), indent:0)
                }
                if !item.allowedit { // default is true
                    appendLine(str:"  allowedit: false", indent:0)
                }
                if item.menus.count > 0 {
                    var first: Bool = true
                    for menu in item.menus {
                        if let title = menu.title, let action = menu.action, let content = menu.content {
                            if first {
                                appendLine(str:"  menus:", indent:0)
                                first = false
                            }
                            appendLine(str:String(format:"- title: \"%@\"", title), indent: 2)
                            appendLine(str:String(format:"  action: %@", action), indent: 2)
                            if menu.askfolder { // default is false
                                appendLine(str:"  askfolder: true", indent: 2)
                            }
                            if menu.fromfile { // default is false
                                appendLine(str:"  fromfile: true", indent: 2)
                                if let path = menu.path {
                                    appendLine(str:String(format:"  path: \"%@\"", path), indent: 2)
                                }
                            }
                            appendLine(str:"  content: |", indent: 2)
                            for line in content.lines {
                                appendLine(str:String(line), indent: 4)
                            }
                        }
                    }
                }
            }
            if let res = XPCWrapper.saveConfig(content: content) {
                return res
            }
        }
        return false
    }
}
