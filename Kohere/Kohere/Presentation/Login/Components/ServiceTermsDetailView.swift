//
//  ServiceTermsDetailView.swift
//  Kohere
//
//  Created by mandoo on 6/19/26.
//

import SwiftUI

struct ServiceTermsDetailView: View {
    
    // MARK: - Properties
    
    let onBackTapped: () -> Void
    let onAgreeTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        TermsDetailView(
            kind: .service,
            onBackTapped: onBackTapped,
            onAgreeTapped: onAgreeTapped
        )
    }
}
