//
//  HeliumPanelController.swift
//  Helium
//
//  Created by Jaden Geller on 4/9/15.
//  Copyright (c) 2015 Jaden Geller. All rights reserved.
//

import AppKit

let optionKeyCode: UInt16 = 58

// editable NSTextField
class Editing: NSTextField {
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue &
                NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

class HeliumPanelController : NSWindowController {
    var isFullScreen = false
    var backupFrame : NSRect = NSRect.zero

    let userDefaults = UserDefaults.standard
    
    private var webViewController: WebViewController {
        return self.window?.contentViewController as! WebViewController
    }

    private var heliumPanel: HeliumPanel {
        return self.panel as! HeliumPanel
    }

    private var mouseOver: Bool = false
    
    private var alpha: CGFloat = 0.6 { //default
        didSet {
            updateTranslucency()
        }
    }

    private var translucencyPreference: TranslucencyPreference = .always {
        didSet {
            updateTranslucency()
        }
    }

    private var translucencyEnabled: Bool = false {
        didSet {
            updateTranslucency()
        }
    }

    private enum TranslucencyPreference: String {
        case always
        case mouseOver
        case mouseOutside
    }

    private var currentlyTranslucent: Bool = false {
        didSet {
            if !NSApplication.shared.isActive {
                panel.ignoresMouseEvents = currentlyTranslucent
            }
            if currentlyTranslucent {
                panel.animator().alphaValue = alpha
                panel.isOpaque = false
            }
            else {
                panel.isOpaque = true
                panel.animator().alphaValue = 1
            }
        }
    }

    private var panel: NSPanel! {
        get {
            return (self.window as! NSPanel)
        }
    }

