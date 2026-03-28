// ============================================
// Pro Setup Wizard
// ============================================
//
// Shown after a new pro finishes profile setup.
// Guides them through:
// 1. Picking their service categories
// 2. Setting their hourly rate
// 3. Adding their first service(s) with pricing
// 4. Setting their service radius
//
// After this, they land on the map and can "Go Live".
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../map/map_screen.dart';

class ProSetupWizard extends StatefulWidget {
  const ProSetupWizard({super.key});

  @override
  State<ProSetupWizard> createState() => _ProSetupWizardState();
}

class _ProSetupWizardState extends State<ProSetupWizard> {
  final _supabase = Supabase.instance.client;
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Categories
  final Set<String> _selectedCategories = {};

  // Step 2: Rate & Radius
  double _hourlyRate = 150;
  int _serviceRadiusKm = 10;

  // Step 3: Services
  final List<_NewService> _services = [];
  final _serviceNameController = TextEditingController();
  final _serviceDescController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDurationController = TextEditingController();

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceDescController.dispose();
    _servicePriceController.dispose();
    _serviceDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Update pro profile with categories, rate, radius
      await _supabase.from('pro_profiles').update({
        'service_categories': _selectedCategories.toList(),
        'hourly_rate': _hourlyRate,
        'service_radius_km': _serviceRadiusKm,
      }).eq('user_id', userId);

      // Insert all services
      if (_services.isNotEmpty) {
        await _supabase.from('pro_services').insert(
          _services
              .map((s) => {
                    'pro_id': userId,
                    'service_name': s.name,
                    'description': s.description,
                    'price': s.price,
                    'duration_minutes': s.durationMinutes,
                    'is_active': true,
                  })
              .toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MapScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addService() {
    final name = _serviceNameController.text.trim();
    final price = double.tryParse(_servicePriceController.text.trim());
    final duration = int.tryParse(_serviceDurationController.text.trim());

    if (name.isEmpty || price == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in name, price, and duration')),
      );
      return;
    }

    setState(() {
      _services.add(_NewService(
        name: name,
        description: _serviceDescController.text.trim(),
        price: price,
        durationMinutes: duration,
      ));
      _serviceNameController.clear();
      _serviceDescController.clear();
      _servicePriceController.clear();
      _serviceDurationController.clear();
    });
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedCategories.isNotEmpty;
      case 1:
        return _hourlyRate > 0;
      case 2:
        return true; // Services are optional initially
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Services'),
        automaticallyImplyLeading: false,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (!_canContinue()) return;
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _saveAndFinish();
          }
        },
        onStepCancel: _currentStep > 0
            ? () => setState(() => _currentStep--)
            : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : _canContinue()
                          ? details.onStepContinue
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentStep == 2 ? 'Finish Setup' : 'Continue'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // ============================================
          // STEP 1: Pick Categories
          // ============================================
          Step(
            title: const Text('What services do you offer?'),
            subtitle: Text(
              _selectedCategories.isEmpty
                  ? 'Pick at least one'
                  : '${_selectedCategories.length} selected',
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.serviceCategories.entries.map((entry) {
                final isSelected = _selectedCategories.contains(entry.key);
                final color = entry.value['color'] as Color;
                return FilterChip(
                  label: Text(
                    entry.value['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  avatar: Icon(
                    entry.value['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : color,
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(entry.key);
                      } else {
                        _selectedCategories.add(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // ============================================
          // STEP 2: Rate & Radius
          // ============================================
          Step(
            title: const Text('Your rate & area'),
            subtitle: Text(
                'R${_hourlyRate.toStringAsFixed(0)}/hr · ${_serviceRadiusKm}km radius'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Default Hourly Rate (Rands)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('R'),
                    Expanded(
                      child: Slider(
                        value: _hourlyRate,
                        min: 50,
                        max: 1000,
                        divisions: 19,
                        label: 'R${_hourlyRate.toStringAsFixed(0)}',
                        onChanged: (v) => setState(() => _hourlyRate = v),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'R${_hourlyRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Clients set their own rates per service.\n'
                  'This is your default displayed on the map.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 24),
                const Text('How far will you travel?',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _serviceRadiusKm.toDouble(),
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: '${_serviceRadiusKm}km',
                        onChanged: (v) =>
                            setState(() => _serviceRadiusKm = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${_serviceRadiusKm}km',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================
          // STEP 3: Add Services
          // ============================================
          Step(
            title: const Text('Add your services'),
            subtitle: Text(
              _services.isEmpty
                  ? 'Add at least one (or skip for now)'
                  : '${_services.length} service${_services.length == 1 ? '' : 's'} added',
            ),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List of added services
                if (_services.isNotEmpty) ...[
                  ..._services.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(s.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${s.durationMinutes} min · R${s.price.toStringAsFixed(0)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              setState(() => _services.removeAt(i)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],

                // Add new service form
                const Text('New Service',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _serviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Service name',
                    hintText: 'e.g. Men\'s Haircut',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceDescController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Includes wash and style',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _servicePriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (R)',
                          hintText: '150',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _serviceDurationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (min)',
                          hintText: '45',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addService,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary data holder for a new service before saving.
class _NewService {
  final String name;
  final String description;
  final double price;
  final int durationMinutes;

  _NewService({
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
  });
}
