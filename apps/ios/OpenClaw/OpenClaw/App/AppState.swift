import SwiftUI
import Combine

/// Central application state manager
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isOnboardingComplete: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentFamily: Family?
    @Published var activeSkills: Set<SkillType> = []
    @Published var errorMessage: String?

    // MARK: - Services
    let modelManager: ModelManager
    let keychainManager: KeychainManager
    let networkMonitor: NetworkMonitor
    let logger: AppLogger
    let skillOrchestrator: SkillOrchestrator

    // MARK: - Init
    init() {
        self.keychainManager = KeychainManager()
        self.networkMonitor = NetworkMonitor()
        self.logger = AppLogger.shared
        self.modelManager = ModelManager()
        self.skillOrchestrator = SkillOrchestrator()
    }

    // MARK: - Initialization
    func initialize() async {
        logger.info("Initializing OpenClaw app...")

        // Check onboarding status
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")

        // Load family data
        if isOnboardingComplete {
            await loadFamilyData()
        }

        // Initialize model manager (stub mode)
        do {
            try await modelManager.initialize()
            isModelLoaded = true
        } catch {
            logger.error("Model initialization failed: \(error.localizedDescription)")
            // Graceful degradation - app works without AI
            isModelLoaded = false
        }

        // Start network monitor
        networkMonitor.start()

        // Initialize skill orchestrator
        skillOrchestrator.configure(
            modelManager: modelManager,
            networkMonitor: networkMonitor
        )

        isLoading = false
        logger.info("OpenClaw initialization complete")
    }

    func completeOnboarding(family: Family, skills: Set<SkillType>) {
        self.currentFamily = family
        self.activeSkills = skills
        self.isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboarding_complete")

        // Save family to Core Data
        PersistenceController.shared.saveFamily(family)

        logger.info("Onboarding completed for family: \(family.name)")
    }

    private func loadFamilyData() async {
        if let family = PersistenceController.shared.loadFamily() {
            self.currentFamily = family
            let skillNames = UserDefaults.standard.stringArray(forKey: "active_skills") ?? []
            self.activeSkills = Set(skillNames.compactMap { SkillType(rawValue: $0) })
        }
    }
}
