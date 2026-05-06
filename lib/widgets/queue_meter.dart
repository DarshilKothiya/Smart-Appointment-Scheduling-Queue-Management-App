import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QueueMeter extends StatelessWidget {
  final int currentPosition;
  final int totalInQueue;
  final int estimatedMinutes;

  const QueueMeter({
    super.key,
    required this.currentPosition,
    required this.totalInQueue,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalInQueue > 0
        ? (totalInQueue - currentPosition + 1) / totalInQueue
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.queueGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QueueStat(
                label: 'Your Position',
                value: '#$currentPosition',
                icon: Icons.person_rounded,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _QueueStat(
                label: 'People Ahead',
                value: '${(currentPosition - 1).clamp(0, 999)}',
                icon: Icons.groups_rounded,
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _QueueStat(
                label: 'Est. Wait',
                value: '${estimatedMinutes}m',
                icon: Icons.hourglass_empty_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Queue Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$totalInQueue in queue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _QueueStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
