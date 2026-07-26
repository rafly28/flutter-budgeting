import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/plan_item.dart';

class PlanController extends ChangeNotifier {
  final Box<PlanItem> _box = Hive.box<PlanItem>('planBox');

  // Ambil semua plan (optional, biasanya filter per cycle/bulan)
  List<PlanItem> get allPlans => _box.values.toList();

  // Ambil plan berdasarkan monthKey (misal "2026-07")
  List<PlanItem> getPlansByMonth(String monthKey) {
    return _box.values.where((p) => p.monthKey == monthKey).toList();
  }

  // Tambah plan baru
  void addPlan(PlanItem plan) {
    _box.add(plan);
    notifyListeners();
  }

  // Edit plan
  void updatePlan(int index, PlanItem updatedPlan) {
    if (index >= 0 && index < _box.length) {
      _box.putAt(index, updatedPlan);
      notifyListeners();
    }
  }

  void updatePlanByKey(dynamic key, PlanItem updatedPlan) {
      _box.put(key, updatedPlan);
      notifyListeners();
  }

  // Hapus plan
  void removePlan(dynamic key) {
    _box.delete(key);
    notifyListeners();
  }

  // Toggle status bayar (isPaid)
  void togglePaidStatus(dynamic key) {
    final plan = _box.get(key);
    if (plan != null) {
      plan.isPaid = !plan.isPaid;
      plan.save();
      notifyListeners();
    }
  }

  // Unmark paid berdasarkan planId (digunakan saat expense dihapus)
  void unmarkPaidByPlanId(String planId) {
    try {
      final plan = _box.values.firstWhere((p) => p.id == planId);
      if (plan.isPaid) {
        plan.isPaid = false;
        plan.save();
        notifyListeners();
      }
    } catch (_) {
      // Abaikan jika tidak ditemukan
    }
  }

  // Fungsi Recurring (Otomatis copy plan dari bulan sebelumnya)
  void autoCopyFromPreviousMonth(String currentMonthKey, String previousMonthKey) {
    final currentPlans = getPlansByMonth(currentMonthKey);
    // Jika bulan ini sudah ada plan, jangan ditimpa (berarti sudah pernah di-copy atau diisi manual)
    if (currentPlans.isNotEmpty) return;

    final previousPlans = getPlansByMonth(previousMonthKey);
    if (previousPlans.isEmpty) return;

    for (var oldPlan in previousPlans) {
      final newPlan = PlanItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + oldPlan.title,
        title: oldPlan.title,
        amount: oldPlan.amount,
        isPaid: false, // Reset status bayar untuk bulan baru
        category: oldPlan.category,
        monthKey: currentMonthKey,
      );
      _box.add(newPlan);
    }
    notifyListeners();
  }
}
