import Foundation

/// Mental Load Automation Skill - Briefings, reminders, weekly planning
final class MentalLoadSkill {
    private let weatherAPI = WeatherAPI()
    private let persistence = PersistenceController.shared
    private let logger = AppLogger.shared

    // Skills references for cross-skill integration
    private let mealPlanning = MealPlanningSkill()
    private let education = EducationSkill()
    private let elderCare = ElderCareSkill()
    private let familyCoordination = FamilyCoordinationSkill()
    private let homeMaintenance = HomeMaintenanceSkill()

    // MARK: - Morning Briefing

    func generateMorningBriefing(family: Family) async -> MorningBriefing {
        logger.info("Generating morning briefing for \(family.name)")

        // Weather
        let weather = await getWeatherSummary(city: family.preferences.homeCity)

        // Calendar
        let events = await familyCoordination.getUpcomingEvents(family: family, daysAhead: 1)
        let todayEvents = events.filter { $0.startTime.isToday }

        // Urgent tasks
        var urgentTasks: [TaskItem] = []

        // Check overdue assignments
        let assignments = await education.getUpcomingAssignments(family: family)
        let dueTodayOrOverdue = assignments.filter { $0.dueDate.isToday || $0.dueDate < Date() }
        for assignment in dueTodayOrOverdue {
            urgentTasks.append(TaskItem(
                title: "\(assignment.title) due \(assignment.dueDate.isToday ? "today" : "overdue")",
                skill: .education,
                priority: .high,
                dueDate: assignment.dueDate
            ))
        }

        // Check maintenance tasks
        let maintenanceTasks = homeMaintenance.getMaintenanceSchedule(family: family)
        let overdueMaintenance = maintenanceTasks.filter { $0.nextDue < Date() && !$0.isCompleted }
        for task in overdueMaintenance {
            urgentTasks.append(TaskItem(
                title: task.title,
                skill: .homeMaintenance,
                priority: task.priority,
                dueDate: task.nextDue
            ))
        }

        // Today's meal
        let mealPlans: [MealPlan] = persistence.loadData(type: "meal_plan")
        let todayMeal = mealPlans.first?.meals.first { Calendar.current.isDate($0.date, inSameDayAs: Date()) }

        // Reminders
        var reminders: [String] = []
        if !todayEvents.isEmpty {
            reminders.append("\(todayEvents.count) event(s) today")
        }
        if let meal = todayMeal {
            reminders.append("Tonight's dinner: \(meal.recipe.title)")
        }

        let motivationalNotes = [
            "You're doing great! Take it one step at a time.",
            "Remember to take a few minutes for yourself today.",
            "Small wins add up. Celebrate the little things!",
            "You've got this. Your family is lucky to have you.",
            "Focus on what matters most. The rest can wait."
        ]

        return MorningBriefing(
            date: Date(),
            weather: weather,
            calendarHighlights: todayEvents,
            urgentTasks: urgentTasks.sorted { $0.priority > $1.priority },
            mealPlanToday: todayMeal,
            reminders: reminders,
            motivationalNote: motivationalNotes.randomElement()
        )
    }

    // MARK: - Evening Wind-Down

    func generateEveningWindDown(family: Family) async -> EveningWindDown {
        // Tomorrow's priorities
        var tomorrowPriorities: [TaskItem] = []

        let assignments = await education.getUpcomingAssignments(family: family)
        let dueTomorrow = assignments.filter { $0.dueDate.isTomorrow }
        for assignment in dueTomorrow {
            tomorrowPriorities.append(TaskItem(
                title: assignment.title,
                skill: .education,
                priority: .high,
                dueDate: assignment.dueDate
            ))
        }

        let events = await familyCoordination.getUpcomingEvents(family: family, daysAhead: 1)
        let tomorrowEvents = events.filter { $0.startTime.isTomorrow }
        for event in tomorrowEvents {
            tomorrowPriorities.append(TaskItem(
                title: event.title,
                skill: .familyCoordination,
                priority: .medium,
                dueDate: event.startTime
            ))
        }

        // Tomorrow's meal
        let mealPlans: [MealPlan] = persistence.loadData(type: "meal_plan")
        let tomorrowMeal = mealPlans.first?.meals.first { $0.date.isTomorrow }

        let suggestions = [
            "Pack lunches tonight to save time in the morning",
            "Set out clothes for tomorrow",
            "Review tomorrow's schedule",
            "Check that backpacks are packed",
            "Make sure devices are charging"
        ]

        let reflectionPrompts = [
            "What went well today?",
            "What's one thing you're grateful for?",
            "What would you do differently tomorrow?",
            "What made your family smile today?"
        ]

        return EveningWindDown(
            date: Date(),
            completedTasks: [], // Would track throughout the day
            tomorrowPriorities: tomorrowPriorities,
            tomorrowMeal: tomorrowMeal,
            suggestions: Array(suggestions.prefix(3)),
            reflectionPrompt: reflectionPrompts.randomElement()
        )
    }

