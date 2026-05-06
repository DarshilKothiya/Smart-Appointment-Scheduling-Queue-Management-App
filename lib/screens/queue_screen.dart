import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/queue_meter.dart';
import '../widgets/empty_state.dart';
import 'appointment_detail_screen.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Live Queue'),
        backgroundColor: AppTheme.bgDark,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<AppointmentProvider>(
            builder: (_, provider, __) => IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: provider.isConnected
                    ? AppTheme.primaryColor
                    : AppTheme.textMuted,
              ),
              onPressed: provider.loadAppointments,
            ),
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          final queue = provider.activeQueue;
          final current = provider.currentServing;

          return RefreshIndicator(
            onRefresh: provider.loadAppointments,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.bgCard,
            child: CustomScrollView(
              slivers: [
                // Queue Meter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: queue.isEmpty
                        ? _EmptyQueueCard()
                        : QueueMeter(
                            currentPosition:
                                current != null ? 1 : (queue.isEmpty ? 0 : 1),
                            totalInQueue: queue.length,
                            estimatedMinutes:
                                queue.isNotEmpty ? queue.first.estimatedWaitMinutes : 0,
                          ),
                  ),
                ),

                // Currently serving
                if (current != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _ServingCard(appointment: current),
                    ),
                  ),

                // Queue list header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Queue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${queue.length} waiting',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Queue items
                queue.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'No one in queue',
                          subtitle: 'All appointments have been served or the queue is empty',
                          icon: Icons.people_outline_rounded,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final appt = queue[i];
                            return _QueueItem(
                              appointment: appt,
                              position: i + 1,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AppointmentDetailScreen(appointment: appt),
                                ),
                              ).then((_) => provider.loadAppointments()),
                            );
                          },
                          childCount: queue.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyQueueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2840)),
      ),
      child: const Column(
        children: [
          Icon(Icons.queue_rounded, size: 48, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text(
            'Queue is empty',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'No active appointments in queue',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ServingCard extends StatelessWidget {
  final dynamic appointment;
  const _ServingCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.warningGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                appointment.name[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔔 Now Serving',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                Text(
                  appointment.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${appointment.appointmentId} • ${appointment.serviceType.displayName}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Text('Token',
                    style: TextStyle(color: Colors.white70, fontSize: 9)),
                Text('#01',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final dynamic appointment;
  final int position;
  final VoidCallback onTap;

  const _QueueItem({
    required this.appointment,
    required this.position,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isServing = appointment.status.name == 'inProgress';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isServing
              ? AppTheme.warningColor.withOpacity(0.08)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isServing
                ? AppTheme.warningColor.withOpacity(0.3)
                : const Color(0xFF2A2840),
          ),
        ),
        child: Row(
          children: [
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isServing
                    ? AppTheme.warningGradient
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#$position',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        appointment.serviceType.displayName,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const Text(' · ',
                          style: TextStyle(color: AppTheme.textMuted)),
                      Text(
                        appointment.timeSlot,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '~${appointment.estimatedWaitMinutes} min',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.warningColor),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.appointmentId,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
