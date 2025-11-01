import 'package:flutter/material.dart';

class DashboardMenu extends StatelessWidget {
  final List<DashboardMenuItem> items;

  const DashboardMenu({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.length <= 3) {
      // 🔹 Layout row untuk max 3 item
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: item.onTap,
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                ),
              ),
            )
            .toList(),
      );
    } else {
      // 🔹 Layout grid kalau item lebih banyak
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 kolom
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3, // biar mirip tombol row
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ElevatedButton.icon(
            onPressed: item.onTap,
            icon: Icon(item.icon),
            label: Text(item.label),
          );
        },
      );
    }
  }
}

class DashboardMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DashboardMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
