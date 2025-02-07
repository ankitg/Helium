//
//  AppDelegate.swift
//  Helium
//
//  Created by Jaden Geller on 4/9/15.
//  Copyright (c) 2015 Jaden Geller. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    @IBOutlet weak var magicURLMenu: NSMenuItem!
    @IBOutlet weak var percentageMenu: NSMenuItem!
    @IBOutlet weak var fullScreenFloatMenu: NSMenuItem!
    @IBOutlet weak var hideTitleBarMenu: NSMenuItem!
    @IBOutlet weak var translucencyEnabled: NSMenuItem!
    @IBOutlet weak var translucencyAlways: NSMenuItem!
    @IBOutlet weak var translucencyMouseOver: NSMenuItem!
    @IBOutlet weak var translucencyMouseOutside: NSMenuItem!

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(AppDelegate.handleURLEvent(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func magicURLRedirectToggled(_ sender: NSMenuItem) {
        sender.state = (sender.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        UserDefaults.standard.set((sender.state == NSControl.StateValue.off), forKey: UserSetting.disabledMagicURLs.userDefaultsKey)
    }
    
    
    //MARK: - handleURLEvent
    // Called when the App opened via URL.
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        
        guard let keyDirectObject = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)), let urlString = keyDirectObject.stringValue,
            let url : String = urlString.substring(from: urlString.index(urlString.startIndex, offsetBy: 9)),
            let urlObject = URL(string:url) else {
            
                return print("No valid URL to handle")
                
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "HeliumLoadURL"), object: urlObject)
        
    }
}

