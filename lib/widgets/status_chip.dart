import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  final AppointmentStatus status;
  final bool small;

  const StatusChip({super.key, required this.status, this.small = false});

  Color get _color {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppTheme.scheduledColor;
      case AppointmentStatus.inProgress:
        return AppTheme.inProgressColor;
      case AppointmentStatus.completed:
        return AppTheme.completedColor;
      case AppointmentStatus.cancelled:
        return AppTheme.cancelledColor;
    }
  }

  IconData get _icon {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule_rounded;
      case AppointmentStatus.inProgress:
        return Icons.timelapse_rounded;
      case AppointmentStatus.completed:
        return Icons.check_circle_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: small ? 10 : 12, color: _color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
