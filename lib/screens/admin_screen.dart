import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/appointment_provider.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import 'appointment_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Admin Control'),
        backgroundColor: AppTheme.bgDark,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Queue'),
            Tab(text: 'All'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Admin control bar
              _AdminControlBar(provider: provider),

              // Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Queue
                    _AppointmentList(
                      appointments: provider.activeQueue,
                      emptyTitle: 'No active appointments',
                      emptySubtitle: 'Queue is empty',
                      emptyIcon: Icons.queue_rounded,
                      showAdminActions: true,
                    ),
                    // All appointments
                    _AppointmentList(
                      appointments: provider.allAppointments,
                      emptyTitle: 'No appointments',
                      emptySubtitle: 'No appointments have been booked yet',
                      emptyIcon: Icons.event_note_rounded,
                      showAdminActions: true,
                    ),
                    // History (completed + cancelled)
                    _AppointmentList(
                      appointments: provider.allAppointments
                          .where((a) =>
                              a.status == AppointmentStatus.completed ||
                              a.status == AppointmentStatus.cancelled)
                          .toList(),
                      emptyTitle: 'No history',
                      emptySubtitle: 'Completed and cancelled appointments appear here',
                      emptyIcon: Icons.history_rounded,
                      showAdminActions: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminControlBar extends StatelessWidget {
  final AppointmentProvider provider;
  const _AdminControlBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ControlStat(
                label: 'In Queue',
                value: provider.activeQueue.length.toString(),
                icon: Icons.queue_rounded,
              ),
              _ControlStat(
                label: 'Serving',
                value: provider.currentServing != null ? '1' : '0',
                icon: Icons.timelapse_rounded,
              ),
              _ControlStat(
                label: 'Completed',
                value: provider.totalCompleted.toString(),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.activeQueue.isEmpty
                  ? null
                  : () async {
                      await provider.advanceQueue();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Queue advanced ▶'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Advance Queue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ControlStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
      ],
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final bool showAdminActions;

  const _AppointmentList({
    required this.appointments,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.showAdminActions,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return EmptyState(
          title: emptyTitle, subtitle: emptySubtitle, icon: emptyIcon);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: appointments.length,
      itemBuilder: (context, i) {
        final appt = appointments[i];
        return _AdminAppointmentCard(
          appointment: appt,
          showActions: showAdminActions,
        );
      },
    );
  }
}

class _AdminAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool showActions;

  const _AdminAppointmentCard(
      {required this.appointment, required this.showActions});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppointmentProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2840)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Position badge
                if (appointment.queuePosition > 0 &&
                    (appointment.status == AppointmentStatus.scheduled ||
                        appointment.status == AppointmentStatus.inProgress))
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: appointment.status ==
                              AppointmentStatus.inProgress
                          ? AppTheme.warningGradient
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '#${appointment.queuePosition}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        appointment.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusChip(status: appointment.status, small: true),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appointment.appointmentId} · ${appointment.serviceType.displayName}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                      Text(
                        '${DateFormat('MMM d').format(appointment.date)} · ${appointment.timeSlot}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          if (showActions &&
              appointment.status != AppointmentStatus.completed &&
              appointment.status != AppointmentStatus.cancelled)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2A2840))),
              ),
              child: Row(
                children: [
                  if (appointment.status == AppointmentStatus.scheduled)
                    _ActionBtn(
                      label: 'Start',
                      icon: Icons.play_arrow_rounded,
                      color: AppTheme.inProgressColor,
                      onTap: () => provider.markAsInProgress(appointment.id),
                    ),
                  if (appointment.status == AppointmentStatus.inProgress)
                    _ActionBtn(
                      label: 'Complete',
                      icon: Icons.check_rounded,
                      color: AppTheme.completedColor,
                      onTap: () => provider.markAsCompleted(appointment.id),
                    ),
                  _ActionBtn(
                    label: 'Reschedule',
                    icon: Icons.edit_calendar_rounded,
                    color: AppTheme.primaryColor,
                    onTap: () => _showRescheduleDialog(context, appointment),
                  ),
                  _ActionBtn(
                    label: 'Cancel',
                    icon: Icons.cancel_rounded,
                    color: AppTheme.cancelledColor,
                    onTap: () => _confirmCancel(context, appointment),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Appointment?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to cancel ${appt.name}\'s appointment (${appt.appointmentId})?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppointmentProvider>().cancelAppointment(appt.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cancelledColor),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, Appointment appt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RescheduleSheet(appointment: appt),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RescheduleSheet extends StatefulWidget {
  final Appointment appointment;
  const _RescheduleSheet({required this.appointment});

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date;
  late String _timeSlot;
  bool _isLoading = false;

  static const List<String> _timeSlots = [
    '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM',
    '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _date = widget.appointment.date;
    _timeSlot = widget.appointment.timeSlot;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reschedule ${widget.appointment.name}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.appointment.appointmentId,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          // Date picker
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
                    DateFormat('EEEE, MMMM d, yyyy').format(_date),
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Time slots
          const Text('Time Slot',
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _timeSlots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final slot = _timeSlots[i];
                final selected = slot == _timeSlot;
                return GestureDetector(
                  onTap: () => setState(() => _timeSlot = slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.bgCardLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : const Color(0xFF2A2840)),
                    ),
                    child: Text(slot,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      final result = await context
                          .read<AppointmentProvider>()
                          .rescheduleAppointment(
                            id: widget.appointment.id,
                            newDate: _date,
                            newTimeSlot: _timeSlot,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: result.success
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        );
                      }
                    },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Reschedule'),
            ),
          ),
        ],
      ),
    );
  }
}
