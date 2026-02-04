import Foundation

// MARK: - Date Extensions

extension Date {
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isWeekday: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday >= 2 && weekday <= 6
    }

    var isWeekend: Bool { !isWeekday }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    static func hours(_ hours: Double) -> TimeInterval {
        hours * 3600
    }

    static func days(_ days: Int) -> TimeInterval {
        Double(days) * 86400
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - String Extensions

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    func containsAny(_ keywords: [String], caseInsensitive: Bool = true) -> Bool {
        let text = caseInsensitive ? self.lowercased() : self
        return keywords.contains { keyword in
            let k = caseInsensitive ? keyword.lowercased() : keyword
            return text.contains(k)
        }
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    mutating func update(_ element: Element) {
        if let index = firstIndex(where: { $0.id as AnyHashable == element.id as AnyHashable }) {
            self[index] = element
        }
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }
}
