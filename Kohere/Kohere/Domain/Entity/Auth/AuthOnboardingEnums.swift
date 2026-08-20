//
//  AuthOnboardingEnums.swift
//  Kohere
//
//  Created by soomin on 7/4/26.
//

enum Gender: String, Equatable, Codable, Sendable, CaseIterable {
    case male = "MALE"
    case female = "FEMALE"
}

enum Occupation: String, Equatable, Codable, Sendable, CaseIterable {
    case undergraduateStudent = "UNDERGRADUATE_STUDENT"
    case graduateStudent = "GRADUATE_STUDENT"
    case exchangeStudent = "EXCHANGE_STUDENT"
    case languageTeaching = "LANGUAGE_TEACHING"
    case manufacturingProduction = "MANUFACTURING_PRODUCTION"
    case businessTrade = "BUSINESS_TRADE"
    case etc = "ETC"
}

enum VisaType: String, Equatable, Codable, Sendable, CaseIterable {
    case shortTermVisit = "SHORT_TERM_VISIT"
    case studentsTrainees = "STUDENTS_TRAINEES"
    case nonProfessionalWorkers = "NON_PROFESSIONAL_WORKERS"
    case workingHolidayWorkAndVisit = "WORKING_HOLIDAY_WORK_AND_VISIT"
    case overseasKoreans = "OVERSEAS_KOREANS"
    case familyMarriageMigrants = "FAMILY_MARRIAGE_MIGRANTS"
    case permanentResidents = "PERMANENT_RESIDENTS"
    case professionals = "PROFESSIONALS"
    case diplomaticOfficialAndOthers = "DIPLOMATIC_OFFICIAL_AND_OTHERS"
    case etc = "ETC"
}
