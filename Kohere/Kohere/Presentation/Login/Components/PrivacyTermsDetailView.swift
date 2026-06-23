//
//  PrivacyTermsDetailView.swift
//  Kohere
//
//  Created by mandoo on 6/19/26.
//

import SwiftUI

struct PrivacyTermsDetailView: View {
    
    // MARK: - Properties
    
    let onAgreeTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        TermsDetailView(
            kind: .privacy,
            onAgreeTapped: onAgreeTapped
        )
    }
}
