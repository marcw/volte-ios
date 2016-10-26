//
//  SendMessageViewController.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import VolteCore

class ComposeMessageView: UIView {

    let contentField: UITextView = {
        let field = UITextView()
        field.font = .systemFont(ofSize: 18)
        field.translatesAutoresizingMaskIntoConstraints = false

        return field
    }()

    let placeholder: UILabel = {
        let placeholder = UILabel()
        placeholder.text = L10n.Timeline.Compose.WhatAreYouUpTo
        placeholder.textColor = .lightGray
        placeholder.font = .systemFont(ofSize: 18)
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.isUserInteractionEnabled = false

        return placeholder
    }()
    init() {
        super.init(frame: .zero)
        contentField.delegate = self
        addSubview(contentField)
        addSubview(placeholder)

        NSLayoutConstraint.activate([
            contentField.topAnchor.constraint(equalTo: topAnchor),
            contentField.leftAnchor.constraint(equalTo: leftAnchor),
            contentField.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentField.rightAnchor.constraint(equalTo: rightAnchor),

            placeholder.topAnchor.constraint(equalTo: topAnchor, constant: 71), // SORRY 🙈
            placeholder.leftAnchor.constraint(equalTo: leftAnchor, constant: 5),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ComposeMessageView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        UIView.animate(withDuration: 0.1) {
            self.placeholder.alpha = textView.text.isEmpty ? 1 : 0
        }
    }
}

class ComposeMessageViewController: UIViewController {

    private let composer: MessageComposer
    
    init(composer: MessageComposer) {
        self.composer = composer
        
        super.init(nibName: nil, bundle: nil)

        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapSend))

        title = L10n.Timeline.Compose.Title
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let composeMessageView = ComposeMessageView()

        self.view = composeMessageView
    }

    func didTapSend() {
        present(LoadingViewController(), animated: true, completion: nil)
        let content = (view as! ComposeMessageView).contentField.text ?? "No content"

        composer
            .sendMessage(with: content)
            .observe(on: UIScheduler())
            .on(completed: { [weak self] in
                self?.dismiss(animated: true) {
                    _ = self?.navigationController?.popViewController(animated: true) // boo.
                }
            })
            .startWithFailed({ [weak self] error in
                let alert = UIAlertController(title: L10n.Compose.Error.Title, message: L10n.Compose.Error.Message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L10n.Alert.Dismiss, style: .default) { [weak self] _ in
                    self?.dismiss(animated: true, completion: nil)
                })

                self?.dismiss(animated: true) {
                    self?.present(alert, animated: true, completion: nil)
                }
            })
    }
}
