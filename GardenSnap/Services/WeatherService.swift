import Foundation

protocol WeatherProvider {
    func forecast(for coordinate: GardenCoordinate?) async throws -> [DailyWeather]
}

final class DemoWeatherProvider: WeatherProvider {
    func forecast(for coordinate: GardenCoordinate?) async throws -> [DailyWeather] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }

            return DailyWeather(
                date: date,
                highFahrenheit: offset == 2 ? 92 : 78 + Double(offset % 3) * 4,
                lowFahrenheit: 61 + Double(offset % 2) * 3,
                precipitationInches: offset == 1 ? 0.45 : (offset == 4 ? 0.18 : 0.0),
                humidity: offset == 2 ? 0.38 : 0.58,
                windMph: offset == 2 ? 14 : 7,
                condition: offset == 1 ? "Rain" : "Partly cloudy"
            )
        }
    }
}
