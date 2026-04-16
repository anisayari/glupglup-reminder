import AppKit
import Combine
import SwiftUI

@MainActor
final class HistoryWindowController: NSWindowController {
    private let store: HydrationStore
    private var observer: AnyCancellable?

    init(store: HydrationStore) {
        self.store = store
        let historyView = HydrationHistoryView(store: store)
        let hostingController = NSHostingController(rootView: historyView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = store.strings.historyWindowTitle
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 700, height: 620)
        window.center()
        window.contentViewController = hostingController

        super.init(window: window)
        shouldCascadeWindows = true
        observer = store.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.window?.title = store.strings.historyWindowTitle
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func present() {
        window?.title = store.strings.historyWindowTitle
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
