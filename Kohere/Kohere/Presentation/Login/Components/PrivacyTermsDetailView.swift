//
//  PrivacyTermsDetailView.swift
//  Kohere
//
//  Created by soomin on 6/19/26.
//

import SwiftUI

struct PrivacyTermsDetailView: View {
    
    // MARK: - Properties
    
    let onBackTapped: () -> Void
    let onAgreeTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        TermsDetailView(
            kind: .privacy,
            onBackTapped: onBackTapped,
            onAgreeTapped: onAgreeTapped
        )
    }
}
