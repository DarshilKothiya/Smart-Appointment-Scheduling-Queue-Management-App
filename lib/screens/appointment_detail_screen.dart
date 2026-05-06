import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/queue_meter.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          // Refresh appointment from provider
          final current = provider.allAppointments
              .where((a) => a.id == appointment.id)
              .firstOrNull ?? appointment;

          return CustomScrollView(
            slivers: [
              // Hero app bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppTheme.bgDark,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: _getGradient(current.status),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  current.name.isNotEmpty
                                      ? current.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              current.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              current.appointmentId,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status chip
                      Center(child: StatusChip(status: current.status)),
                      const SizedBox(height: 20),

                      // Queue meter (only if active)
                      if (current.status == AppointmentStatus.scheduled ||
                          current.status == AppointmentStatus.inProgress) ...[
                        QueueMeter(
                          currentPosition: current.queuePosition,
                          totalInQueue: provider.activeQueue.length,
                          estimatedMinutes: current.estimatedWaitMinutes,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Appointment details card
                      _DetailCard(
                        title: 'Appointment Details',
                        children: [
                          _DetailRow(
                            icon: Icons.badge_outlined,
                            label: 'Appointment ID',
                            value: current.appointmentId,
                          ),
                          _DetailRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Service Type',
                            value: current.serviceType.displayName,
                          ),
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: DateFormat('EEEE, MMMM d, yyyy')
                                .format(current.date),
                          ),
                          _DetailRow(
                            icon: Icons.access_time_rounded,
                            label: 'Time Slot',
                            value: current.timeSlot,
                          ),
                          _DetailRow(
                            icon: Icons.event_note_rounded,
                            label: 'Booked On',
                            value: DateFormat('MMM d, yyyy · h:mm a')
                                .format(current.createdAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sync status
                      _SyncStatusCard(isSynced: current.isSynced),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  LinearGradient _getGradient(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppTheme.primaryGradient;
      case AppointmentStatus.inProgress:
        return AppTheme.warningGradient;
      case AppointmentStatus.completed:
        return AppTheme.successGradient;
      case AppointmentStatus.cancelled:
        return const LinearGradient(
          colors: [AppTheme.cancelledColor, Color(0xFFFF9A9E)],
        );
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2840)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final bool isSynced;
  const _SyncStatusCard({required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSynced
            ? AppTheme.successColor.withOpacity(0.08)
            : AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSynced
              ? AppTheme.successColor.withOpacity(0.2)
              : AppTheme.warningColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            color: isSynced ? AppTheme.successColor : AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSynced ? 'Synced to Cloud' : 'Stored Locally (Offline)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSynced
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
                Text(
                  isSynced
                      ? 'This appointment is synced with the server'
                      : 'Will sync when internet connection is restored',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
