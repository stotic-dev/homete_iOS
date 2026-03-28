//
//  FirestoreListenerStorerable.swift
//

import FirebaseFirestore

protocol FirestoreListenerStorerable<Element> {

    associatedtype Element
    var continuation: AsyncStream<Element>.Continuation { get }
    var listener: any ListenerRegistration { get }
    func remove()
}

struct FirestoreListener<Element>: FirestoreListenerStorerable {

    let continuation: AsyncStream<Element>.Continuation
    let listener: any ListenerRegistration

    func remove() {

        continuation.finish()
        listener.remove()
    }
}
