import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let store: HydrationStore
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let historyWindowController: HistoryWindowController

    private var animationTimer: Timer?
    private var frameIndex = 0
    private var storeObserver: AnyCancellable?

    init(store: HydrationStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.historyWindowController = HistoryWindowController(store: store)

        super.init()

        configureStatusItem()
        configurePopover()
        observeStore()
        startAnimation()
        updateStatusItem()
    }

    deinit {
        animationTimer?.invalidate()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.toolTip = store.strings.statusTooltip
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 470)
        popover.contentViewController = NSHostingController(
            rootView: HydrationPopoverView(
                store: store,
                onOpenHistory: { [weak self] in
                    self?.openHistory()
                },
                onQuit: { NSApp.terminate(nil) }
            )
        )
    }

    private func observeStore() {
        storeObserver = store.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateStatusItem()
            }
        }
    }

    private func startAnimation() {
        animationTimer?.invalidate()

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.28, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else {
                    return
                }

                self.frameIndex = (self.frameIndex + 1) % DropletStatusIcon.frameCount
                self.updateStatusItem()
            }
        }

        if let animationTimer {
            RunLoop.main.add(animationTimer, forMode: .common)
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = store.statusTitle
        button.image = DropletStatusIcon.image(frameIndex: frameIndex, goalReached: store.goalReachedToday)
        button.setAccessibilityLabel("GlupGlup Reminder \(store.statusTitle)")
        button.toolTip = store.strings.statusTooltip
    }

    @objc
    private func handleStatusItemClick(_ sender: Any?) {
        let event = NSApp.currentEvent
        let isContextClick = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true

        if isContextClick {
            togglePopover()
            return
        }

        if event?.modifierFlags.contains(.option) == true {
            if popover.isShown {
                popover.performClose(sender)
            }
            WaterSoundPlayer.shared.playDrop()
            store.removeGlass()
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        }

        WaterSoundPlayer.shared.playDrop()
        store.addGlass()
    }

    private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(button)
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func openHistory() {
        if popover.isShown {
            popover.performClose(nil)
        }

        historyWindowController.present()
    }
}
