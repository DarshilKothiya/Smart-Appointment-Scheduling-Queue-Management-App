import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/empty_state.dart';
import 'appointment_detail_screen.dart';
import 'book_appointment_screen.dart';
import 'my_appointments_screen.dart';
import 'queue_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    MyAppointmentsScreen(),
    QueueScreen(),
    AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BookAppointmentScreen()),
              ).then((_) =>
                  context.read<AppointmentProvider>().loadAppointments()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(top: BorderSide(color: Color(0xFF2A2840), width: 1)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textMuted,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.queue_rounded),
                label: 'Queue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_rounded),
                label: 'Admin',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.loadAppointments,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.bgCard,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppTheme.bgDark,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A1535), AppTheme.bgDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SmartQueue',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Manage your appointments',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Connectivity badge
                                  _ConnectivityBadge(
                                      isConnected: provider.isConnected),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _StatsRow(provider: provider),
                  ),
                ),

                // Current serving
                if (provider.currentServing != null)
                  SliverToBoxAdapter(
                    child: _CurrentServingBanner(
                        appointment: provider.currentServing!),
                  ),

                // Today's queue header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      'Upcoming Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),

                // Queue list
                provider.activeQueue.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'No appointments yet',
                          subtitle:
                              'Book your first appointment to get started',
                          icon: Icons.event_available_rounded,
                          onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const BookAppointmentScreen()),
                          ).then((_) => provider.loadAppointments()),
                          actionLabel: 'Book Appointment',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final appt = provider.activeQueue[index];
                            return AppointmentCard(
                              appointment: appt,
                              showQueueBadge: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AppointmentDetailScreen(appointment: appt),
                                ),
                              ).then((_) => provider.loadAppointments()),
                            );
                          },
                          childCount: provider.activeQueue.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  final bool isConnected;
  const _ConnectivityBadge({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? AppTheme.successColor.withOpacity(0.15)
            : AppTheme.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppTheme.successColor.withOpacity(0.4)
              : AppTheme.errorColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 14,
            color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 5),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppointmentProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Scheduled',
          value: provider.totalScheduled.toString(),
          color: AppTheme.scheduledColor,
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Completed',
          value: provider.totalCompleted.toString(),
          color: AppTheme.completedColor,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Cancelled',
          value: provider.totalCancelled.toString(),
          color: AppTheme.cancelledColor,
          icon: Icons.cancel_rounded,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentServingBanner extends StatelessWidget {
  final dynamic appointment;
  const _CurrentServingBanner({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timelapse_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Now Serving',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  appointment.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${appointment.appointmentId} · ${appointment.serviceType.displayName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'IN PROGRESS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
