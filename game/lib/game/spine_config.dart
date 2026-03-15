import 'package:mg_common_game/core/assets/asset_types.dart';

/// Spine 통합 플래그. `--dart-define=SPINE_ENABLED=true`로 활성화.
const kSpineEnabled = bool.fromEnvironment(
  'SPINE_ENABLED',
  defaultValue: false,
);

// ── Fairy Healer ─────────────────────────────────────────────

const kFairyHealerMeta = SpineAssetMeta(
  key: 'fairy_healer',
  path: 'spine/characters/fairy_healer',
  atlasPath: 'assets/spine/characters/fairy_healer/fairy_healer.atlas',
  skeletonPath:
      'assets/spine/characters/fairy_healer/fairy_healer.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Forest Spirit ────────────────────────────────────────────

const kForestSpiritMeta = SpineAssetMeta(
  key: 'forest_spirit',
  path: 'spine/characters/forest_spirit',
  atlasPath:
      'assets/spine/characters/forest_spirit/forest_spirit.atlas',
  skeletonPath:
      'assets/spine/characters/forest_spirit/forest_spirit.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);

// ── Woodland Sprite ──────────────────────────────────────────

const kWoodlandSpriteMeta = SpineAssetMeta(
  key: 'woodland_sprite',
  path: 'spine/characters/woodland_sprite',
  atlasPath:
      'assets/spine/characters/woodland_sprite/woodland_sprite.atlas',
  skeletonPath:
      'assets/spine/characters/woodland_sprite/woodland_sprite.json',
  animations: ['idle', 'walk', 'attack', 'hit'],
  defaultAnimation: 'idle',
  defaultMix: 0.2,
);
