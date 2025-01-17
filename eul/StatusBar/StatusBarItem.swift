//
//  StatusBarItem.swift
//  eul
//
//  Created by Gao Sun on 2020/8/21.
//  Copyright © 2020 Gao Sun. All rights reserved.
//

import Cocoa
import SwiftUI

extension Notification.Name {
    static let StatusBarMenuShouldClose = Notification.Name("StatusBarMenuShouldClose")
}

class StatusBarItem {
    let config: StatusBarConfig
    private let item: NSStatusItem
    private var statusView: NSHostingView<AnyView>?
    private var menuView: NSHostingView<AnyView>?
    private var shouldCloseObserver: NSObjectProtocol?

    var isVisible: Bool {
        get { item.isVisible }
        set { item.isVisible = newValue }
    }

    func onSizeChange(size: CGSize) {
        let width = size.width + (Info.isBigSur ? 8 : 12)

        item.length = width
        statusView?.setFrameSize(NSSize(width: width, height: AppDelegate.statusBarHeight))
    }

    func onMenuSizeChange(size: CGSize) {
        menuView?.setFrameSize(NSSize(width: size.width, height: size.height))
    }

    func refresh() {
        let view = NSHostingView(rootView: config.viewBuilder(onSizeChange))
        view.setFrameSize(NSSize(width: 0, height: AppDelegate.statusBarHeight))
        item.button?.subviews.forEach { $0.removeFromSuperview() }
        item.button?.addSubview(view)
        statusView = view
    }

    init() {
        config = getStatusBarConfig()
        item = NSStatusBar.system.statusItem(withLength: 0)
        item.isVisible = false

        let statusBarMenu = NSMenu()

        if let menuBuilder = config.menuBuilder {
            let customItem = NSMenuItem()
            menuView = StatusBarMenuHostingView(rootView: menuBuilder(onMenuSizeChange))
            customItem.view = menuView
            statusBarMenu.addItem(customItem)
            statusBarMenu.addItem(NSMenuItem.separator())
        }

        item.menu = statusBarMenu

        shouldCloseObserver = NotificationCenter.default.addObserver(forName: .StatusBarMenuShouldClose, object: nil, queue: nil) { _ in
            statusBarMenu.cancelTracking()
        }

        refresh()
    }

    deinit {
        if let observer = shouldCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
