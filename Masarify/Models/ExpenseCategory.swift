import Foundation

enum ExpenseSource: String, Codable {
    case manual
    case voice
    case receipt

    var labelAr: String {
        localizedLabel(.arabic)
    }

    func localizedLabel(_ language: AppLanguage) -> String {
        switch (self, language) {
        case (.manual, .arabic): return "يدوي"
        case (.manual, .english): return "Manual"
        case (.voice, .arabic): return "صوت"
        case (.voice, .english): return "Voice"
        case (.receipt, .arabic): return "فاتورة"
        case (.receipt, .english): return "Receipt"
        }
    }
}
