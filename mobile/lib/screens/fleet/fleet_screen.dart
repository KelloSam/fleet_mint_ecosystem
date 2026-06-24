import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/api_service.dart';
import '../../models/vehicle_model.dart';
import '../../models/route_model.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VehicleModel> _vehicles = [];
  List<RouteModel> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final v = await ApiService().getVehicles();
      _vehicles = v.map((e) => VehicleModel.fromJson(e)).toList();
    } catch (_) {
      _vehicles = VehicleModel.mock;
    }
    try {
      final r = await ApiService().getRoutes();
      _routes = r.map((e) => RouteModel.fromJson(e)).toList();
    } catch (_) {
      _routes = RouteModel.mock;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buses = _vehicles.where((v) => v.isBus).toList();
    final trucks = _vehicles.where((v) => v.isTruck).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Vehicles (${_vehicles.length})'),
            Tab(text: 'Routes (${_routes.length})'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Vehicles tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (buses.isNotEmpty) ...[
                      _SectionHeader(icon: Icons.directions_bus_rounded,
                          title: 'Buses (${buses.length})'),
                      const SizedBox(height: 8),
                      ...buses.asMap().entries.map((e) =>
                          _VehicleCard(vehicle: e.value)
                              .animate().fadeIn(delay: (e.key * 50).ms)),
                    ],
                    if (trucks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _SectionHeader(icon: Icons.local_shipping_rounded,
                          title: 'Trucks (${trucks.length})'),
                      const SizedBox(height: 8),
                      ...trucks.asMap().entries.map((e) =>
                          _VehicleCard(vehicle: e.value)
                              .animate().fadeIn(delay: (e.key * 50).ms)),
                    ],
                  ],
                ),

                // Routes tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routes.length,
                  itemBuilder: (context, i) =>
                      _RouteCard(route: _routes[i])
                          .animate().fadeIn(delay: (i * 50).ms),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.isActive
        ? AppColors.success
        : vehicle.status == 'maintenance'
            ? AppColors.warning
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              vehicle.isBus ? Icons.directions_bus_rounded : Icons.local_shipping_rounded,
              color: AppColors.primary, size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.registrationNumber,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary, fontSize: 15)),
                Text('${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (vehicle.isBus && vehicle.seatCapacity != null)
                      _Tag(label: '${vehicle.seatCapacity} seats', color: AppColors.accent),
                    if (vehicle.isBus && vehicle.busType != null) ...[
                      const SizedBox(width: 6),
                      _Tag(label: vehicle.busType!, color: AppColors.primary),
                    ],
                    if (vehicle.isTruck && vehicle.payloadTonnes != null)
                      _Tag(label: '${vehicle.payloadTonnes}t payload', color: AppColors.accent),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              vehicle.status[0].toUpperCase() + vehicle.status.substring(1),
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(route.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (route.isInternational)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('International',
                      style: TextStyle(color: AppColors.warning, fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(route.startLocation,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(route.endLocation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Tag(label: '${route.distanceKm.toStringAsFixed(0)} km', color: AppColors.primary),
              const SizedBox(width: 6),
              _Tag(label: Fmt.minutesToDuration(route.durationMinutes), color: AppColors.accent),
              const SizedBox(width: 6),
              _Tag(label: Fmt.currency(route.baseFare), color: AppColors.success),
            ],
          ),
          if (route.intermediateStops.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Stops: ${route.intermediateStops.join(' → ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
