//
//  AppDelegate.swift
//  FinderEx Editor
//
//  Created by Yanto Suryono on 2021/12/24.
//

import Cocoa
import FinderSync

extension Menu {

    func startEditing() -> Menu {
        initTitle = title
        initAction = action
        initContent = content
        initAskFolder = askfolder
        initFromFile = fromfile
        initPath = path
        return self
    }
    
    func revisitEnabled() {
        self.willChangeValue(forKey: "enabled")
        self.didChangeValue(forKey: "enabled")
    }

    func revisitModified() {
        self.willChangeValue(forKey: "modified")
        self.didChangeValue(forKey: "modified")
    }

    func revisitPath() {
        self.willChangeValue(forKey: "pathValid")
        self.willChangeValue(forKey: "pathValue")
        self.willChangeValue(forKey: "pathColor")
        self.didChangeValue(forKey: "pathValid")
        self.didChangeValue(forKey: "pathValue")
        self.didChangeValue(forKey: "pathColor")
    }
    
    @objc dynamic var enabled: Bool {
        get {
            return !(title == nil || action == nil)
        }
    }
    
    @objc dynamic var modified: Bool {
        get {
            return (title != initTitle || action != initAction || fromfile != initFromFile || path != initPath || content != initContent)
        }
    }
    
    @objc dynamic var pathValid: Bool {
        get {
            if let p = path {
                return FileManager.default.fileExists(atPath: p)
            }
            return false
        }
    }

    @objc dynamic var pathValue: String {
        get {
            if let p = path {
                if !p.isEmpty { return p }
            }
            return "No file selected"
        }
    }

