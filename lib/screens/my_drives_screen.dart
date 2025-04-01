// File: lib/screens/my_drives_screen.dart
import 'package:flutter/material.dart';
import 'package:ride_share_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:ride_share_app/models/trip.dart'; // Reuse the Trip model (ensure it matches data from driving endpoint)

class MyDrivesScreen extends StatefulWidget {
  const MyDrivesScreen({super.key});

  @override
  State<MyDrivesScreen> createState() => _MyDrivesScreenState();
}

class _MyDrivesScreenState extends State<MyDrivesScreen> {
  final ApiService _apiService = ApiService();
  // Future holds the list of trips the driver is driving
  late Future<List<Trip>> _drivingTripsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrivingTrips();
  }

  // Fetch trips the driver has accepted
  Future<void> _loadDrivingTrips() async {
     setState(() {
         // Use the new API method if you created it, otherwise adapt getMyTripRequests logic if needed
         // Assuming you created getDrivingTrips in ApiService
         _drivingTripsFuture = _apiService.getDrivingTrips();
     });
     // Await for RefreshIndicator functionality
     await _drivingTripsFuture.catchError((_) {});
  }

  // --- Helper Methods (Can be shared in a utils file later) ---
  String _formatDateRange(DateTime earliest, DateTime latest) {
     if (earliest.year <= 1970 || latest.year <= 1970) return "Invalid Date";
     try {
       final DateFormat displayFormat = DateFormat('MMM d, hh:mm a');
       if (earliest.day == latest.day && earliest.month == latest.month && earliest.year == latest.year) {
          return "${displayFormat.format(earliest)} - ${DateFormat('hh:mm a').format(latest)}";
       } else {
          return "${displayFormat.format(earliest)} to ${displayFormat.format(latest)}";
       }
     } catch (e) { return "Date Error"; }
  }

   // Status styling specific to accepted trip statuses
   ({IconData icon, Color color}) _getDrivingStatusStyle(String status) {
     final lowerStatus = status.toLowerCase();
     switch (lowerStatus) {
       case 'scheduled': return (icon: Icons.schedule_rounded, color: Colors.blue.shade300);
       case 'driver_en_route': return (icon: Icons.near_me_rounded, color: Colors.cyan.shade400);
       case 'in_progress': return (icon: Icons.directions_car_filled_rounded, color: Colors.deepPurple.shade300);
       case 'completed': return (icon: Icons.task_alt_rounded, color: Colors.green.shade400);
       case 'cancelled_by_driver': // Or other cancel statuses
       case 'cancelled_by_passenger':
            return (icon: Icons.cancel_rounded, color: Colors.grey.shade500);
       default: return (icon: Icons.help_outline_rounded, color: Colors.grey.shade500);
     }
   }
  // --- End Helper Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Accepted Drives')),
      body: RefreshIndicator(
        onRefresh: _loadDrivingTrips,
        child: FutureBuilder<List<Trip>>(
          future: _drivingTripsFuture,
          builder: (context, snapshot) {
            // --- Loading ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // --- Error ---
            if (snapshot.hasError) {
              return Center( /* ... Error display ... */
                 child: Padding(padding: const EdgeInsets.all(20.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48), const SizedBox(height: 16), Text('Error loading your drives:\n${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error)), const SizedBox(height: 20), ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Try Again'), onPressed: _loadDrivingTrips) ], ), ),
               );
            }
            // --- Empty ---
            final List<Trip> trips = snapshot.data ?? [];
            if (trips.isEmpty) {
              return LayoutBuilder( /* ... Empty display ... */
                 builder: (context, constraints) => SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.no_transfer_rounded, size: 60, color: Colors.grey.shade600), const SizedBox(height: 16), Text('You haven\'t accepted any drives yet.', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10), Text('(Pull down to refresh)', style: TextStyle(color: Colors.grey.shade500)), ], ), ), ), ),
              );
            }

            // --- Success: Display List ---
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final Trip trip = trips[index];
                // Use the dedicated driving status style helper
                final statusStyle = _getDrivingStatusStyle(trip.status); // Assumes backend sends accepted_trip_status in trip.status field

                // Build subtitle parts, potentially including passenger info if fetched
                List<String> subtitleParts = [
                   _formatDateRange(trip.departureEarliest, trip.departureLatest),
                   'Seats Needed by Passenger: ${trip.seatsNeeded}', // Clarify this is passenger's need
                   'Status: ${trip.status.toUpperCase()}' // Display the current accepted trip status
                ];
                // Example if passenger name was fetched:
                // if (trip.passengerName != null) {
                //    subtitleParts.insert(1, 'Passenger: ${trip.passengerName}');
                // }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Tooltip(message: trip.status.toUpperCase(), child: Icon(statusStyle.icon, color: statusStyle.color, size: 30)),
                    title: Text('${trip.originAddress} to ${trip.destinationAddress}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(subtitleParts.join('\n')),
                    isThreeLine: subtitleParts.length > 2, // Adjust if adding more info
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                    onTap: () {
                      // TODO: Navigate to Driver's Trip Detail Screen (for status updates, chat)
                      print('Tapped on accepted drive ID: ${trip.acceptedTripId}, Request ID: ${trip.id}');
                       ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Driver trip detail view not implemented yet (ID: ${trip.acceptedTripId}).'))
                       );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}