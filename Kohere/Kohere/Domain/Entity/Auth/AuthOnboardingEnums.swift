//
//  AuthOnboardingEnums.swift
//  Kohere
//
//  Created by mandoo on 7/4/26.
//

enum Gender: String, Equatable, Codable, Sendable, CaseIterable {
    case male = "MALE"
    case female = "FEMALE"
}

enum Occupation: String, Equatable, Codable, Sendable, CaseIterable {
    case undergraduateStudent = "UNDERGRADUATE_STUDENT"
    case graduateStudent = "GRADUATE_STUDENT"
    case exchangeStudent = "EXCHANGE_STUDENT"
    case educationAcademicResearch = "EDUCATION_ACADEMIC_RESEARCH"
    case itSoftwareEngineering = "IT_SOFTWARE_ENGINEERING"
    case developer = "DEVELOPER"
    case designer = "DESIGNER"
}

enum VisaType: String, Equatable, Codable, Sendable, CaseIterable {
    case diplomaticOfficial = "DIPLOMATIC_OFFICIAL_A-1_A-2"
    case visaExempted = "VISA_EXEMPTED_B"
    case journalismReligiousAffairs = "JOURNALISM_RELIGIOUS_AFFAIRS_C-1_D-5_D-6"
    case shortTermVisit = "SHORT_TERM_VISIT_C-2_C-3"
    case study = "STUDY_D-2"
    case trainee = "TRAINEE_D-3_D-4"
    case intraCompanyTransfer = "INTRA_COMPANY_TRANSFER_D-7"
    case professional = "PROFESSIONAL_C-4_D-1_D-8_D-9_D-10_E-1_E-2_E-3_E-4_E-5_E-6_E-7"
    case nonProfessional = "NON_PROFESSIONAL_E-8_E-9_E-10"
    case workingHoliday = "WORKING_HOLIDAY_H-1"
    case workAndVisit = "WORK_AND_VISIT_H-2"
    case familyVisitorDependent = "FAMILY_VISITOR_DEPENDENT_F-1_F-2_F-3"
    case overseasKorean = "OVERSEAS_KOREAN_F-4"
    case permanentResidence = "PERMANENT_RESIDENCE_F-5"
    case marriageMigrant = "MARRIAGE_MIGRANT_F-6"
    case others = "OTHERS_G-1"
}
