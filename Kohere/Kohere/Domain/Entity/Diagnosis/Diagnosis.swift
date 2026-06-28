//
//  Diagnosis.swift
//  Kohere
//
//  Created by mandoo on 6/26/26.
//

enum SelectType: String {
    case single = "SINGLE"
    case multi = "MULTI"
    case slider = "SLIDER"
}

struct Diagnosis: Equatable {
    let step: Int
    let field: String
    let question: String
    let selectType: SelectType
    let maxSelectCount: Int
    let options: [DiagnosisOption]
}

struct DiagnosisOption: Equatable {
    let code: String
    let label: String
}

extension Diagnosis {
    static let mockDiagnosisList: [Diagnosis] = [
        Diagnosis(
            step: 1,
            field: "region",
            question: "어떤 지역에서 방을 찾으시나요?",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(code: "SEOUL", label: "서울"),
                DiagnosisOption(code: "BUSAN", label: "부산"),
                DiagnosisOption(code: "GYEONGGI", label: "경기")
            ]
        ),
        
        Diagnosis(
            step: 2,
            field: "purpose",
            question: "유학하기 위해 오셨나요?",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(code: "YES", label: "네"),
                DiagnosisOption(code: "NO", label: "아니요")
            ]
        ),
        
        Diagnosis(
            step: 3,
            field: "university",
            question: "다음 중 해당하는 대학을 선택해주세요",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(code: "HUFS", label: "HUFS・KHU・Korea"),
                DiagnosisOption(code: "SKKU", label: "SKKU・Sungshin"),
                DiagnosisOption(code: "SNU", label: "SNU・CAU・Soongsil"),
                DiagnosisOption(code: "Hongik", label: "Hongik・Yonsei・Ewha"),
                DiagnosisOption(code: "Konkuk", label: "Konkuk・Sejong・HYU"),
                DiagnosisOption(code: "ETC", label: "etc")
            ]
        ),
        
        Diagnosis(
            step: 4,
            field: "amenities",
            question: "꼭 필요한 조건 3가지가 무엇인가요?",
            selectType: .multi,
            maxSelectCount: 3,
            options: [
                DiagnosisOption(code: "WOMEN_ONLY", label: "여성전용"),
                DiagnosisOption(code: "ENGLISH", label: "영어 소통 가능"),
                DiagnosisOption(code: "IMMEDIATE", label: "즉시 입주"),
                DiagnosisOption(code: "PRIVATE_BATH", label: "개인 화장실/개인 욕실"),
                DiagnosisOption(code: "REGISTRATION", label: "전입신고 가능"),
                DiagnosisOption(code: "MEALS", label: "식사 제공"),
                DiagnosisOption(code: "NO_MAINTENANCE", label: "관리비 없음"),
                DiagnosisOption(code: "DOUBLE_ROOM", label: "2인실")
            ]
        ),
        
        Diagnosis(
            step: 5,
            field: "budget",
            question: "월세는 어느 정도로 생각하시나요?",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(code: "YES", label: "네"),
                DiagnosisOption(code: "NO", label: "아니요")
            ]
        ),
        
        Diagnosis(
            step: 6,
            field: "arc",
            question: "ARC를 보유하고 있나요?",
            selectType: .single,
            maxSelectCount: 1,
            options: [
                DiagnosisOption(code: "YES", label: "네"),
                DiagnosisOption(code: "NO", label: "아니요")
            ]
        )
    ]
}
