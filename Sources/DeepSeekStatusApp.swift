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
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Close any windows macOS tries to open on launch (e.g. settings/blank windows)
        for window in NSApplication.shared.windows {
            window.close()
        }
        
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
        
        // Lazy build popover so SwiftUI view hierarchy and window surfaces are created on demand
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 380, height: 370)
        pop.behavior = .transient
        pop.animates = false
        pop.delegate = self
        pop.contentViewController = NSHostingController(
            rootView: PopoverContentView(
                schedule: scheduleManager,
                pricing: pricingManager
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
