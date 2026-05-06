import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state.dart';
import 'book_appointment_screen.dart';
import 'appointment_detail_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: AppTheme.bgDark,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: provider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Active filters row
              if (_hasActiveFilters(provider))
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _ActiveFiltersRow(provider: provider),
                ),

              // Count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${provider.appointments.length} appointment${provider.appointments.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                    if (_hasActiveFilters(provider))
                      TextButton.icon(
                        onPressed: () {
                          provider.clearFilters();
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Clear filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor))
                    : provider.appointments.isEmpty
                        ? EmptyState(
                            title: 'No appointments found',
                            subtitle: _hasActiveFilters(provider)
                                ? 'Try adjusting your search or filters'
                                : 'Book your first appointment to get started',
                            icon: Icons.event_busy_rounded,
                            onAction: _hasActiveFilters(provider)
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const BookAppointmentScreen()),
                                    ).then((_) => provider.loadAppointments()),
                            actionLabel: 'Book Appointment',
                          )
                        : RefreshIndicator(
                            onRefresh: provider.loadAppointments,
                            color: AppTheme.primaryColor,
                            backgroundColor: AppTheme.bgCard,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: provider.appointments.length,
                              itemBuilder: (context, i) {
                                final appt = provider.appointments[i];
                                return AppointmentCard(
                                  appointment: appt,
                                  showQueueBadge: true,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AppointmentDetailScreen(
                                              appointment: appt),
                                    ),
                                  ).then((_) => provider.loadAppointments()),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _hasActiveFilters(AppointmentProvider provider) {
    return provider.searchQuery.isNotEmpty ||
        provider.statusFilter != null ||
        provider.serviceFilter != null ||
        provider.dateFilter != null;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  final AppointmentProvider provider;
  const _ActiveFiltersRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (provider.statusFilter != null)
            _FilterChip(
              label: provider.statusFilter!.displayName,
              onRemove: () => provider.setStatusFilter(null),
            ),
          if (provider.serviceFilter != null)
            _FilterChip(
              label: provider.serviceFilter!.displayName,
              onRemove: () => provider.setServiceFilter(null),
            ),
          if (provider.dateFilter != null)
            _FilterChip(
              label:
                  '${provider.dateFilter!.day}/${provider.dateFilter!.month}/${provider.dateFilter!.year}',
              onRemove: () => provider.setDateFilter(null),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  AppointmentStatus? _status;
  ServiceType? _service;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppointmentProvider>();
    _status = p.statusFilter;
    _service = p.serviceFilter;
    _date = p.dateFilter;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.bgCard,
            onSurface: AppTheme.textPrimary,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: AppTheme.bgCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Appointments',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status filter
          const Text('Status',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppointmentStatus.values.map((s) {
              final selected = _status == s;
              return ChoiceChip(
                label: Text(s.displayName),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _status = selected ? null : s),
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Service filter
          const Text('Service Type',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2840)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceType?>(
                value: _service,
                isExpanded: true,
                hint: const Text('All services',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                dropdownColor: AppTheme.bgCard,
                items: [
                  const DropdownMenuItem(
                      value: null,
                      child: Text('All services',
                          style: TextStyle(color: AppTheme.textSecondary))),
                  ...ServiceType.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.displayName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 14)),
                      )),
                ],
                onChanged: (v) => setState(() => _service = v),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Date filter
          const Text('Date',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2840)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    _date != null
                        ? '${_date!.day}/${_date!.month}/${_date!.year}'
                        : 'Select date',
                    style: TextStyle(
                      color: _date != null
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_date != null)
                    GestureDetector(
                      onTap: () => setState(() => _date = null),
                      child: const Icon(Icons.clear_rounded,
                          size: 16, color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<AppointmentProvider>().clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final p = context.read<AppointmentProvider>();
                    p.setStatusFilter(_status);
                    p.setServiceFilter(_service);
                    p.setDateFilter(_date);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
