import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final bool isFirst;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemTile({
    super.key,
    required this.item,
    required this.isFirst,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: isFirst
          ? theme.colorScheme.primary.withOpacity(0.1)
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isFirst ? theme.colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 5, 10),
        title: Text(item.content, style: const TextStyle(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFirst)
              ElevatedButton(
                onPressed: onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Use'),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: Colors.grey.shade600,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.grey.shade600,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

