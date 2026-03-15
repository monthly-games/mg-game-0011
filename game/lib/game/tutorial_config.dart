import 'package:mg_common_game/systems/tutorial/tutorial.dart';

/// Tutorial configuration for MG-0011: Fairy Forest Healing Idle.
///
/// Placeholder tutorial steps — replace with localized strings
/// and add targetSelector for highlight positioning in production.
const kOnboardingTutorial = TutorialConfig(
  id: 'onboarding',
  name: 'Fairy Forest Healing Idle Tutorial',
  steps: [
    TutorialStep(
      id: 'welcome',
      title: 'Welcome!',
      description: 'Tap to earn currency and grow.',
      actionHint: 'Tap to continue',
    ),
    TutorialStep(
      id: 'first_tap',
      title: 'Your First Tap',
      description: 'Tap the main button to earn gold.',
      actionHint: 'Tap to earn',
      targetSelector: 'tap_button',
    ),
    TutorialStep(
      id: 'first_upgrade',
      title: 'Upgrade',
      description: 'Spend gold to boost your earnings.',
      actionHint: 'Tap upgrade',
      targetSelector: 'upgrade_button',
    ),
    TutorialStep(
      id: 'idle_earnings',
      title: 'Idle Earnings',
      description: 'You earn gold even while away. Come back often to collect!',
      actionHint: 'Tap to continue',
    ),
  ],
  skippable: true,
  showOnFirstLaunch: true,
  trigger: TutorialTrigger.firstLaunch,
);
