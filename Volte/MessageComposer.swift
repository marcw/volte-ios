//
//  MessageComposer.swift
//  Volte
//
//  Created by Romain Pouclet on 2016-10-12.
//  Copyright © 2016 Perfectly-Cooked. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

class MessageComposer {
    enum ComposingError: Error {
        case internalError(Error)
    }

    private let session: MCOSMTPSession = {
        let session = MCOSMTPSession()
        session.hostname = "voltenetwork.xyz"
        session.port = 587
        session.connectionType = .startTLS

        return session
    }()

    private let account: Account

    init(account: Account) {
        self.account = account

        session.username = account.username;
        session.password = account.password;
    }
    func sendMessage(with content: String) -> SignalProducer<String, ComposingError> {
        return fetchBetaTesters()
            .promoteErrors(ComposingError.self)
            .flatMap(.latest, transform: { (senders) -> SignalProducer<String, ComposingError> in
                return self.sendMessage(with: content, to: senders)
            })
    }
    func sendMessage(with content: String, to recipients: [MCOAddress]) -> SignalProducer<String, ComposingError> {
        return SignalProducer { sink, disposable in
            let builder = MCOMessageBuilder()
            builder.header.from = MCOAddress(mailbox: self.account.username)
            builder.header.to = recipients
            builder.header.subject = "Coucou"

            builder.textBody = content
            let payload: [String: Any] = [
                "@context": "http://schema.org",
                "@type": "SocialMediaPosting",
                "@id": UUID().uuidString,
                "datePublished": "\(Date())",
                "text": content
            ]

            let attachment = MCOAttachment(rfc822Message: try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted))!
            attachment.mimeType = "application/ld+json"
            builder.addAttachment(attachment)

            let operation = self.session.sendOperation(with: builder.data())
            operation?.start { (error) in
                print("Send error = \(error)")
                if let error = error {
                    sink.send(error: .internalError(error))
                } else {
                    sink.send(value: "Yay")
                    sink.sendCompleted()
                }
            }
            disposable.add {
                operation?.cancel()
            }
        }
    }

    func fetchBetaTesters() -> SignalProducer<[MCOAddress], NoError> {
        return SignalProducer { sink, _ in
            let testersURL = Bundle.main.url(forResource: "testers", withExtension: "json")!
            let content = try! Data(contentsOf: testersURL)
            let testers = try! JSONSerialization.jsonObject(with: content, options: .allowFragments) as! [String]
            print("Testers = \(testers)")
            sink.send(value: testers.map { MCOAddress(mailbox: $0)})
            sink.sendCompleted()
        }
    }
}
