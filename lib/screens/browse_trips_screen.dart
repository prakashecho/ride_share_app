// File: lib/screens/browse_trips_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider if used
import 'package:ride_share_app/services/api_service.dart';
import 'package:intl/intl.dart';
// Ensure MyTripRequestViewModel is defined in trip.dart or imported separately
import 'package:ride_share_app/models/trip.dart';

class BrowseTripsScreen extends StatefulWidget {
  const BrowseTripsScreen({super.key});
  @override
  State<BrowseTripsScreen> createState() => _BrowseTripsScreenState();
}

class _BrowseTripsScreenState extends State<BrowseTripsScreen> {
  late ApiService _apiService;
  late Future<List<MyTripRequestViewModel>> _pendingTripsFuture;
  bool _isAccepting = false;
  int? _acceptingTripId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _apiService = Provider.of<ApiService>(context, listen: false);
        _loadPendingTrips();
      }
    });
  }

  Future<void> _loadPendingTrips() async {
    if (!mounted || _isAccepting) return;

    setState(() {
      _pendingTripsFuture = _apiService.getPendingTripRequests().catchError((error) {
        if (!mounted) return Future.value(<MyTripRequestViewModel>[]);
        print("Error loading pending trips in screen: $error");
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to load pending trips: ${error.toString().split(':').last}')),
        );
        return Future.value(<MyTripRequestViewModel>[]);
      });
    });
    try {
      await _pendingTripsFuture;
    } catch (_) {
      // Error handled
    }
  }

  // --- FIX: Implement _formatDateRange ---
  String _formatDateRange(DateTime earliest, DateTime latest) {
    if (earliest.year <= 1970 || latest.year <= 1970) return "Invalid Date";
    try {
      final DateFormat displayFormat = DateFormat('MMM d, hh:mm a');
      final localEarliest = earliest.toLocal();
      final localLatest = latest.toLocal();

      if (localEarliest.year == localLatest.year &&
          localEarliest.month == localLatest.month &&
          localEarliest.day == localLatest.day) {
        return "${displayFormat.format(localEarliest)} - ${DateFormat('hh:mm a').format(localLatest)}";
      } else {
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
    // Only need pending status here, but keep others for potential future use
    switch (lowerStatus) {
      case 'pending':
        return (icon: Icons.hourglass_top_rounded, color: Colors.orange.shade300);
      // Other statuses might be useful if the API changes or for different contexts
      case 'scheduled':
        return (icon: Icons.schedule_rounded, color: Colors.blue.shade300);
      case 'accepted':
        return (icon: Icons.check_circle_rounded, color: Colors.green.shade400);
      case 'driver en route':
        return (icon: Icons.local_shipping_rounded, color: Colors.teal.shade300);
      case 'in progress':
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

  // --- Accept Trip Logic ---
  Future<void> _acceptTrip(int tripId) async {
    if (_isAccepting) return;
    setState(() { _isAccepting = true; _acceptingTripId = tripId; });
    String? feedbackMessage;
    bool success = false;
    // Capture context before async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await _apiService.acceptTripRequest(tripId);
      feedbackMessage = result['message'] as String? ?? 'Trip accepted!';
      success = true;
    } catch (e) {
      feedbackMessage = e.toString();
      if (feedbackMessage.startsWith("Exception: ")) {
        feedbackMessage = feedbackMessage.substring("Exception: ".length);
      }
      success = false;
    } finally {
      if (mounted) { // Check if widget is still mounted after await
        setState(() { _isAccepting = false; _acceptingTripId = null; });
        messenger.showSnackBar(
          SnackBar(
            content: Text(feedbackMessage ?? 'Unknown error.'),
            backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
            duration: Duration(seconds: success ? 2 : 4),
          )
        );
        if (success) {
          // Don't call _loadPendingTrips directly in finally if setState was called.
          // Trigger refresh after build frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
             _loadPendingTrips();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- FIX: Corrected Scaffold Structure ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Pending Trips'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isAccepting ? null : _loadPendingTrips, // Disable refresh while accepting
              tooltip: 'Refresh Trips'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingTrips,
        child: FutureBuilder<List<MyTripRequestViewModel>>(
          future: _pendingTripsFuture,
          builder: (context, snapshot) {
            // --- Loading State ---
            if (snapshot.connectionState == ConnectionState.waiting && !_isAccepting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error State ---
            if (snapshot.hasError && !_isAccepting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading pending trips:\n${snapshot.error.toString().split(':').last.trim()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          onPressed: _loadPendingTrips)
                    ],
                  ),
                ),
              );
            }

            // --- Empty State ---
            final trips = snapshot.data ?? [];
            if (trips.isEmpty && !_isAccepting) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade600),
                          const SizedBox(height: 16),
                          Text('No pending trips found right now.', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Text('(Pull down to refresh)', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // --- Display List ---
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final MyTripRequestViewModel trip = trips[index];
                final statusStyle = _getStatusStyle(trip.requestStatus); // Always pending here
                final bool isCurrentAccepting = _isAccepting && _acceptingTripId == trip.id;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: isCurrentAccepting ? 0 : 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Tooltip(
                      message: trip.requestStatus.toUpperCase(),
                      child: Icon(statusStyle.icon, color: statusStyle.color, size: 30)),
                    title: Text(
                      '${trip.originAddress} -> ${trip.destinationAddress}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'Passenger: ${trip.passengerName}\n' // Added passenger name
                      '${_formatDateRange(trip.departureEarliest, trip.departureLatest)}\n'
                      'Seats Needed: ${trip.seatsNeeded}',
                       style: const TextStyle(height: 1.3), // Adjust line spacing
                    ),
                    isThreeLine: true, // Make space for passenger name
                    trailing: SizedBox(
                      width: 90,
                      child: isCurrentAccepting
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)))
                        : ElevatedButton(
                            onPressed: _isAccepting ? null : () => _acceptTrip(trip.id), // Use ID from ViewModel
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 13)),
                            child: const Text('Accept'),
                          ),
                    ),
                    onTap: () {
                      print('Tapped pending request ID: ${trip.id}');
                      // Optional: Navigate to details
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
} // End _BrowseTripsScreenState