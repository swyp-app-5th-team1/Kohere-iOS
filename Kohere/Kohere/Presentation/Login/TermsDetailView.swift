//
//  TermsDetailView.swift
//  Kohere
//
//  Created by Codex on 6/21/26.
//

import SwiftUI

enum TermsDetailKind: String, Identifiable {
    case service
    case privacy
    case marketing
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .service:
            "서비스 이용약관"
        case .privacy:
            "개인정보처리방침"
        case .marketing:
            "마케팅 커뮤니케이션"
        }
    }
    
    var content: String {
        switch self {
        case .service:
            """
            서비스 이용약관 내용이 들어갈 예정입니다.
            """
        case .privacy:
            """
            개인정보처리방침 내용이 들어갈 예정입니다.
            """
        case .marketing:
            """
            마케팅 커뮤니케이션 동의 내용이 들어갈 예정입니다.
            """
        }
    }
}

struct TermsDetailView: View {
    
    // MARK: - Properties
    
    let kind: TermsDetailKind
    let onAgreeTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Divider()
                    .background(.lineNeutral)
                
                ScrollView {
                    Text(kind.content)
                        .kohereTextStyle(.label3Medium)
                        .foregroundColor(.neutral60)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                }
                
                Divider()
                    .background(.lineNeutral)
                
                Button {
                    onAgreeTapped()
                } label: {
                    Text("Agree")
                        .kohereTextStyle(.label1Semibold)
                        .foregroundColor(.staticWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.primaryNormal)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }
}
