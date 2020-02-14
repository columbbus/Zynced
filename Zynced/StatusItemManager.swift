//
//  StatusItemManager.swift
//  Zynced
//
//  Created by Pascal Braband on 13.02.20.
//  Copyright © 2020 Pascal Braband. All rights reserved.
//

import Cocoa
import BoteCore
import Combine

class StatusItemManager: NSObject {
    
    var statusItem: NSStatusItem?
    var preferencesShown = false
    
    var configManager: ConfigurationManager
    var syncOrchestrator: SyncOrchestrator
    
    var subscriptions = [(AnyCancellable, AnyCancellable)]()
    
    var menu: NSMenu?
    
    let shownItemsCount = 5
    
    
    init(menu: NSMenu?, configManager: ConfigurationManager, syncOrchestrator: SyncOrchestrator) {
        self.configManager = configManager
        self.syncOrchestrator = syncOrchestrator
        
        super.init()
        
        self.menu = menu
        initStatusItem()
    }
    
    
    func initStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Assign status item button image
        let itemImage = NSImage(named: "StatusIcon")
        itemImage?.isTemplate = true
        statusItem?.button?.image = itemImage
        
        // React to menu actions
        if let menu = menu {
            statusItem?.menu = menu
            menu.delegate = self
        }
        
        
        // Setup ConfigurationInfoView's
        
        // Load syncItems and order by status (connected > active > failed > inactive)
        let syncItems = syncOrchestrator.syncItems.sorted { (a, b) -> Bool in
            return a.status > b.status
        }
        
        // Setup ItemInfoView for every given item
        subscriptions.removeAll()
        // Take the first items in the list
        for item in syncItems.prefix(shownItemsCount) {
            // Setup menu items and separator
            let separator = NSMenuItem.separator()
            let menuItem = createMenuItem(for: item)
            
            // Insert menu items at top of menu
            menu?.items.insert(contentsOf: [menuItem, separator], at: 0)
        }
    }
    
    
    func createMenuItem(for item: SyncItem) -> NSMenuItem {
        // Setup ConfigurationInfoView
        let infoView = ConfigurationInfoView(frame: NSRect(x: 0.0, y: 0.0, width: 350.0, height: 58.0))
        infoView.setName(item.configuration.name)
        infoView.setStatus(item.status)
        infoView.setLocation(item.configuration.from.path)
        infoView.setLastSynced(item.lastSynced)
        
        let statusSub = item.$status.sink { (newStatus) in
            infoView.setStatus(newStatus)
        }
        let syncedSub = item.$lastSynced.sink { (newSyncDate) in
            infoView.setLastSynced(newSyncDate)
        }
        subscriptions.append((statusSub, syncedSub))
        
        // Setup menu items and separator
        let menuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menuItem.view = infoView
        
        return menuItem
    }
    
    
    func showPreferences() {
        // Only show preferences if not already displayed
        if !preferencesShown {
            preferencesShown = true
            
            // Instatiate ViewController and set properties
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let vc = storyboard.instantiateController(withIdentifier: .init(stringLiteral: "preferencesID")) as? ViewController else { return }
            vc.configManager = configManager
            vc.syncOrchestrator = syncOrchestrator
            
            // Present window vis ViewController
            let window = NSWindow(contentViewController: vc)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.delegate = self
        }
    }
}



extension StatusItemManager: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        preferencesShown = false
    }
}



extension StatusItemManager: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        // Update something
        // call initStatusItem again
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // Cancel all subscriptions
        for (statusSub, syncedSub) in subscriptions {
            statusSub.cancel()
            syncedSub.cancel()
        }
        subscriptions.removeAll()
    }
}
