/// 가챠 시스템 어댑터 - MG-0011 Idle Forest
library;

import 'package:flutter/foundation.dart';
import 'package:mg_common_game/systems/gacha/gacha_pool.dart';
import 'package:mg_common_game/systems/gacha/gacha_manager.dart';

/// 게임 내 Tree 모델
class Tree {
  final String id;
  final String name;
  final GachaRarity rarity;
  final Map<String, dynamic> stats;

  const Tree({
    required this.id,
    required this.name,
    required this.rarity,
    this.stats = const {},
  });
}

/// Idle Forest 가챠 어댑터
class TreeGachaAdapter extends ChangeNotifier {
  final GachaManager _gachaManager = GachaManager(
    pityConfig: const PityConfig(
      softPityStart: 70,
      hardPity: 80,
      softPityBonus: 6.0,
    ),
    multiPullGuarantee: const MultiPullGuarantee(
      minRarity: GachaRarity.rare,
    ),
  );

  static const String _poolId = 'forest_pool';

  TreeGachaAdapter() {
    _initPool();
  }

  void _initPool() {
    final pool = GachaPool(
      id: _poolId,
      nameKr: 'Idle Forest 가챠',
      items: _generateItems(),
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    );
    _gachaManager.registerPool(pool);
  }

  List<GachaItem> _generateItems() {
    return [
      // UR (0.6%)
      const GachaItem(id: 'ur_forest_001', nameKr: '전설의 Tree', rarity: GachaRarity.ultraRare),
      const GachaItem(id: 'ur_forest_002', nameKr: '신화의 Tree', rarity: GachaRarity.ultraRare),
      // SSR (2.4%)
      const GachaItem(id: 'ssr_forest_001', nameKr: '영웅의 Tree', rarity: GachaRarity.superRare),
      const GachaItem(id: 'ssr_forest_002', nameKr: '고대의 Tree', rarity: GachaRarity.superRare),
      const GachaItem(id: 'ssr_forest_003', nameKr: '황금의 Tree', rarity: GachaRarity.superRare),
      // SR (12%)
      const GachaItem(id: 'sr_forest_001', nameKr: '희귀한 Tree A', rarity: GachaRarity.superRare),
      const GachaItem(id: 'sr_forest_002', nameKr: '희귀한 Tree B', rarity: GachaRarity.superRare),
      const GachaItem(id: 'sr_forest_003', nameKr: '희귀한 Tree C', rarity: GachaRarity.superRare),
      const GachaItem(id: 'sr_forest_004', nameKr: '희귀한 Tree D', rarity: GachaRarity.superRare),
      // R (35%)
      const GachaItem(id: 'r_forest_001', nameKr: '우수한 Tree A', rarity: GachaRarity.rare),
      const GachaItem(id: 'r_forest_002', nameKr: '우수한 Tree B', rarity: GachaRarity.rare),
      const GachaItem(id: 'r_forest_003', nameKr: '우수한 Tree C', rarity: GachaRarity.rare),
      const GachaItem(id: 'r_forest_004', nameKr: '우수한 Tree D', rarity: GachaRarity.rare),
      const GachaItem(id: 'r_forest_005', nameKr: '우수한 Tree E', rarity: GachaRarity.rare),
      // N (50%)
      const GachaItem(id: 'n_forest_001', nameKr: '일반 Tree A', rarity: GachaRarity.normal),
      const GachaItem(id: 'n_forest_002', nameKr: '일반 Tree B', rarity: GachaRarity.normal),
      const GachaItem(id: 'n_forest_003', nameKr: '일반 Tree C', rarity: GachaRarity.normal),
      const GachaItem(id: 'n_forest_004', nameKr: '일반 Tree D', rarity: GachaRarity.normal),
      const GachaItem(id: 'n_forest_005', nameKr: '일반 Tree E', rarity: GachaRarity.normal),
      const GachaItem(id: 'n_forest_006', nameKr: '일반 Tree F', rarity: GachaRarity.normal),
    ];
  }

  /// 단일 뽑기
  Tree? pullSingle() {
    final result = _gachaManager.pull(_poolId);
    if (result == null) return null;
    notifyListeners();
    return _convertToItem(result.item);
  }

  /// 10연차
  List<Tree> pullTen() {
    final results = _gachaManager.multiPull(_poolId, count: 10);
    notifyListeners();
    return results.map((r) => _convertToItem(r.item)).toList();
  }

  Tree _convertToItem(GachaItem item) {
    return Tree(
      id: item.id,
      name: item.nameKr,
      rarity: item.rarity,
    );
  }

  /// 천장까지 남은 횟수
  int get pullsUntilPity => _gachaManager.remainingPity(_poolId);

  /// 총 뽑기 횟수
  int get totalPulls => _gachaManager.getPityState(_poolId)?.totalPulls ?? 0;

  /// 통계
  GachaStats get stats => _gachaManager.getStats(_poolId);

  Map<String, dynamic> toJson() => _gachaManager.toJson();
  void loadFromJson(Map<String, dynamic> json) {
    _gachaManager.loadFromJson(json);
    notifyListeners();
  }
}
