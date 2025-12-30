import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'authentication.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  TextEditingController _searchController = TextEditingController();
  int totalUsers = 0;
  int monthlyActiveUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users
          .where((user) =>
              (user['username'] ?? '').toString().toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _fetchUsers() async {
    String path = join(await getDatabasesPath(), 'users.db');
    Database db = await openDatabase(path);

    final List<Map<String, dynamic>> users = await db.rawQuery('''
      SELECT id, username, createdAt, lastLogin 
      FROM users 
      WHERE username != ? 
      GROUP BY username
      ORDER BY lastLogin DESC
    ''', ['admin']);

    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);
    String start = firstDayOfMonth.toIso8601String();
    String end = firstDayOfNextMonth.toIso8601String();

    final List<Map<String, dynamic>> monthlyUsers = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT username) as count
      FROM users
      WHERE lastLogin >= ? AND lastLogin < ? AND username != ?
      ''',
      [start, end, 'admin']
    );

    setState(() {
      _users = users;
      _filteredUsers = List.from(_users);
      totalUsers = _users.length;
      monthlyActiveUsers = monthlyUsers.first['count'] ?? 0;
    });
  }

  Future<void> _deleteUser(int id) async {
    String path = join(await getDatabasesPath(), 'users.db');
    Database db = await openDatabase(path);
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
    await _fetchUsers();
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (ctx) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Users: $totalUsers',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active Total User This Month: $monthlyActiveUsers',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by username',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No Users Found.',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final createdAt =
                          DateTime.tryParse(user['createdAt'] ?? '')
                                  ?.toLocal()
                                  .toString()
                                  .split('.')[0] ??
                              'N/A';
                      final lastLogin =
                          DateTime.tryParse(user['lastLogin'] ?? '')
                                  ?.toLocal()
                                  .toString()
                                  .split('.')[0] ??
                              'N/A';

                      return Card(
                        elevation: 6,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['username'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                              const Text('Confirm Delete'),
                                          content: Text(
                                              'Are you sure you want to delete user "${user['username']}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deleteUser(user['id']);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Registered: $createdAt',
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 14)),
                              Text('Last Login: $lastLogin',
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}