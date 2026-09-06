//
//  ListenerLoadState.swift
//  LocalPackage
//

/// Firestoreスナップショットリスナーの購読状態
public enum ListenerLoadState: Equatable, Sendable {

    case loading
    case loaded
    case failed(DomainError)

}
