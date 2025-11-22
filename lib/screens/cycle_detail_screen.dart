import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cycle.dart';
import '../models/item.dart';
import '../widgets/item_tile.dart';

class CycleDetailScreen extends StatefulWidget {
  final Cycle cycle;
  const CycleDetailScreen({super.key, required this.cycle});

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  List<Item> _items = [];
  bool _isLoading = true;
  
  bool _isReordering = false;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  Future<void> _refreshItems() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getItemsByCycleId(
      widget.cycle.id!,
    );
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  void _toggleReorderMode() {
    setState(() {
      _isReordering = !_isReordering;
    });
    if (!_isReordering) {
      _refreshItems();
    }
  }

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Item item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    await DatabaseHelper.instance.updateItemsOrder(_items);
  }

  void _showItemDialog({Item? item}) {
    _controller.text = item?.content ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add New Item' : 'Edit Item'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Wash the dishes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveItem(item),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveItem(Item? item) async {
    final content = _controller.text;
    if (content.isNotEmpty) {
      if (item == null) {
        final newItem = await DatabaseHelper.instance.createItem(
          Item(cycleId: widget.cycle.id!, content: content, orderPosition: 0),
        );
        _items.add(newItem);
        if (!_isReordering) {
          _listKey.currentState?.insertItem(_items.length - 1);
        }
      } else {
        final updatedItem = item.copy(content: content);
        await DatabaseHelper.instance.updateItem(updatedItem);
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) setState(() => _items[index] = updatedItem);
      }
      Navigator.pop(context);
      if (_isReordering) setState(() {});
    }
  }

  void _onUseItem(Item item, int index) async {
    await DatabaseHelper.instance.rotateItemToBack(item);

    final usedItem = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(sizeFactor: animation),
    );

    final newItems = await DatabaseHelper.instance.getItemsByCycleId(
      widget.cycle.id!,
    );
    setState(() {
      _items = newItems;
    });
    _refreshItems();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.content}" moved to the back.'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _onDeleteItem(Item item, int index) {
    DatabaseHelper.instance.deleteItem(item.id!);

    setState(() {
       final removedItem = _items.removeAt(index);
       
       if (!_isReordering) {
         _listKey.currentState?.removeItem(
          index,
          (context, animation) => FadeTransition(
            opacity: animation,
            child: ItemTile(
              item: removedItem,
              isFirst: false,
              onUse: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        );
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cycle.name),
        actions: [
          IconButton(
            tooltip: _isReordering ? 'Done Reordering' : 'Manage Order',
            icon: Icon(_isReordering ? Icons.check : Icons.sort),
            onPressed: _toggleReorderMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'Empty! Add your first item.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                )
              : _buildList(), 
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList() {
    if (_isReordering) {
      return ReorderableListView(
        padding: const EdgeInsets.all(8),
        onReorder: _onReorder,
        children: [
          for (int i = 0; i < _items.length; i++)
            ListTile(
              key: ValueKey(_items[i].id), 
              title: Text(_items[i].content),
              leading: const Icon(Icons.drag_handle),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _onDeleteItem(_items[i], i),
              ),
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
        ],
      );
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();
        
        final item = _items[index];
        return SizeTransition(
          sizeFactor: animation,
          child: ItemTile(
            item: item,
            isFirst: index == 0,
            onUse: () => _onUseItem(item, index),
            onEdit: () => _showItemDialog(item: item),
            onDelete: () => _onDeleteItem(item, index),
          ),
        );
      },
    );
  }
}