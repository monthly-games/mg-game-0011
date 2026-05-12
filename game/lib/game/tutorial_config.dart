import 'package:mg_common_game/systems/tutorial/tutorial.dart';

/// Tutorial configuration for MG-0011: Fairy Forest Healing Idle.
///
/// Placeholder tutorial steps -- replace with localized strings
/// and add targetSelector for highlight positioning in production.
const kOnboardingTutorial = TutorialConfig(
  id: 'onboarding',
  name: 'Fairy Forest Healing Idle Tutorial',
  steps: [
    TutorialStep(
      id: 'tap_area',
      title: '탭하여 자원을 모으세요',
      description: '화면을 탭하여 골드를 획득합니다.',
      targetSelector: 'tap_area',
    ),
    TutorialStep(
      id: 'shop_button',
      title: '첫 업그레이드를 구매하세요',
      description: '상점에서 업그레이드를 구매하여 수입을 늘리세요.',
      targetSelector: 'shop_button',
    ),
    TutorialStep(
      id: 'auto_button',
      title: '자동 수집을 해제하세요',
      description: '자동 수집기를 구매하면 탭 없이도 골드가 쌓입니다.',
      targetSelector: 'auto_button',
    ),
    TutorialStep(
      id: 'prestige_button',
      title: '프레스티지로 성장하세요',
      description: '프레스티지를 통해 영구 보너스를 획득하세요.',
      targetSelector: 'prestige_button',
    ),
  
  ],
  skippable: true,
  showOnFirstLaunch: true,
  trigger: TutorialTrigger.firstLaunch,
);