    // MARK: - Weekly Planning

    func generateWeeklyPlan(family: Family) async -> WeeklyPlan {
        let events = await familyCoordination.getUpcomingEvents(family: family, daysAhead: 7)
        let chores = familyCoordination.getChores(family: family)
        let maintenanceTasks = homeMaintenance.getMaintenanceSchedule(family: family)

        // Detect schedule conflicts
        let conflicts = familyCoordination.detectConflicts(events: events)

        // Generate reminders
        var reminders: [ProactiveReminder] = []

        // Appointment reminders
        for event in events {
            reminders.append(ProactiveReminder(
                title: event.title,
                message: "\(event.title) is coming up on \(event.startTime.dayOfWeek)",
                triggerDate: event.startTime.addingDays(-1),
                skill: .familyCoordination,
                priority: .medium,
                actionable: true,
                actionLabel: "View Details"
            ))
        }

        // Maintenance reminders
        for task in maintenanceTasks.filter({ $0.nextDue <= Date().addingDays(7) }) {
            reminders.append(ProactiveReminder(
                title: task.title,
                message: "\(task.title) is due \(task.nextDue.relativeString)",
                triggerDate: task.nextDue.addingDays(-1),
                skill: .homeMaintenance,
                priority: task.priority
            ))
        }

        // Get or generate meal plan
        let mealPlans: [MealPlan] = persistence.loadData(type: "meal_plan")

        return WeeklyPlan(
            weekStartDate: Date().startOfWeek,
            calendarEvents: events,
            mealPlan: mealPlans.first,
            chores: chores,
            appointments: [], // Would integrate with healthcare
            reminders: reminders.sorted { $0.triggerDate < $1.triggerDate },
            conflicts: conflicts
        )
    }

    // MARK: - Formatting

    func formatBriefing(_ briefing: MorningBriefing) -> String {
        var text = ""

        if let weather = briefing.weather {
            text += "**Weather:** \(weather.description) (\(Int(weather.temperatureHigh))F high / \(Int(weather.temperatureLow))F low)"
            if weather.precipitation { text += " - Rain expected!" }
            text += "\n\n"
        }

        if !briefing.calendarHighlights.isEmpty {
            text += "**Today's Schedule:**\n"
            for event in briefing.calendarHighlights {
                text += "- \(event.startTime.timeString): \(event.title)\n"
            }
            text += "\n"
        }

        if !briefing.urgentTasks.isEmpty {
            text += "**Needs Attention:**\n"
            for task in briefing.urgentTasks {
                text += "- [\(task.skill.rawValue)] \(task.title)\n"
            }
            text += "\n"
        }

        if let meal = briefing.mealPlanToday {
            text += "**Tonight's Dinner:** \(meal.recipe.title) (\(meal.recipe.totalTime) min)\n\n"
        }

        if let note = briefing.motivationalNote {
            text += "_\(note)_"
        }

        return text
    }

    func formatWindDown(_ windDown: EveningWindDown) -> String {
        var text = ""

        if !windDown.tomorrowPriorities.isEmpty {
            text += "**Tomorrow's Priorities:**\n"
            for task in windDown.tomorrowPriorities {
                text += "- \(task.title)"
                if let due = task.dueDate { text += " (due \(due.timeString))" }
                text += "\n"
            }
            text += "\n"
        }

        if let meal = windDown.tomorrowMeal {
            text += "**Tomorrow's Dinner:** \(meal.recipe.title)\n\n"
        }

        if !windDown.suggestions.isEmpty {
            text += "**Evening Suggestions:**\n"
            for suggestion in windDown.suggestions {
                text += "- \(suggestion)\n"
            }
            text += "\n"
        }

        if let prompt = windDown.reflectionPrompt {
            text += "_Reflection: \(prompt)_"
        }

        return text
    }

    // MARK: - Helpers

    private func getWeatherSummary(city: String?) async -> WeatherSummary? {
        guard let city = city else { return nil }

        do {
            let forecasts = try await weatherAPI.getForecast(city: city)
            return forecasts.first
        } catch {
            logger.warning("Weather fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
}