    @objc dynamic var pathColor: NSColor {
        get {
            if pathValid {
                return NSColor.controlTextColor
            }
            else {
                return NSColor.secondaryLabelColor
            }
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let defaultCategory = "Category"
    let defaultMenuTitle = "Title"
    
    @IBOutlet weak var configTableView: NSTableView!
    @IBOutlet weak var modifyConfigArrayButtons: NSSegmentedCell!
    @IBOutlet weak var contextMenu: NSMenu!
    @IBOutlet weak var menuObjectController: NSObjectController!
    
    @IBOutlet weak var actionContentView: NSTextView!
    @IBOutlet weak var configArrayController: NSArrayController!
    @IBOutlet weak var configTestBox: NSBox!
    
    @IBOutlet weak var contextMenuActionTypeComboBox: NSComboBox!
    @IBOutlet weak var contextMenuRemoveButton: NSButton!
    @IBOutlet weak var contextMenuActionSourceFile: NSButton!
    @IBOutlet weak var contextMenuActionSourceContent: NSButton!
    
    @IBOutlet weak var fileSaveMenuItem: NSMenuItem!
    
    var textFieldValueBeforeEdit: String?
    var confirmedExit: Bool = false
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if confirmSaveBeforeExit() {
            return .terminateNow
        }
        else {
            return .terminateCancel
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        actionContentView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        actionContentView.isAutomaticQuoteSubstitutionEnabled = false
        actionContentView.isAutomaticDashSubstitutionEnabled = false
        actionContentView.isRichText = false
        
        contextMenuActionTypeComboBox.removeAllItems()
        contextMenuActionTypeComboBox.addItems(withObjectValues: Menu.validActions)
        
        contextMenuActionSourceContent.wantsLayer = true
        contextMenuActionSourceContent.layer?.borderWidth = 0
        contextMenuActionSourceContent.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        var config = ConfigManager.loadConfigAsArray(includeSystemWide: false)
        if config.isEmpty {
            config = ConfigManager.generateDefault()
            setConfigDirty(isDirty: true)
        }
        else {
            setConfigDirty(isDirty: false)
        }
        configArrayController.content = config
        
        menuObjectController.content = nil
        contextMenuRemoveButton.isEnabled = false
        
        assignContextMenu(menu: nil)
        
        // Show "Extensions Preference" if FinderEx is not enabled yet
        if !FIFinderSyncController.isExtensionEnabled {
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    
    // Give user chance to save config before exit
    // Returns true to continue exiting, false to cancel
    func confirmSaveBeforeExit() -> Bool {
        
        if confirmedExit {
            return true
        }
        
        if !fileSaveMenuItem.isEnabled {
            return true
        }
            
        let alert = NSAlert()
        alert.messageText = "You may have unsaved changes!"
        alert.informativeText = "Do you want to save it before exiting?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Quit without saving")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        let modalResponse = alert.runModal()
        if (modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn) {
            fileSaveAction(self)
            confirmedExit = true
            return true
        }  else if (modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn) {
            confirmedExit = true
            return true
        }
        else {
            return false
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return confirmSaveBeforeExit()
    }
}

// Configuration editor and controller
extension AppDelegate {

    func currentConfig() -> ConfigItem? {
        let config = configArrayController.content as! [ConfigItem]
        if configTableView.selectedRow == -1 {
            return nil
        }
        return config[configTableView.selectedRow]
    }
    
    @IBAction func modifyConfigArray(_ sender: Any) {
        var config = configArrayController.content as! [ConfigItem]
        switch modifyConfigArrayButtons.selectedSegment {
        case 0:
            let newconfig = ConfigItem(name: defaultCategory, type: "", ext: "", allowedit: true)
            config.append(newconfig)
            setConfigDirty(isDirty: true)
        case 1:
            if configTableView.selectedRow == -1 {
                return
            }
            if config[configTableView.selectedRow].allowedit {
                config.remove(at: configTableView.selectedRow)
                setConfigDirty(isDirty: true)
            }
        default:
            break
        }
        configArrayController.content = config
        populateContextMenu()
    }

    @IBAction func configTextFieldCategoryAction(_ sender: Any) {
        guard let textField = sender as? NSTextField else {
            return
        }
        var trimmedValue = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            if let t = textFieldValueBeforeEdit {
                trimmedValue = t
            }
            else {
                trimmedValue = defaultCategory
            }
        }
        textField.stringValue = trimmedValue
        self.populateContextMenu()
        setConfigDirty(isDirty: true)
    }
    
    @IBAction func configTextFieldExtAction(_ sender: Any) {
        self.populateContextMenu()
        setConfigDirty(isDirty: true)
    }
}

// Context menu editor and controller
extension AppDelegate: NSTextViewDelegate, NSMenuDelegate {

    func menuWillOpen(_ menu: NSMenu) {
        if menu == contextMenu {
            
            // Allow if not triggered from config table view
            if configTableView.clickedRow == -1 { return }
            
            // Allow if (right) clicked row is the currently selected row
            if (configTableView.clickedRow == configTableView.selectedRow) { return }
            
            // Disallow by cancelling menu opening
            menu.cancelTrackingWithoutAnimation()
        }
    }
    
    func assignContextMenu(menu: NSMenu?) {
        configTestBox.menu = menu
        configTableView.menu = menu
    }
    
    func populateContextMenu() {
        
        if let config = currentConfig() {
            
            // Remove everything but the last one
            if contextMenu.items.count > 1 {
                for _ in 1...(contextMenu.items.count-1) {
                    contextMenu.removeItem(at: 0)
                }
            }
            
            // Add relevant items
            var i : Int = 0
            for menu in config.menus {
                if menu.valid() {
                    let menuitem = contextMenu.insertItem(withTitle: menu.title!, action: #selector(AppDelegate.contextMenuUserItemAction(sender:)), keyEquivalent: "", at: i)
                    menuitem.target = self
                    i += 1
                }
            }
            
            // Add separator if there was at least one menu item
            if i > 0 {
                let separator = NSMenuItem.separator()
                contextMenu.insertItem(separator, at: i)
            }
            
            assignContextMenu(menu: contextMenu)
        }
        else {
            assignContextMenu(menu: nil)
        }
    }
    
    @objc func contextMenuUserItemAction(sender: NSMenuItem) {
        let i = sender.menu?.index(of: sender)
        if let config = currentConfig() {
            let item = config.menus[i!]
            menuObjectController.content = item.startEditing()
            contextMenuSelectActionSource(fromfile: item.fromfile)
            contextMenuRemoveButton.isEnabled = true
        }
        else {
            menuObjectController.content = nil
            contextMenuRemoveButton.isEnabled = false
        }
    }
    
    @IBAction func contextMenuAddItemAction(_ sender: NSMenuItem) {
        NSLog("add menu item")
        if let config = currentConfig() {
            let newitem = Menu(title: defaultMenuTitle, action: "bash", path: "", content: "", askfolder: false, fromfile: false)
            config.menus.append(newitem)
            menuObjectController.content = newitem.startEditing()
            contextMenuSelectActionSource(fromfile: newitem.fromfile)
            populateContextMenu()
            setConfigDirty(isDirty: true)
            contextMenuRemoveButton.isEnabled = true
        }
    }

    @IBAction func contextMenuRemoveAction(_ sender: Any) {
        if let m = menuObjectController.content as? Menu, let config = currentConfig() {
            for i in 0..<config.menus.count {
                if config.menus[i] == m {
                    config.menus.remove(at: i)
                    populateContextMenu()
                    menuObjectController.content = nil
                    setConfigDirty(isDirty: true)
                    contextMenuRemoveButton.isEnabled = false
                    return
                }
            }
        }
    }

    @IBAction func contextMenuTitleAction(_ sender: Any) {
        guard let textField = sender as? NSTextField else {
            return
        }
        var trimmedValue = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            if let t = textFieldValueBeforeEdit {
                trimmedValue = t
            }
            else {
                trimmedValue = defaultMenuTitle
            }
        }
        textField.stringValue = trimmedValue
        (menuObjectController.content as! Menu).title = trimmedValue
        populateContextMenu()
        setConfigDirty(isDirty: true)
    }
    
    @IBAction func contextMenuAskFolderAction(_ sender: Any) {
        setConfigDirty(isDirty: true)
    }
    
    @IBAction func contextMenuActionAction(_ sender: Any) {
        setConfigDirty(isDirty: true)
    }
    
    private func contextMenuSelectActionSource(fromfile: Bool) {
        contextMenuActionSourceFile.state = fromfile ? .on : .off
        contextMenuActionSourceContent.state = fromfile ? .off : .on
    }
    
    @IBAction func contextMenuActionSourceAction(_ sender: Any) {
        let button = sender as! NSButton
        if button.tag == 0 {
            
            let dialog = NSOpenPanel()

            dialog.title = "Select File"
            dialog.showsResizeIndicator = true
            dialog.showsHiddenFiles = false
            dialog.allowsMultipleSelection = false
            dialog.canChooseDirectories = false

            if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
                let m = menuObjectController.content as! Menu
                if let result = dialog.url {
                    m.path = result.path
                    setConfigDirty(isDirty: true)
                }
                else {
                    m.path = ""
                }
                m.revisitPath()
            }
        }
        else {
            setConfigDirty(isDirty: true)
        }
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        if let m = menuObjectController.content as? Menu {
            m.revisitModified()
            if m.modified {
                setConfigDirty(isDirty: true)
            }
        }
    }
}

extension AppDelegate {
    
    func setConfigDirty(isDirty: Bool) {
        fileSaveMenuItem.isEnabled = isDirty
    }
    
    @IBAction func fileSaveAction(_ sender: Any) {
        let config = configArrayController.content as? [ConfigItem]
        if ConfigManager.saveConfigFromArray(configArray: config) {
            setConfigDirty(isDirty: false)
        }
    }
}

extension AppDelegate : NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.populateContextMenu()
        menuObjectController.content = nil
        contextMenuRemoveButton.isEnabled = false
    }
}

extension AppDelegate : NSTextFieldDelegate {
    
    func controlTextDidBeginEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            textFieldValueBeforeEdit = textField.stringValue
        }
    }
}
