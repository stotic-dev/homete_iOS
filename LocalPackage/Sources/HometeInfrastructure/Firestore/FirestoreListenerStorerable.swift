//
//  FirestoreListenerStorerable.swift
//

import FirebaseFirestore

protocol FirestoreListenerStorerable<Element> {

    associatedtype Element
    var continuation: AsyncThrowingStream<Element, Error>.Continuation { get }
    var listener: any ListenerRegistration { get }
    func remove()

}

struct FirestoreListener<Element>: FirestoreListenerStorerable {

    let continuation: AsyncThrowingStream<Element, Error>.Continuation
    let listener: any ListenerRegistration

    func remove() {
        continuation.finish()
        listener.remove()
    }

}