    // MARK: Window lifecycle
    override func windowDidLoad() {
        panel.isFloatingPanel = true

        let _ = AppleMediaKeyController.init()
        let app = NSApplication.shared.delegate as! AppDelegate

        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.didBecomeActive), name:
            NSApplication.didBecomeActiveNotification , object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.willResignActive), name: NSApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.didUpdateTitle(_:)), name: NSNotification.Name(rawValue: "HeliumUpdateTitle"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.playPauseNotification(_:)), name: Notification.Name.MediaKeyPlayPause, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.seekBackwardNotification(_:)), name: Notification.Name.MediaKeyPrevious, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HeliumPanelController.seekForwardNotification(_:)), name: Notification.Name.MediaKeyNext, object: nil)

        self.setupTitleVisibility()
        setFloatOverFullScreenApps()

        let pref = TranslucencyPreference(rawValue: userDefaults.string(forKey: UserSetting.translucencyPreference.userDefaultsKey) ?? "always")!
        if userDefaults.bool(forKey: UserSetting.translucencyEnabled.userDefaultsKey) {
            didEnableTranslucency()
            app.translucencyEnabled.state = NSControl.StateValue.on
        } else {
            didDisableTranslucency()
            app.translucencyEnabled.state = NSControl.StateValue.off
        }
        
        switch pref {
        case TranslucencyPreference.mouseOver:
            app.translucencyMouseOver.state = NSControl.StateValue.on
        case TranslucencyPreference.mouseOutside:
            app.translucencyMouseOutside.state = NSControl.StateValue.on
        case TranslucencyPreference.always:
            app.translucencyAlways.state = NSControl.StateValue.on
        }
        translucencyPreference = pref

        app.magicURLMenu.state = userDefaults.bool(forKey: UserSetting.disabledMagicURLs.userDefaultsKey) ? NSControl.StateValue.off : NSControl.StateValue.on
        app.fullScreenFloatMenu.state = userDefaults.bool(forKey: UserSetting.disabledFullScreenFloat.userDefaultsKey) ? NSControl.StateValue.off : NSControl.StateValue.on
        app.hideTitleBarMenu.state = userDefaults.bool(forKey: UserSetting.hideTitle.userDefaultsKey) ? NSControl.StateValue.on : NSControl.StateValue.off
        
        if let alpha = userDefaults.object(forKey: UserSetting.opacityPercentage.userDefaultsKey) {
            didUpdateAlpha(CGFloat(alpha as! Int))
            let offset = (alpha as! Int)/10 - 1
            for (index, button) in app.percentageMenu.submenu!.items.enumerated() {
                (button ).state = (offset == index) ? NSControl.StateValue.on : NSControl.StateValue.off
            }
        }
        
        self.windowFrameAutosaveName = "position"
    }

    // MARK : Mouse events
    override func mouseEntered(with theEvent: NSEvent) {
        mouseOver = true
        updateTranslucency()
    }

    override func mouseExited(with theEvent: NSEvent) {
        mouseOver = false
        updateTranslucency()
    }

    // MARK: media keys
    @objc func playPauseNotification(_ notification: Notification) {
        self.heliumPanel.fireControlEvent(of: .playpause)
    }

    @objc func seekForwardNotification(_ notification: Notification) {
        self.heliumPanel.fireControlEvent(of: .right)
    }

    @objc func seekBackwardNotification(_ notification: Notification) {
        self.heliumPanel.fireControlEvent(of: .left)
    }

    // MARK : Translucency
    private func updateTranslucency() {
        currentlyTranslucent = shouldBeTranslucent()
        userDefaults.set(translucencyPreference.rawValue, forKey: UserSetting.translucencyPreference.userDefaultsKey)
        userDefaults.set(translucencyEnabled, forKey: UserSetting.translucencyEnabled.userDefaultsKey)
    }

    private func shouldBeTranslucent() -> Bool {
        /* Implicit Arguments
         * - mouseOver
         * - translucencyPreference
         * - tranlucencyEnalbed
         */

        guard translucencyEnabled else { return false }

        switch translucencyPreference {
        case .always:
            return true
        case .mouseOver:
            return mouseOver
        case .mouseOutside:
            return !mouseOver
        }
    }

    private func setFloatOverFullScreenApps() {
        if userDefaults.bool(forKey: UserSetting.disabledFullScreenFloat.userDefaultsKey) {
            panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]

        } else {
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        }
    }

    //MARK: IBActions
    private func disabledAllMouseOverPreferences(_ allMenus: [NSMenuItem]) {
        // GROSS HARD CODED
        for x in allMenus.dropFirst(2) {
            x.state = NSControl.StateValue.off
        }
    }

    @IBAction private func alwaysPreferencePress(_ sender: NSMenuItem) {
        disabledAllMouseOverPreferences(sender.menu!.items)
        translucencyPreference = .always
        sender.state = NSControl.StateValue.on
    }
    
    @IBAction private func overPreferencePress(_ sender: NSMenuItem) {
        disabledAllMouseOverPreferences(sender.menu!.items)
        translucencyPreference = .mouseOver
        sender.state = NSControl.StateValue.on
    }

    @IBAction private func outsidePreferencePress(_ sender: NSMenuItem) {
        disabledAllMouseOverPreferences(sender.menu!.items)
        translucencyPreference = .mouseOutside
        sender.state = NSControl.StateValue.on
    }

    @IBAction private func translucencyPress(_ sender: NSMenuItem) {
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
            didDisableTranslucency()
        }
        else {
            sender.state = NSControl.StateValue.on
            didEnableTranslucency()
        }
    }

    @IBAction private func percentagePress(_ sender: NSMenuItem) {
        for button in sender.menu!.items{
            (button ).state = NSControl.StateValue.off
        }
        sender.state = NSControl.StateValue.on
        let value = sender.title.substring(to: sender.title.index(sender.title.endIndex, offsetBy: -1))
        if let alpha = Int(value) {
             didUpdateAlpha(CGFloat(alpha))
             userDefaults.set(alpha, forKey: UserSetting.opacityPercentage.userDefaultsKey)
        }
    }

    @IBAction private func openLocationPress(_ sender: AnyObject) {
        didRequestLocation()
    }

    @IBAction private func openFilePress(_ sender: AnyObject) {
        didRequestFile()
    }

    @IBAction private func openClipboard(_ sender: AnyObject) {
        didRequestClipboard()
    }

    @IBAction private func floatOverFullScreenAppsToggled(_ sender: NSMenuItem) {
        sender.state = (sender.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        userDefaults.set((sender.state == NSControl.StateValue.off), forKey: UserSetting.disabledFullScreenFloat.userDefaultsKey)

        setFloatOverFullScreenApps()
    }

    @IBAction private func hideTitle(_ sender: NSMenuItem) {
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
        } else {
            sender.state = NSControl.StateValue.on
        }

        userDefaults.set(sender.state, forKey: UserSetting.hideTitle.userDefaultsKey)
        self.setupTitleVisibility()
    }

    @IBAction private func openFullScreen(_ sender: NSMenuItem) {
        NSLog("Fatal Error: Event Tap could not be created");
        if let screen = window?.screen ?? NSScreen.main {
            self.isFullScreen = !self.isFullScreen
            if self.isFullScreen {
                self.backupFrame = (window?.frame)!
                window?.setFrame(screen.visibleFrame, display: true, animate: true)
            } else {
                window?.setFrame(self.backupFrame, display: true, animate: true)
            }
        }
    }

    @IBAction func activateByWindowToggled(_ sender: NSMenuItem) {
        sender.state = (sender.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        userDefaults.set((sender.state == NSControl.StateValue.on), forKey: UserSetting.activateByWindow.userDefaultsKey)
        self.setupTitleVisibility()
    }

    private func setupTitleVisibility() {
        let hideTitle = userDefaults.bool(forKey: UserSetting.hideTitle.userDefaultsKey)
        let activate = userDefaults.bool(forKey: UserSetting.activateByWindow.userDefaultsKey)

        if !hideTitle {
            panel.styleMask = [NSPanel.StyleMask.titled, NSPanel.StyleMask.hudWindow, NSPanel.StyleMask.utilityWindow, NSPanel.StyleMask.resizable, ]
            panel.title = self.webViewController.webView.title ?? ""
        } else {
            panel.styleMask = [NSPanel.StyleMask.borderless, NSPanel.StyleMask.resizable, ]
        }

        if !activate {
            panel.styleMask.insert(NSPanel.StyleMask.nonactivatingPanel)
        }
    }

    @IBAction func setHomePage(_ sender: AnyObject){
        didRequestChangeHomepage()
    }

    //MARK: Actual functionality
    @objc private func didUpdateTitle(_ notification: Notification) {
        if let title = notification.object as? String {
            panel.title = title
        }
    }

    private func didRequestFile() {
        let open = NSOpenPanel()
        open.allowsMultipleSelection = false
        open.canChooseFiles = true
        open.canChooseDirectories = false
        
        if open.runModal() == NSApplication.ModalResponse.OK {
            if let url = open.url {
                webViewController.loadURL(url)
            }
        }
    }

    private func didRequestLocation() {
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.messageText = "Enter Destination URL"

        let urlField = Editing()
        urlField.frame = NSRect(x: 0, y: 0, width: 300, height: 20)
        urlField.lineBreakMode = NSLineBreakMode.byTruncatingHead
        urlField.usesSingleLineMode = true
        // Load from URL before
        var savedUrl = self.userDefaults.string(forKey: "saveURL")
        if savedUrl == nil {
            // default
            savedUrl = self.webViewController.webView.url?.absoluteString ?? ""
        }
        urlField.stringValue = savedUrl!

        alert.accessoryView = urlField
        alert.addButton(withTitle: "Load")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: self.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                // Load
                let text = (alert.accessoryView as! NSTextField).stringValue
                self.saveURL(text: text)
                self.webViewController.loadAlmostURL(text)
            }
        })
        urlField.becomeFirstResponder()
    }

    private func saveURL(text:String) {
        self.userDefaults.set(text, forKey:"saveURL")
        self.userDefaults.synchronize()
    }

    private func didRequestClipboard() {
        if let contents = NSPasteboard.general.string(forType: NSPasteboard.PasteboardType.string) {
            self.saveURL(text: contents)
            self.webViewController.loadAlmostURL(contents)
        }
    }

    func didRequestChangeHomepage(){
        let alert = NSAlert()
        alert.alertStyle = NSAlert.Style.informational
        alert.messageText = "Enter new Homepage URL"

        let urlField = Editing()
        urlField.frame = NSRect(x: 0, y: 0, width: 300, height: 20)
        urlField.lineBreakMode = NSLineBreakMode.byTruncatingHead
        urlField.usesSingleLineMode = true

        alert.accessoryView = urlField
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: self.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                var text = (alert.accessoryView as! NSTextField).stringValue

                // Add prefix if necessary
                if !(text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")) {
                    text = "http://" + text
                }

                // Save to defaults if valid. Else, use Helium default page
                if self.validateURL(text) {
                    self.userDefaults.set(text, forKey: UserSetting.homePageURL.userDefaultsKey)
                }
                else{
                    self.userDefaults.set("https://ankitg.github.io/Helium/helium_start.html", forKey: UserSetting.homePageURL.userDefaultsKey)
                }

                // Load new Home page
                self.webViewController.loadAlmostURL(self.userDefaults.string(forKey: UserSetting.homePageURL.userDefaultsKey)!)
            }
        })
        urlField.becomeFirstResponder()
    }

    func validateURL (_ stringURL : String) -> Bool {
        
        let urlRegEx = "((https|http)://)((\\w|-)+)(([.]|[/])((\\w|-)+))+"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[urlRegEx])
        
        return predicate.evaluate(with: stringURL)
    }

    @objc private func didBecomeActive() {
        panel.ignoresMouseEvents = false
    }

    @objc private func willResignActive() {
        if currentlyTranslucent {
            panel.ignoresMouseEvents = true
        }
    }

    private func didEnableTranslucency() {
        translucencyEnabled = true
    }

    private func didDisableTranslucency() {
        translucencyEnabled = false
    }

    private func didUpdateAlpha(_ newAlpha: CGFloat) {
        alpha = newAlpha / 100
    }
}
