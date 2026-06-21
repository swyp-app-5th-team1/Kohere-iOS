//
//  MarketingTermsDetailView.swift
//  Kohere
//
//  Created by Codex on 6/21/26.
//

import SwiftUI

struct MarketingTermsDetailView: View {
    
    // MARK: - Properties
    
    let onAgreeTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        TermsDetailView(
            kind: .marketing,
            onAgreeTapped: onAgreeTapped
        )
    }
}
