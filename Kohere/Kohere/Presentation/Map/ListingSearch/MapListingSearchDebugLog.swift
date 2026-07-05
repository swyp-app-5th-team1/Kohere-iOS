//
//  MapListingSearchDebugLog.swift
//  Kohere
//
//  Created by Codex on 7/6/26.
//

import Foundation
import OSLog

nonisolated func debugLogListingSearchRequest(_ input: ListingSearchInput) {
#if DEBUG
    let logger = Logger(subsystem: "Kohere", category: "MapListingSearch")
    logger.debug("request: \(String(describing: input), privacy: .public)")
#endif
}

nonisolated func debugLogListingSearchResponse(_ page: ListingSearchPage) {
#if DEBUG
    let logger = Logger(subsystem: "Kohere", category: "MapListingSearch")
    logger.debug("response: \(String(describing: page), privacy: .public)")
#endif
}

nonisolated func debugLogListingSearchError(_ error: Error) {
#if DEBUG
    let logger = Logger(subsystem: "Kohere", category: "MapListingSearch")
    logger.error("request failed: \(error.localizedDescription, privacy: .public)")
#endif
}
