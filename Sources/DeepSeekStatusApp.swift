import SwiftUI
import AppKit
import Combine

@main
struct DeepSeekStatusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar only: no Settings or WindowGroup scenes to prevent ghost windows
        #if os(macOS)
        _EmptyScene()
        #endif
    }
}

// Minimal empty scene preventing macOS from registering a Settings window or shortcut
struct _EmptyScene: Scene {
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commandsRemoved()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private let scheduleManager = ScheduleManager()
    private let pricingManager = PricingManager()
    private let balanceManager = BalanceManager()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Close any windows macOS tries to open on launch (e.g. settings/blank windows)
        for window in NSApplication.shared.windows {
            window.close()
        }
        
        // Enable standard keyboard shortcuts (Cmd+V, Cmd+C, Cmd+A, Cmd+Z) in popover text fields
        setupMainMenuShortcuts()
        
        // Configure NSStatusItem in macOS menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateStatusItemIcon()
        }
        
        // Observe schedule changes to update the menu bar icon color dynamically
        scheduleManager.$isOffPeak
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemIcon()
            }
            .store(in: &cancellables)
    }
    
    private func setupMainMenuShortcuts() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        mainMenu.addItem(editMenuItem)
        mainMenu.setSubmenu(editMenu, for: editMenuItem)
        NSApplication.shared.mainMenu = mainMenu
    }
    
    private func updateStatusItemIcon() {
        guard let button = statusItem.button else { return }
        
        let isOffPeak = scheduleManager.isOffPeak
        let iconImage = DeepSeekWhaleLogo.generateImage(isOffPeak: isOffPeak, size: 22)
        
        button.image = iconImage
        button.imagePosition = .imageOnly
        button.toolTip = "DeepSeek API: \(scheduleManager.currentStatusText)\n\(scheduleManager.nextTransitionText)"
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if let pop = popover, pop.isShown {
            pop.performClose(nil)
            return
        }
        
        // Update data right before presenting
        scheduleManager.updateSchedule()
        if balanceManager.hasApiKey {
            balanceManager.fetchBalance()
        }
        
        // Lazy build popover so SwiftUI view hierarchy and window surfaces are created on demand
        let pop = NSPopover()
        let popoverHeight: CGFloat = balanceManager.hasApiKey ? 495 : 445
        pop.contentSize = NSSize(width: 380, height: popoverHeight)
        pop.behavior = .transient
        pop.animates = false
        pop.delegate = self
        pop.contentViewController = NSHostingController(
            rootView: PopoverContentView(
                schedule: scheduleManager,
                pricing: pricingManager,
                balance: balanceManager
            )
        )
        
        self.popover = pop
        pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        pop.contentViewController?.view.window?.makeKey()
    }
    
    func popoverDidClose(_ notification: Notification) {
        // Release hosting controller and window memory when user dismisses the popover
        popover = nil
    }
}
