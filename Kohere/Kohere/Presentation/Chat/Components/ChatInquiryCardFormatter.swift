import Foundation

struct ChatInquiryCardFormatter {
    let item: ChatInquiryCard
    let language: AppLanguage

    var locationAndType: String {
        [location, listingType].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var monthlyRent: String {
        let minText = wonText(item.monthlyRentMin)
        let amountText = item.monthlyRentMin == item.monthlyRentMax
            ? minText
            : "\(minText) ~ \(wonText(item.monthlyRentMax))"
        return language == .korean ? "월 \(amountText)" : "\(amountText)/mo"
    }

    private var location: String {
        [localizedLocationCode(item.city), localizedLocationCode(item.district)]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var listingType: String {
        switch item.listingType {
        case ListingSearchPropertyType.goshiwon.rawValue:
            language.localizedString(forKey: "map.propertyType.goshiwon")
        case ListingSearchPropertyType.coLiving.rawValue:
            language.localizedString(forKey: "map.propertyType.coLiving")
        case ListingSearchPropertyType.shareHouse.rawValue:
            language.localizedString(forKey: "map.propertyType.shareHouse")
        default:
            readableCode(item.listingType)
        }
    }

    private func localizedLocationCode(_ code: String) -> String {
        if language == .korean, let korean = Self.koreanLocationNames[code] { return korean }
        return readableCode(code)
    }

    private func readableCode(_ code: String) -> String {
        code.lowercased().split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }

    private func wonText(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "₩\(formatter.string(from: NSNumber(value: value)) ?? "\(value)")"
    }

    private static let koreanLocationNames = [
        "SEOUL": "서울",
        "JONGNO_GU": "종로구",
        "JUNG_GU": "중구",
        "YONGSAN_GU": "용산구",
        "SEONGDONG_GU": "성동구",
        "GWANGJIN_GU": "광진구",
        "DONGDAEMUN_GU": "동대문구",
        "JUNGNANG_GU": "중랑구",
        "SEONGBUK_GU": "성북구",
        "GANGBUK_GU": "강북구",
        "DOBONG_GU": "도봉구",
        "NOWON_GU": "노원구",
        "EUNPYEONG_GU": "은평구",
        "SEODAEMUN_GU": "서대문구",
        "MAPO_GU": "마포구",
        "YANGCHEON_GU": "양천구",
        "GANGSEO_GU": "강서구",
        "GURO_GU": "구로구",
        "GEUMCHEON_GU": "금천구",
        "YEONGDEUNGPO_GU": "영등포구",
        "DONGJAK_GU": "동작구",
        "GWANAK_GU": "관악구",
        "SEOCHO_GU": "서초구",
        "GANGNAM_GU": "강남구",
        "SONGPA_GU": "송파구",
        "GANGDONG_GU": "강동구"
    ]
}
