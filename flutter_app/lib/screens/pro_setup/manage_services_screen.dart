// ============================================
// Manage Services Screen
// ============================================
//
// Lets pros view, add, edit, and deactivate their services.
// Accessible from the Settings screen.
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('pro_services')
          .select()
          .eq('pro_id', userId)
          .order('created_at');

      setState(() {
        _services = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading services: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(String serviceId, bool currentActive) async {
    try {
      await _supabase
          .from('pro_services')
          .update({'is_active': !currentActive}).eq('id', serviceId);
      _loadServices();
    } catch (_) {}
  }

  Future<void> _deleteService(String serviceId, String serviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$serviceName"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('pro_services').delete().eq('id', serviceId);
        _loadServices();
      } catch (_) {}
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['service_name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final priceCtrl = TextEditingController(
        text: existing?['price']?.toString() ?? '');
    final durationCtrl = TextEditingController(
        text: existing?['duration_minutes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Service' : 'Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service name',
                  hintText: 'e.g. Men\'s Haircut',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price (R)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duration (min)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.trim());
              final duration = int.tryParse(durationCtrl.text.trim());

              if (name.isEmpty || price == null || duration == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Name, price, and duration required')),
                );
                return;
              }

              final userId = _supabase.auth.currentUser?.id;
              if (userId == null) return;

              try {
                if (existing != null) {
                  await _supabase.from('pro_services').update({
                    'service_name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'duration_minutes': duration,
                  }).eq('id', existing['id']);
                } else {
                  await _supabase.from('pro_services').insert({
                    'pro_id': userId,
                    'service_name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'duration_minutes': duration,
                    'is_active': true,
                  });
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadServices();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Services')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No services yet',
                          style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first service',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final s = _services[index];
                      final isActive = s['is_active'] ?? true;
                      return Card(
                        color: isActive ? null : Colors.grey[100],
                        child: ListTile(
                          title: Text(
                            s['service_name'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isActive ? null : Colors.grey,
                              decoration: isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Text(
                            '${s['duration_minutes']} min · R${double.parse(s['price'].toString()).toStringAsFixed(0)}'
                            '${s['description'] != null && s['description'].toString().isNotEmpty ? '\n${s['description']}' : ''}',
                          ),
                          isThreeLine:
                              s['description'] != null &&
                              s['description'].toString().isNotEmpty,
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                onTap: () => _showAddEditDialog(existing: s),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () =>
                                    _toggleActive(s['id'], isActive),
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Deactivate' : 'Activate'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () => _deleteService(
                                    s['id'], s['service_name']),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 20,
                                        color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
