//
//  RealmDAOError.swift
//  RealmDAO
//
//  Created by Brian Thomas on 4/14/22.
//

import Foundation

public enum RealmDAOError: Error {
    case unavailable
    case indexOutOfOrder
    case insertingOldObject
    case unknown
}
