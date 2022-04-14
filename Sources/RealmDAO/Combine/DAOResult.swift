//
//  DAOResult.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation

public enum DAOResult<T, E: Error>: Equatable {
    case idle
    case loading
    case error(E)
    case success(T)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return false
    }
}
