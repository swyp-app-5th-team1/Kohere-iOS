//
//  DataError+.swift
//  Kohere
//
//  Created by mandoo on 7/5/26.
//

import Foundation

extension DataError {
    static func from(_ error: Error) -> DataError {
        if let dataError = error as? DataError { return dataError }
        return .underlying(message: error.localizedDescription)
    }
}
