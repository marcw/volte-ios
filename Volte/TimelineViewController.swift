//
//  TimelineViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-11.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import CryptoSwift

protocol TimelineViewModelType {
    var messages: MutableProperty<[Item]> { get }
}

class TimelineViewModel {
    var messages = MutableProperty<[Item]>([])
}

class TimelineViewController: UIViewController {
    fileprivate let provider: TimelineContentProvider

    private let viewModel = TimelineViewModel()
    private let account: Account

    init(provider: TimelineContentProvider, account: Account) {
        self.provider = provider
        self.account = account

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapCompose))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let timelineView = TimelineView(viewModel: viewModel)
        timelineView.delegate = self

        self.view = timelineView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchMessages()
    }

    func fetchMessages() {
        provider
            .fetchItems()
            .collect()
            .observe(on: UIScheduler())
            .startWithResult { [weak self] (result) in
                if let messages = result.value {
                    // TODO use RAC binding but I don't remember how it works
                    self?.viewModel.messages.value = messages
                } else if let error = result.error {
                    // TODO: Present error
                    print("Error = \(error)")
                }
        }
    }
}

extension TimelineViewController: TimelineViewDelegate {
    func didPullToRefresh() {
        fetchMessages()
    }

    func didTapCompose() {
        let composer = MessageComposer(account: account)
        let viewController = SendMessageViewController(composer: composer)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
