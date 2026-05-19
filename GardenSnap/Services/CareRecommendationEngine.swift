import Foundation

struct CareRecommendationEngine {
    func recommendations(
        for plant: PlantInstance,
        forecast: [DailyWeather],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> [CareRecommendation] {
        [
            wateringRecommendation(for: plant, forecast: forecast, today: today, calendar: calendar),
            fertilizingRecommendation(for: plant, today: today, calendar: calendar),
            pruningRecommendation(for: plant, today: today, calendar: calendar),
            inspectionRecommendation(for: plant, today: today)
        ]
        .compactMap { $0 }
        .sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return lhs.priority > rhs.priority
            }
            return lhs.dueDate < rhs.dueDate
        }
    }

    private func wateringRecommendation(
        for plant: PlantInstance,
        forecast: [DailyWeather],
        today: Date,
        calendar: Calendar
    ) -> CareRecommendation {
        let interval = adjustedWateringInterval(for: plant, forecast: forecast)
        let lastWatered = plant.lastWatered ?? plant.dateAdded
        let initialDueDate = calendar.date(byAdding: .day, value: interval, to: lastWatered) ?? today
        let rainSoon = soakingRainSoon(in: forecast, today: today, calendar: calendar)

        let dueDate: Date
        let detail: String
        if let rainSoon, plant.setting != .indoor, plant.setting != .container, initialDueDate <= calendar.date(byAdding: .day, value: 1, to: today) ?? today {
            dueDate = calendar.date(byAdding: .day, value: 1, to: rainSoon.date) ?? rainSoon.date
            detail = "Rain is expected soon, so watering can wait unless the soil is already dry."
        } else {
            dueDate = initialDueDate
            detail = wateringDetail(
                for: plant,
                interval: interval,
                forecast: forecast,
                today: today,
                calendar: calendar
            )
        }

        return CareRecommendation(
            action: .water,
            status: status(for: dueDate, today: today, calendar: calendar),
            title: "Water \(plant.nickname)",
            detail: detail,
            dueDate: dueDate,
            priority: priority(for: dueDate, today: today, calendar: calendar, base: 90)
        )
    }

    private func fertilizingRecommendation(
        for plant: PlantInstance,
        today: Date,
        calendar: Calendar
    ) -> CareRecommendation {
        let lastFertilized = plant.lastFertilized ?? plant.dateAdded
        var dueDate = calendar.date(
            byAdding: .day,
            value: plant.species.fertilizeEveryDays,
            to: lastFertilized
        ) ?? today
        var detail = "Last fertilized \(relativeDate(lastFertilized, today: today)). Use the plant profile interval as the baseline."

        if let lastPruned = plant.lastPruned,
           daysSince(lastPruned, today: today, calendar: calendar) <= 10,
           dueDate <= (calendar.date(byAdding: .day, value: 2, to: today) ?? today) {
            dueDate = calendar.date(byAdding: .day, value: 10, to: lastPruned) ?? dueDate
            detail = "Recent pruning is logged, so hold fertilizer briefly while the plant rebounds."
        }

        return CareRecommendation(
            action: .fertilize,
            status: status(for: dueDate, today: today, calendar: calendar),
            title: "Fertilize \(plant.nickname)",
            detail: detail,
            dueDate: dueDate,
            priority: priority(for: dueDate, today: today, calendar: calendar, base: 55)
        )
    }

    private func pruningRecommendation(
        for plant: PlantInstance,
        today: Date,
        calendar: Calendar
    ) -> CareRecommendation? {
        let month = calendar.component(.month, from: today)
        guard plant.species.pruneWindowMonths.contains(month) else {
            return nil
        }

        let lastPruned = plant.lastPruned ?? plant.dateAdded
        let dueDate = calendar.date(byAdding: .day, value: 45, to: lastPruned) ?? today

        return CareRecommendation(
            action: .prune,
            status: status(for: dueDate, today: today, calendar: calendar),
            title: "Check pruning on \(plant.nickname)",
            detail: "This is a normal pruning window for \(plant.species.commonName). Last pruned \(relativeDate(lastPruned, today: today)).",
            dueDate: dueDate,
            priority: priority(for: dueDate, today: today, calendar: calendar, base: 65)
        )
    }

    private func inspectionRecommendation(for plant: PlantInstance, today: Date) -> CareRecommendation? {
        guard let note = plant.healthNotes.sorted(by: { $0.date > $1.date }).first(where: { $0.severity != .none }) else {
            return nil
        }

        if let lastInspected = plant.lastInspected, lastInspected >= note.date {
            return nil
        }

        return CareRecommendation(
            action: .inspect,
            status: note.severity == .action ? .dueNow : .dueSoon,
            title: "Inspect \(plant.nickname)",
            detail: "\(note.title): \(note.detail)",
            dueDate: today,
            priority: note.severity == .action ? 100 : 80
        )
    }

    private func adjustedWateringInterval(for plant: PlantInstance, forecast: [DailyWeather]) -> Int {
        var interval = plant.species.averageWateringDays

        switch plant.setting {
        case .container:
            interval -= 2
        case .raisedBed:
            interval -= 1
        case .gardenBed:
            break
        case .indoor:
            interval += 2
        }

        switch plant.sunExposure {
        case .fullSun:
            interval -= 1
        case .partSun:
            break
        case .shade:
            interval += 1
        }

        if forecast.prefix(3).contains(where: { $0.highFahrenheit >= 90 || $0.humidity < 0.40 || $0.windMph >= 13 }) {
            interval -= 1
        }

        if forecast.prefix(3).contains(where: { $0.precipitationInches >= 0.25 }) && plant.setting != .indoor && plant.setting != .container {
            interval += plant.species.overwateringSensitivity >= 0.45 ? 2 : 1
        }

        if plant.species.droughtTolerance >= 0.7 {
            interval += 2
        } else if plant.species.droughtTolerance <= 0.2 {
            interval -= 1
        }

        return min(max(interval, 1), 21)
    }

    private func soakingRainSoon(
        in forecast: [DailyWeather],
        today: Date,
        calendar: Calendar
    ) -> DailyWeather? {
        let windowEnd = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        return forecast.first { weather in
            weather.date >= calendar.startOfDay(for: today)
                && weather.date <= windowEnd
                && weather.isSoakingRain
        }
    }

    private func wateringDetail(
        for plant: PlantInstance,
        interval: Int,
        forecast: [DailyWeather],
        today: Date,
        calendar: Calendar
    ) -> String {
        let hotSoon = forecast.prefix(3).contains { $0.highFahrenheit >= 90 }
        let rainSoon = forecast.prefix(3).contains { $0.precipitationInches >= 0.25 }

        if let lastPruned = plant.lastPruned,
           daysSince(lastPruned, today: today, calendar: calendar) <= 7 {
            return "Recent pruning is logged, so check soil before soaking. The current target is about every \(interval) day(s)."
        }

        if hotSoon {
            return "Heat is coming, so the interval tightened to about every \(interval) day(s). Check soil before soaking."
        }

        if rainSoon && plant.setting != .indoor {
            return "Rain is in the forecast, so the interval was relaxed to about every \(interval) day(s)."
        }

        return "Based on species, setting, sun, and recent care, aim for about every \(interval) day(s)."
    }

    private func status(for dueDate: Date, today: Date, calendar: Calendar) -> CareStatus {
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDueDate = calendar.startOfDay(for: dueDate)
        let daysUntilDue = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0

        if daysUntilDue <= 0 {
            return .dueNow
        }

        if daysUntilDue <= 2 {
            return .dueSoon
        }

        return .scheduled
    }

    private func priority(for dueDate: Date, today: Date, calendar: Calendar, base: Int) -> Int {
        let startOfToday = calendar.startOfDay(for: today)
        let startOfDueDate = calendar.startOfDay(for: dueDate)
        let daysUntilDue = calendar.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0
        return max(1, min(100, base - max(daysUntilDue, 0) * 7))
    }

    private func relativeDate(_ date: Date, today: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: today)
    }

    private func daysSince(_ date: Date, today: Date, calendar: Calendar) -> Int {
        let startOfDate = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: today)
        return calendar.dateComponents([.day], from: startOfDate, to: startOfToday).day ?? 0
    }
}
