//
//  ProxyListViewController.swift
//  Potatso
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Cartography
import Eureka

private let rowHeight: CGFloat = 107
private let kProxyCellIdentifier = "proxy"

// MARK: shadowsock代理选择页面。

class ProxyListViewController: FormViewController {

    var proxies: [Proxy?] = []
    let allowNone: Bool
    let chooseCallback: (Proxy? -> Void)?

    init(allowNone: Bool = false, chooseCallback: (Proxy? -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
        super.init(style: .Plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Proxy".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(add))
        reloadData()
    }

    func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    func reloadData() {
        proxies = defaultRealm.objects(Proxy).sorted("createAt").map({ $0 })
        if allowNone {
            proxies.insert(nil, atIndex: 0)
        }
        form.delegate = nil
        form.removeAll()
        let section = Section()
        for proxy in proxies {
            section
                <<< ProxyRow () {
                    $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .None
                }).onCellSelection({ [unowned self] (cell, row) in
                    cell.setSelected(false, animated: true)
                    let proxy = row.value
                    if let cb = self.chooseCallback {
                        cb(proxy)
                        self.close()
                    }else {
                        if proxy?.type != .None {
                            self.showProxyConfiguration(proxy)
                        }
                    }
                })
        }
        form +++ section
        form.delegate = self
        tableView?.reloadData()
    }

    func showProxyConfiguration(proxy: Proxy?) {
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if allowNone && indexPath.row == 0 {
            return false
        }
        return true
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard indexPath.row < proxies.count, let item = (form[indexPath] as? ProxyRow)?.value else {
                return
            }
            do {
                proxies.removeAtIndex(indexPath.row)
                try defaultRealm.write {
                    defaultRealm.delete(item)
                }
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.tableFooterView = UIView()
        tableView?.tableHeaderView = UIView()
    }

}
