//
//  UserResponseDTO.swift
//  Kohere
//
//  Created by Codex on 7/8/26.
//

import Foundation

struct UserNotificationPreferencesResponseDTO: Decodable {
    /// 같은 계정의 모든 기기에 적용되는 서버 채팅 푸시 설정이며, iOS 알림 권한과는 별개다.
    /// 설정 이력이 없으면 서버가 true를 반환한다.
    let chatPushEnabled: Bool
}

struct UserProfileResponseDTO: Decodable {
    let id: Int
    let userType: String
    let name: String?
    let nickname: String?
    let gender: String?
    let birthDate: String?
    let country: String?
    let countryName: String?
    let countryFlag: String?
    let occupation: String?
    let email: String?
    let visaType: String?
    let phoneNumber: String?
    let businessRegistrationNumber: String?
    let status: String
    let termsOfServiceAgreed: Bool
    let privacyPolicyAgreed: Bool
    let marketingAgreed: Bool
    let lang: String?
    let createdAt: String
}
