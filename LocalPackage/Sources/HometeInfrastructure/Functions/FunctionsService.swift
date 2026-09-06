//
//  FunctionsService.swift
//

import FirebaseFunctions

public enum FunctionsService {

    public static func call(_ name: String, parameters: Any? = nil) async throws -> HTTPSCallableResult {
        try await Functions.functions(region: FunctionsRegion.homete)
            .httpsCallable(name)
            .call(parameters)
    }

}
