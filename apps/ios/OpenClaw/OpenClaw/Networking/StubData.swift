import Foundation

// MARK: - Stub Recipe Data

enum StubRecipeData {
    static let sampleRecipes: [Recipe] = [
        Recipe(title: "Lemon Herb Chicken", description: "A zesty weeknight chicken dish", cuisine: "American",
               prepTime: 10, cookTime: 20, totalTime: 30, servings: 4,
               ingredients: [
                   Ingredient(name: "Chicken breast", amount: 4, unit: "pieces", category: .meat),
                   Ingredient(name: "Lemon", amount: 2, unit: "whole", category: .produce),
                   Ingredient(name: "Olive oil", amount: 2, unit: "tbsp", category: .condiments),
                   Ingredient(name: "Garlic", amount: 3, unit: "cloves", category: .produce),
                   Ingredient(name: "Fresh rosemary", amount: 2, unit: "sprigs", category: .produce)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Season chicken with salt and pepper"), InstructionStep(stepNumber: 2, text: "Heat oil in skillet over medium-high heat"), InstructionStep(stepNumber: 3, text: "Cook chicken 6-7 minutes per side"), InstructionStep(stepNumber: 4, text: "Add lemon juice and herbs, serve")],
               isVegetarian: false, isDairyFree: true, primaryProtein: .chicken, tags: ["quick", "healthy"]),

        Recipe(title: "Pasta Primavera", description: "Fresh vegetable pasta with light sauce", cuisine: "Italian",
               prepTime: 10, cookTime: 15, totalTime: 25, servings: 4,
               ingredients: [
                   Ingredient(name: "Penne pasta", amount: 1, unit: "lb", category: .pantry),
                   Ingredient(name: "Bell peppers", amount: 2, unit: "whole", category: .produce),
                   Ingredient(name: "Zucchini", amount: 1, unit: "whole", category: .produce),
                   Ingredient(name: "Cherry tomatoes", amount: 1, unit: "cup", category: .produce),
                   Ingredient(name: "Parmesan cheese", amount: 0.5, unit: "cup", category: .dairy)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Cook pasta according to package"), InstructionStep(stepNumber: 2, text: "Saute vegetables in olive oil"), InstructionStep(stepNumber: 3, text: "Toss pasta with vegetables and parmesan")],
               isVegetarian: true, primaryProtein: .vegetarian, tags: ["vegetarian", "quick"]),

        Recipe(title: "Beef Tacos", description: "Classic family-friendly tacos", cuisine: "Mexican",
               prepTime: 10, cookTime: 15, totalTime: 25, servings: 4,
               ingredients: [
                   Ingredient(name: "Ground beef", amount: 1, unit: "lb", category: .meat),
                   Ingredient(name: "Taco shells", amount: 12, unit: "shells", category: .pantry),
                   Ingredient(name: "Lettuce", amount: 1, unit: "head", category: .produce),
                   Ingredient(name: "Tomatoes", amount: 2, unit: "whole", category: .produce),
                   Ingredient(name: "Shredded cheese", amount: 1, unit: "cup", category: .dairy)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Brown ground beef with taco seasoning"), InstructionStep(stepNumber: 2, text: "Warm taco shells"), InstructionStep(stepNumber: 3, text: "Assemble with toppings")],
               primaryProtein: .beef, tags: ["family", "quick"]),

        Recipe(title: "Salmon with Rice", description: "Healthy baked salmon with steamed rice", cuisine: "Asian",
               prepTime: 5, cookTime: 20, totalTime: 25, servings: 4,
               ingredients: [
                   Ingredient(name: "Salmon fillets", amount: 4, unit: "pieces", category: .meat),
                   Ingredient(name: "Rice", amount: 2, unit: "cups", category: .pantry),
                   Ingredient(name: "Soy sauce", amount: 2, unit: "tbsp", category: .condiments),
                   Ingredient(name: "Ginger", amount: 1, unit: "tbsp", category: .produce),
                   Ingredient(name: "Broccoli", amount: 2, unit: "cups", category: .produce)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Season salmon with soy sauce and ginger"), InstructionStep(stepNumber: 2, text: "Bake at 400F for 15 minutes"), InstructionStep(stepNumber: 3, text: "Serve with steamed rice and broccoli")],
               isGlutenFree: true, isDairyFree: true, primaryProtein: .seafood, tags: ["healthy", "quick"]),

        Recipe(title: "Vegetarian Chili", description: "Hearty bean chili with cornbread", cuisine: "American",
               prepTime: 10, cookTime: 30, totalTime: 40, servings: 6,
               ingredients: [
                   Ingredient(name: "Black beans", amount: 2, unit: "cans", category: .pantry),
                   Ingredient(name: "Kidney beans", amount: 1, unit: "can", category: .pantry),
                   Ingredient(name: "Diced tomatoes", amount: 2, unit: "cans", category: .pantry),
                   Ingredient(name: "Onion", amount: 1, unit: "whole", category: .produce),
                   Ingredient(name: "Chili powder", amount: 2, unit: "tbsp", category: .condiments)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Saute onion until soft"), InstructionStep(stepNumber: 2, text: "Add beans, tomatoes, and spices"), InstructionStep(stepNumber: 3, text: "Simmer for 30 minutes")],
               isVegetarian: true, isVegan: true, isGlutenFree: true, isDairyFree: true, primaryProtein: .vegan, tags: ["comfort", "budget"]),

        Recipe(title: "Chicken Stir Fry", description: "Quick Asian-inspired stir fry", cuisine: "Chinese",
               prepTime: 10, cookTime: 10, totalTime: 20, servings: 4,
               ingredients: [
                   Ingredient(name: "Chicken breast", amount: 1, unit: "lb", category: .meat),
                   Ingredient(name: "Mixed vegetables", amount: 3, unit: "cups", category: .produce),
                   Ingredient(name: "Soy sauce", amount: 3, unit: "tbsp", category: .condiments),
                   Ingredient(name: "Rice", amount: 2, unit: "cups", category: .pantry)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Slice chicken into strips"), InstructionStep(stepNumber: 2, text: "Stir fry chicken until cooked"), InstructionStep(stepNumber: 3, text: "Add vegetables and sauce, cook 5 minutes")],
               isDairyFree: true, primaryProtein: .chicken, tags: ["quick", "healthy"]),

        Recipe(title: "Black Bean Burritos", description: "Easy meatless Monday option", cuisine: "Mexican",
               prepTime: 10, cookTime: 10, totalTime: 20, servings: 4,
               ingredients: [
                   Ingredient(name: "Flour tortillas", amount: 4, unit: "large", category: .bakery),
                   Ingredient(name: "Black beans", amount: 1, unit: "can", category: .pantry),
                   Ingredient(name: "Rice", amount: 1, unit: "cup", category: .pantry),
                   Ingredient(name: "Salsa", amount: 0.5, unit: "cup", category: .condiments),
                   Ingredient(name: "Avocado", amount: 1, unit: "whole", category: .produce)
               ],
               instructions: [InstructionStep(stepNumber: 1, text: "Heat beans and rice"), InstructionStep(stepNumber: 2, text: "Warm tortillas"), InstructionStep(stepNumber: 3, text: "Assemble burritos with toppings")],
               isVegetarian: true, isDairyFree: true, primaryProtein: .vegetarian, tags: ["budget", "quick"])
    ]
}

// MARK: - Stub Calendar Data

enum StubCalendarData {
    static var sampleEvents: [CalendarEvent] {
        let now = Date()
        return [
            CalendarEvent(title: "Team Meeting", startTime: now.addingHours(2), endTime: now.addingHours(3), memberName: "Parent"),
            CalendarEvent(title: "Soccer Practice", startTime: now.addingDays(1).addingHours(6), endTime: now.addingDays(1).addingHours(7), memberName: "Child"),
            CalendarEvent(title: "Piano Lesson", startTime: now.addingDays(2).addingHours(4), endTime: now.addingDays(2).addingHours(5), memberName: "Child"),
            CalendarEvent(title: "Doctor Appointment", startTime: now.addingDays(3).addingHours(2), endTime: now.addingDays(3).addingHours(3), memberName: "Parent"),
            CalendarEvent(title: "Grocery Shopping", startTime: now.addingDays(4).addingHours(1), endTime: now.addingDays(4).addingHours(2), memberName: "Parent")
        ]
    }
}

// MARK: - Stub Education Data

enum StubEducationData {
    static let sampleCourses: [ClassroomCourse] = [
        ClassroomCourse(id: "course_1", name: "5th Grade Math", section: "Section A", room: "Room 201", ownerId: nil, courseState: "ACTIVE"),
        ClassroomCourse(id: "course_2", name: "5th Grade Science", section: "Section B", room: "Room 105", ownerId: nil, courseState: "ACTIVE"),
        ClassroomCourse(id: "course_3", name: "5th Grade English", section: "Section A", room: "Room 301", ownerId: nil, courseState: "ACTIVE")
    ]

    static let sampleCourseWork: [ClassroomCourseWork] = [
        ClassroomCourseWork(id: "cw_1", courseId: "course_1", title: "Math Worksheet Ch 5", description: "Complete problems 1-20", maxPoints: 100, dueDate: ClassroomDate(year: 2026, month: 2, day: 5), dueTime: ClassroomTimeOfDay(hours: 23, minutes: 59), workType: "ASSIGNMENT"),
        ClassroomCourseWork(id: "cw_2", courseId: "course_2", title: "Science Lab Report", description: "Write up the plant growth experiment", maxPoints: 50, dueDate: ClassroomDate(year: 2026, month: 2, day: 7), dueTime: ClassroomTimeOfDay(hours: 23, minutes: 59), workType: "ASSIGNMENT")
    ]

    static func sampleAssignments(for studentId: UUID) -> [Assignment] {
        let now = Date()
        return [
            Assignment(studentId: studentId, title: "Math Worksheet Ch 5", subject: "Math", dueDate: now.addingDays(2), status: .pending, estimatedTime: 30, priority: .medium, points: nil, maxPoints: 100),
            Assignment(studentId: studentId, title: "Science Lab Report", subject: "Science", dueDate: now.addingDays(4), status: .pending, estimatedTime: 45, priority: .high, points: nil, maxPoints: 50),
            Assignment(studentId: studentId, title: "Reading Log", subject: "English", dueDate: now.addingDays(1), status: .inProgress, estimatedTime: 20, priority: .medium),
            Assignment(studentId: studentId, title: "History Essay Draft", subject: "History", dueDate: now.addingDays(6), status: .pending, estimatedTime: 60, priority: .high)
        ]
    }

    static func sampleGrades(for studentId: UUID) -> [GradeEntry] {
        [
            GradeEntry(studentId: studentId, subject: "Math", grade: 88, date: Date().addingDays(-7), type: .assignment),
            GradeEntry(studentId: studentId, subject: "Science", grade: 92, date: Date().addingDays(-5), type: .quiz),
            GradeEntry(studentId: studentId, subject: "English", grade: 85, date: Date().addingDays(-3), type: .assignment),
            GradeEntry(studentId: studentId, subject: "History", grade: 78, date: Date().addingDays(-1), type: .test)
        ]
    }
}

// MARK: - Stub Contractor Data

enum StubContractorData {
    static func sampleProviders(for query: String) -> [ServiceProvider] {
        let type = inferType(query)
        return [
            ServiceProvider(name: "A+ \(type.rawValue) Services", serviceType: type, phone: "(555) 100-0001", address: "123 Main St", rating: 4.8, reviewCount: 156, source: "Stub"),
            ServiceProvider(name: "Quick Fix \(type.rawValue)", serviceType: type, phone: "(555) 100-0002", address: "456 Oak Ave", rating: 4.5, reviewCount: 89, source: "Stub"),
            ServiceProvider(name: "Reliable \(type.rawValue) Co", serviceType: type, phone: "(555) 100-0003", address: "789 Elm Dr", rating: 4.2, reviewCount: 203, source: "Stub")
        ]
    }

    private static func inferType(_ query: String) -> ServiceType {
        let lower = query.lowercased()
        for type in ServiceType.allCases {
            if lower.contains(type.rawValue.lowercased()) { return type }
        }
        return .general
    }
}
