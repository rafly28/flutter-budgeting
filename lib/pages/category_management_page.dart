import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../controllers/category_controller.dart';
import '../models/transaction_category.dart';

const List<IconData> _availableIcons = [
  Icons.category, Icons.fastfood, Icons.directions_car, Icons.shopping_cart,
  Icons.local_hospital, Icons.school, Icons.home, Icons.flight,
  Icons.phone_android, Icons.pets, Icons.sports_esports, Icons.work,
  Icons.account_balance, Icons.attach_money, Icons.credit_card, Icons.monetization_on,
];

/// Opsi grup budget untuk metode 50-30-20.
const List<({String value, String label})> _budgetGroupOptions = [
  (value: 'needs', label: 'Kebutuhan'),
  (value: 'wants', label: 'Keinginan'),
  (value: 'savings', label: 'Tabungan'),
];

/// Menampilkan pesan error singkat ke pengguna.
void _showError(BuildContext context, String message) {
  toastification.show(
    context: context,
    title: Text(message),
    type: ToastificationType.error,
    style: ToastificationStyle.flat,
    autoCloseDuration: const Duration(seconds: 3),
  );
}

/// Widget kecil untuk memilih grup budget (needs / wants / savings).
///
/// Tidak dipakai untuk kategori pemasukan, karena 50-30-20 hanya menghitung
/// pengeluaran.
class _BudgetGroupField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _BudgetGroupField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Grup Budget (50-30-20)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _budgetGroupOptions.map((option) {
            final selected = value == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: selected,
              onSelected: (_) => onChanged(option.value),
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100, // Background senada Dashboard
        appBar: AppBar(
          title: const Text(
            'Kelola Kategori',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.onPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            tabs: const [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Pemasukan'),
            ],
          ),
        ),
        body: Column(
          children: [
            // 🔹 Efek Lengkungan Biru di bawah TabBar
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CategoryList(type: 'expense'),
                  _CategoryList(type: 'income'),
                ],
              ),
            ),
          ],
        ),
        // 🔹 FAB Konsisten (Center & Extended)
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text(
            "Kategori Baru",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () => _showCategoryDialog(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // Dialog Tambah Kategori (Gaya Rounded & Clean)
  void _showCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedBudgetGroup = 'needs';
    IconData selectedIcon = _availableIcons.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Tambah Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tipe',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Pengeluaran'),
                    ),
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pilih Ikon",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableIcons.map((icon) {
                    final bool isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: CircleAvatar(
                        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.grey.shade100,
                        child: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedType == 'expense') ...[
                  const SizedBox(height: 15),
                  _BudgetGroupField(
                    value: selectedBudgetGroup,
                    onChanged: (value) =>
                        setState(() => selectedBudgetGroup = value),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  final error = context
                      .read<CategoryController>()
                      .validateName(name);
                  if (error != null) {
                    _showError(context, error);
                    return;
                  }
                  final added = context.read<CategoryController>().addCategory(
                    name,
                    selectedType,
                    iconCodePoint: selectedIcon.codePoint,
                    iconFontFamily: selectedIcon.fontFamily,
                    budgetGroup: selectedBudgetGroup,
                  );
                  if (!added) {
                    _showError(context, 'Kategori gagal disimpan.');
                    return;
                  }
                  Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final String type;
  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CategoryController>();
    final categories = type == 'income'
        ? controller.incomeCategories
        : controller.expenseCategories;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada kategori ${type == "income" ? "pemasukan" : "pengeluaran"}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: type == 'income'
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: category.iconCodePoint != null &&
                      category.iconFontFamily != null
                  ? Icon(
                      IconData(
                        category.iconCodePoint!,
                        fontFamily: category.iconFontFamily,
                      ),
                      color: category.type == 'income'
                          ? Colors.green
                          : Colors.red,
                    )
                  : Icon(
                      category.type == 'income'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: category.type == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => _showEditDialog(context, category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteConfirm(context, category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, TransactionCategory category) {
    final nameController = TextEditingController(text: category.name);
    String selectedBudgetGroup = category.budgetGroup;
    IconData selectedIcon = category.iconCodePoint != null && category.iconFontFamily != null
        ? IconData(category.iconCodePoint!, fontFamily: category.iconFontFamily)
        : _availableIcons.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Edit Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Pilih Ikon",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableIcons.map((icon) {
                    final bool isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: CircleAvatar(
                        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.grey.shade100,
                        child: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
                      ),
                    );
                  }).toList(),
                ),
                if (category.type == 'expense') ...[
                  const SizedBox(height: 15),
                  _BudgetGroupField(
                    value: selectedBudgetGroup,
                    onChanged: (value) =>
                        setState(() => selectedBudgetGroup = value),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final controller = context.read<CategoryController>();
                  final error = controller.validateName(
                    nameController.text,
                    ignoring: category,
                  );
                  if (error != null) {
                    _showError(context, error);
                    return;
                  }
                  final saved = await controller.updateCategory(
                    category,
                    nameController.text,
                    iconCodePoint: selectedIcon.codePoint,
                    iconFontFamily: selectedIcon.fontFamily,
                    budgetGroup: category.type == 'expense'
                        ? selectedBudgetGroup
                        : category.budgetGroup,
                  );
                  if (!context.mounted) return;
                  if (!saved) {
                    _showError(context, 'Kategori gagal disimpan.');
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, TransactionCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori?'),
        content: Builder(
          builder: (dialogContext) {
            final controller = context.read<CategoryController>();
            final references = controller.referenceCount(category.name);
            final hasLimit = controller.hasBudgetLimit(category.name);
            if (references == 0) {
              return Text(
                'Kategori "${category.name}" belum dipakai transaksi atau '
                'rencana apa pun dan akan dihapus'
                '${hasLimit ? ' (limit budget ikut dihapus)' : ''}.',
              );
            }
            return Text(
              'Kategori "${category.name}" masih dipakai $references catatan '
              '(transaksi atau rencana). Hapus kategori dengan paksa akan '
              'membuat catatan itu kehilangan kategori. Rename kategori lebih '
              'aman.',
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final deleted = await context
                  .read<CategoryController>()
                  .deleteCategory(category);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (!deleted) {
                _showError(
                  context,
                  'Kategori masih dipakai catatan lain, jadi tidak dihapus. '
                  'Rename kategori sebagai gantinya.',
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
