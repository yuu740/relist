import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/cycle.dart';
import '../theme/theme_provider.dart';
import '../widgets/cycle_tile.dart';
import 'cycle_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Cycle>> _cycles;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCycles();
  }

  void _refreshCycles() {
    setState(() {
      _cycles = DatabaseHelper.instance.getAllCycles();
    });
  }

  void _showCycleDialog({Cycle? cycle}) {
    _controller.text = cycle?.name ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cycle == null ? 'Create New List' : 'Edit List Name'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Spotify Playlists',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveCycle(cycle),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveCycle(Cycle? cycle) async {
    final name = _controller.text;
    if (name.isNotEmpty) {
      if (cycle == null) {
        await DatabaseHelper.instance.createCycle(Cycle(name: name));
      } else {
        await DatabaseHelper.instance.updateCycle(cycle.copy(name: name));
      }
      Navigator.pop(context);
      _refreshCycles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Cycle>>(
        future: _cycles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No lists yet.\nTap + to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            );
          }
          final cycles = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: cycles.length,
            itemBuilder: (context, index) {
              final cycle = cycles[index];
              return CycleTile(
                cycle: cycle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CycleDetailScreen(cycle: cycle),
                    ),
                  ).then((_) => _refreshCycles());
                },
                onEdit: () => _showCycleDialog(cycle: cycle),
                onDelete: () {
                  DatabaseHelper.instance.deleteCycle(cycle.id!);
                  _refreshCycles();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCycleDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

