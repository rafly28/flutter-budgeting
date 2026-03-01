import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/category_controller.dart';
import '../models/transaction_category.dart';

class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Kategori'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Pemasukan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CategoryList(type: 'expense'),
            _CategoryList(type: 'income'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => _showCategoryDialog(context),
        ),
      ),
    );
  }

  // Dialog untuk Tambah Data
  void _showCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tambah Kategori'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Kategori'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Pengeluaran'),
                    ),
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Tipe Kategori'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<CategoryController>().addCategory(
                      nameController.text.trim(),
                      selectedType,
                    );
                    Navigator.pop(context);
                  }
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
      return const Center(child: Text('Belum ada kategori'));
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: Icon(
            type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
            color: type == 'income' ? Colors.green : Colors.red,
          ),
          title: Text(category.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDialog(context, category),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirm(context, category),
              ),
            ],
          ),
        );
      },
    );
  }

  // Dialog Edit
  void _showEditDialog(BuildContext context, TransactionCategory category) {
    final nameController = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                context.read<CategoryController>().updateCategory(
                  category,
                  nameController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus
  void _showDeleteConfirm(BuildContext context, TransactionCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CategoryController>().deleteCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
