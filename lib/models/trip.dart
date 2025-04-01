// lib/models/trip.dart

import 'package:flutter/foundation.dart' show immutable;
import 'package:intl/intl.dart'; // Ensure you have intl: flutter pub add intl

// Represents the core Trip Request data, primarily matching trip_requests table
@immutable
class Trip {
  final int id;
  final String passengerId; // UUID as string
  final String originAddress;
  final double originLat;
  final double originLon;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLon;
  final DateTime departureEarliest;
  final DateTime departureLatest;
  final int seatsNeeded;
  final String? notes;
  final double? offeredPrice;
  final String status; // Status from trip_requests (e.g., "pending", "accepted")
  final int? acceptedTripId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.passengerId,
    required this.originAddress,
    required this.originLat,
    required this.originLon,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.departureEarliest,
    required this.departureLatest,
    required this.seatsNeeded,
    this.notes,
    this.offeredPrice,
    required this.status,
    this.acceptedTripId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Simplified and safer factory constructor
  factory Trip.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse dates
    DateTime _parseSafeDateTime(dynamic value) {
      if (value is String) {
        try {
          return DateTime.parse(value).toLocal();
        } catch (_) {}
      }
      print("Warning: Could not parse date from '$value', returning epoch.");
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    // Helper to safely parse double
    double _parseSafeDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely parse int
    int _parseSafeInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt(); // Allow double -> int
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Trip(
      id: _parseSafeInt(json['id']),
      passengerId: json['passenger_id'] as String? ?? '',
      originAddress: json['origin_address'] as String? ?? 'Unknown Origin',
      // Parse separate lat/lon fields directly
      originLat: _parseSafeDouble(json['origin_lat']),
      originLon: _parseSafeDouble(json['origin_lon']),
      destinationAddress: json['destination_address'] as String? ?? 'Unknown Destination',
      destinationLat: _parseSafeDouble(json['destination_lat']),
      destinationLon: _parseSafeDouble(json['destination_lon']),
      departureEarliest: _parseSafeDateTime(json['departure_earliest']),
      departureLatest: _parseSafeDateTime(json['departure_latest']),
      seatsNeeded: _parseSafeInt(json['seats_needed']),
      notes: json['notes'] as String?,
      offeredPrice: _parseSafeDouble(json['offered_price']), // Use helper for price too
      status: json['status'] as String? ?? 'unknown',
      acceptedTripId: json['accepted_trip_id'] as int?, // Keep nullable parsing
      createdAt: _parseSafeDateTime(json['created_at']),
      updatedAt: _parseSafeDateTime(json['updated_at']),
    );
  }

   // Helper for date formatting (moved from ViewModel, can be used here too)
  String get formattedDepartureWindow {
    final DateFormat formatter = DateFormat('MMM d, HH:mm'); // Example format
    try {
      // Use toLocal() if times are UTC, otherwise just format
      return '${formatter.format(departureEarliest.toLocal())} - ${formatter.format(departureLatest.toLocal())}';
    } catch (e) {
      return "Invalid Date";
    }
  }

   // Optional: Add toJson method if needed
   Map<String, dynamic> toJson() => {
         // ... (implementation as before if required) ...
       };
}

// --- ADD THE VIEW MODEL CLASS HERE (or in a separate file) ---

// View Model for GetMyRequests and GetPendingRequests
class MyTripRequestViewModel {
  // Fields from original TripRequest (copied for self-containment)
  final int id;
  final String passengerId;
  final String originAddress;
  final double originLat;
  final double originLon;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLon;
  final DateTime departureEarliest;
  final DateTime departureLatest;
  final int seatsNeeded;
  final String? notes;
  final double? offeredPrice;
  final String requestStatus; // Status from trip_requests table
  final int? acceptedTripId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Added fields from backend JOINs
  final String? acceptedTripStatus; // Status from accepted_trips table (if accepted)
  final String? driverName;         // Driver's full name (if accepted)
  final String passengerName;      // Passenger's name (from profiles join)

  MyTripRequestViewModel({
    required this.id,
    required this.passengerId,
    required this.originAddress,
    required this.originLat,
    required this.originLon,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLon,
    required this.departureEarliest,
    required this.departureLatest,
    required this.seatsNeeded,
    this.notes,
    this.offeredPrice,
    required this.requestStatus,
    this.acceptedTripId,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedTripStatus,
    this.driverName,
    required this.passengerName, // Added required passenger name
  });

  factory MyTripRequestViewModel.fromJson(Map<String, dynamic> json) {
    // Use the same safe parsing helpers as Trip.fromJson
     DateTime _parseSafeDateTime(dynamic value) { if (value is String) { try { return DateTime.parse(value).toLocal(); } catch (_) {} } print("Warning: Could not parse date from '$value', returning epoch."); return DateTime.fromMillisecondsSinceEpoch(0); }
     double _parseSafeDouble(dynamic value) { if (value is double) return value; if (value is int) return value.toDouble(); if (value is String) return double.tryParse(value) ?? 0.0; return 0.0; }
     int _parseSafeInt(dynamic value) { if (value is int) return value; if (value is double) return value.toInt(); if (value is String) return int.tryParse(value) ?? 0; return 0; }

    return MyTripRequestViewModel(
      id: _parseSafeInt(json['id']),
      passengerId: json['passenger_id'] as String? ?? '',
      originAddress: json['origin_address'] as String? ?? 'Unknown Origin',
      originLat: _parseSafeDouble(json['origin_lat']),
      originLon: _parseSafeDouble(json['origin_lon']),
      destinationAddress: json['destination_address'] as String? ?? 'Unknown Destination',
      destinationLat: _parseSafeDouble(json['destination_lat']),
      destinationLon: _parseSafeDouble(json['destination_lon']),
      departureEarliest: _parseSafeDateTime(json['departure_earliest']),
      departureLatest: _parseSafeDateTime(json['departure_latest']),
      seatsNeeded: _parseSafeInt(json['seats_needed']),
      notes: json['notes'] as String?,
      offeredPrice: _parseSafeDouble(json['offered_price']),
      requestStatus: json['request_status'] as String? ?? 'unknown', // Field name from backend
      acceptedTripId: json['accepted_trip_id'] as int?,
      createdAt: _parseSafeDateTime(json['created_at']),
      updatedAt: _parseSafeDateTime(json['updated_at']),
      // Parse new nullable fields
      acceptedTripStatus: json['accepted_trip_status'] as String?,
      driverName: json['driver_name'] as String?,
      passengerName: json['passenger_name'] as String? ?? 'Unknown Passenger', // Added parsing
    );
  }

  // Helper method for display status
  String get displayStatus {
    final statusToShow = acceptedTripStatus ?? requestStatus;
    // Simple formatting example
    return statusToShow.replaceAll('_', ' ').toUpperCase();
  }

  // Helper for date formatting
  String get formattedDepartureWindow {
    final DateFormat formatter = DateFormat('MMM d, HH:mm'); // Example format
     try { return '${formatter.format(departureEarliest.toLocal())} - ${formatter.format(departureLatest.toLocal())}'; } catch (e) { return "Invalid Date"; }
  }
}

// TODO: Define DrivingTripViewModel later when needed for MyDrivesScreen
// class DrivingTripViewModel { ... }