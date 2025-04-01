// File: lib/screens/my_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider if used
import 'package:ride_share_app/services/api_service.dart';
import 'package:intl/intl.dart';
// Ensure MyTripRequestViewModel is defined in trip.dart or imported separately
import 'package:ride_share_app/models/trip.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  late ApiService _apiService;
  late Future<List<MyTripRequestViewModel>> _myTripsFuture;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to safely access context for Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _apiService = Provider.of<ApiService>(context, listen: false);
        _loadMyTrips();
      }
    });
  }

  // Function to fetch trips and update the state's Future
  Future<void> _loadMyTrips() async {
    if (!mounted) return;
    setState(() {
      _myTripsFuture = _apiService.getMyTripRequests().catchError((error) {
        if (!mounted) return Future.value(<MyTripRequestViewModel>[]);
        print("Error loading my trips in screen: $error");
        // Use ScaffoldMessenger safely
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to load trips: ${error.toString().split(':').last}')),
        );
        return Future.value(<MyTripRequestViewModel>[]);
      });
    });
    try {
      await _myTripsFuture; // Await for RefreshIndicator completion
    } catch (_) {
      // Error handled by catchError
    }
  }

  // --- FIX: Implement _formatDateRange ---
  String _formatDateRange(DateTime earliest, DateTime latest) {
    // Check for invalid dates (e.g., epoch from parsing error)
    if (earliest.year <= 1970 || latest.year <= 1970) return "Invalid Date";
    try {
      final DateFormat displayFormat = DateFormat('MMM d, hh:mm a'); // e.g., Aug 15, 09:00 AM
      // Use local time for display
      final localEarliest = earliest.toLocal();
      final localLatest = latest.toLocal();

      if (localEarliest.year == localLatest.year &&
          localEarliest.month == localLatest.month &&
          localEarliest.day == localLatest.day) {
        // Same day: Aug 15, 09:00 AM - 11:00 AM
        return "${displayFormat.format(localEarliest)} - ${DateFormat('hh:mm a').format(localLatest)}";
      } else {
        // Different days: Aug 15, 09:00 AM to Aug 16, 11:00 AM
        return "${displayFormat.format(localEarliest)} to ${displayFormat.format(localLatest)}";
      }
    } catch (e) {
      print("Error formatting date range: $e");
      return "Date Error";
    }
  }

  // --- FIX: Implement _getStatusStyle ---
  ({IconData icon, Color color}) _getStatusStyle(String status) {
    final lowerStatus = status.toLowerCase();
    switch (lowerStatus) {
      case 'pending':
        return (icon: Icons.hourglass_top_rounded, color: Colors.orange.shade300);
      case 'scheduled': // Added
        return (icon: Icons.schedule_rounded, color: Colors.blue.shade300);
      case 'accepted': // Still useful if backend uses it sometimes
        return (icon: Icons.check_circle_rounded, color: Colors.green.shade400);
      case 'driver en route': // Added
        return (icon: Icons.local_shipping_rounded, color: Colors.teal.shade300);
      case 'in progress': // Added
        return (icon: Icons.directions_car_rounded, color: Colors.lightGreen.shade500);
      case 'completed':
        return (icon: Icons.task_alt_rounded, color: Colors.blue.shade400);
      case 'cancelled':
        return (icon: Icons.cancel_rounded, color: Colors.grey.shade500);
      case 'expired':
        return (icon: Icons.timer_off_rounded, color: Colors.red.shade400);
      default:
        return (icon: Icons.help_outline_rounded, color: Colors.grey.shade500);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIX: Corrected Scaffold Structure ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posted Trips'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMyTrips,
              tooltip: 'Refresh Trips'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyTrips,
        child: FutureBuilder<List<MyTripRequestViewModel>>(
          future: _myTripsFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error State ---
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading your trips:\n${snapshot.error.toString().split(':').last.trim()}', // Show concise error
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: _loadMyTrips,
                      )
                    ],
                  ),
                ),
              );
            }

            // --- Empty State ---
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.trip_origin_outlined,
                              size: 60, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('You haven\'t posted any trips yet.',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Text('(Pull down to refresh)',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // --- Success State ---
            final List<MyTripRequestViewModel> trips = snapshot.data!;
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final MyTripRequestViewModel trip = trips[index];
                // Use the displayStatus which prefers accepted_trip_status
                final statusStyle = _getStatusStyle(trip.displayStatus);

                // Build subtitle dynamically
                List<String> subtitleLines = [
                  _formatDateRange(trip.departureEarliest, trip.departureLatest),
                  'Seats: ${trip.seatsNeeded}',
                ];
                if (trip.driverName != null) {
                  subtitleLines.add('Driver: ${trip.driverName}');
                }
                 if (trip.offeredPrice != null) {
                  subtitleLines.add('Price: \$${trip.offeredPrice!.toStringAsFixed(2)}');
                 }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Tooltip(
                      message: trip.displayStatus.toUpperCase(),
                      child: Icon(statusStyle.icon, color: statusStyle.color, size: 30),
                    ),
                    title: Text(
                      '${trip.originAddress} -> ${trip.destinationAddress}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(subtitleLines.join('\n')), // Join lines for subtitle
                    isThreeLine: subtitleLines.length >= 3, // Adjust based on content
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                    onTap: () {
                      print('Tapped on trip ID: ${trip.id}, Accepted ID: ${trip.acceptedTripId}');
                      // TODO: Navigate based on whether acceptedTripId is present
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Trip details view not implemented yet (Req ID: ${trip.id}).')));
                    },
                  ),
                );
              },
            );
          }, // End builder
        ), // End FutureBuilder
      ), // End RefreshIndicator
    ); // End Scaffold
  } // End build
} // End _MyTripsScreenState