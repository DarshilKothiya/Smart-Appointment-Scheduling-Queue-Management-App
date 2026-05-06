import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final bool showQueueBadge;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.showQueueBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2840), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Color accent top bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: _statusGradient,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: _statusGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          appointment.name.isNotEmpty
                              ? appointment.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Main info
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StatusChip(status: appointment.status, small: true),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appointment.serviceType.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _InfoTag(
                                icon: Icons.badge_outlined,
                                label: appointment.appointmentId,
                              ),
                              const SizedBox(width: 8),
                              _InfoTag(
                                icon: Icons.calendar_today_rounded,
                                label: DateFormat('MMM d').format(appointment.date),
                              ),
                              const SizedBox(width: 8),
                              _InfoTag(
                                icon: Icons.access_time_rounded,
                                label: appointment.timeSlot,
                              ),
                            ],
                          ),
                          if (showQueueBadge &&
                              (appointment.status == AppointmentStatus.scheduled ||
                                  appointment.status == AppointmentStatus.inProgress)) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.queue_rounded,
                                          size: 12, color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Queue #${appointment.queuePosition}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_empty_rounded,
                                          size: 12, color: AppTheme.warningColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '~${appointment.estimatedWaitMinutes} min',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!appointment.isSynced) ...[
                                  const SizedBox(width: 8),
                                  const Tooltip(
                                    message: 'Sync pending',
                                    child: Icon(
                                      Icons.cloud_off_rounded,
                                      size: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Arrow
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient get _statusGradient {
    switch (appointment.status) {
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

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppTheme.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
