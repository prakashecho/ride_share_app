// File: lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
// --- UPDATE IMPORT IF YOU MOVED/RENAMED THE MODEL FILE ---
import 'package:ride_share_app/models/trip.dart'; // Now includes MyTripRequestViewModel

class ApiService {
  static const String _emulatorBaseUrl = 'http://10.0.2.2:8089/api/v1';
  static const String _localBaseUrl = 'http://localhost:8089/api/v1';
  static String get _baseUrl { try { if (Platform.isAndroid) { return _emulatorBaseUrl; } } catch (e) {} return _localBaseUrl; }
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, String>> _getHeaders() async {
     final session = _supabase.auth.currentSession;
     if (session == null) {
        print("[API Service] Error: No active session found for headers.");
        throw Exception('Not authenticated.');
     }
     return {
       'Content-Type': 'application/json; charset=UTF-8',
       'Authorization': 'Bearer ${session.accessToken}',
     };
  }

  // --- createTripRequest (Keep as is) ---
  Future<Map<String, dynamic>> createTripRequest({
     required String originAddress, required double originLat, required double originLon,
     required String destinationAddress, required double destinationLat, required double destinationLon,
     required DateTime departureEarliest, required DateTime departureLatest, required int seatsNeeded,
     String? notes, double? offeredPrice
  }) async {
     final url = Uri.parse('$_baseUrl/trip-requests');
     late final Map<String, String> headers;
     try { headers = await _getHeaders(); } catch (e) { throw Exception('Auth error: ${e.toString()}'); }
     final body = jsonEncode(<String, dynamic>{
       'origin_address': originAddress, 'origin_lat': originLat, 'origin_lon': originLon,
       'destination_address': destinationAddress, 'destination_lat': destinationLat, 'destination_lon': destinationLon,
       'departure_earliest': departureEarliest.toUtc().toIso8601String(),
       'departure_latest': departureLatest.toUtc().toIso8601String(),
       'seats_needed': seatsNeeded,
       if (notes != null && notes.isNotEmpty) 'notes': notes,
       if (offeredPrice != null) 'offered_price': offeredPrice,
     });
     print('[API Service] POST $url');
     try {
        final response = await http.post(url, headers: headers, body: body);
        print('[API Service] POST $url Response: ${response.statusCode}');
        if (response.statusCode == 201) {
           try { return jsonDecode(response.body) as Map<String, dynamic>; } catch (e) { throw Exception('Success, but bad response format.'); }
        } else { throw _handleApiError(response); }
     } on http.ClientException catch (e) { throw Exception('Network Error: ${e.message}'); } catch (e) { throw Exception('Unexpected Error: ${e.toString()}'); }
  }

  // --- getMyTripRequests (UPDATED Return Type and Parsing) ---
  Future<List<MyTripRequestViewModel>> getMyTripRequests() async {
     final url = Uri.parse('$_baseUrl/trip-requests/mine');
     final headers = await _getHeaders();
     print('[API Service] GET $url');
     try {
        final response = await http.get(url, headers: headers);
        print('[API Service] GET $url Response: ${response.statusCode}');
        if (response.statusCode == 200) {
           try {
              // Use utf8.decode for broader character support
              List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
              // --- USE THE NEW VIEW MODEL ---
              return jsonList.map((json) => MyTripRequestViewModel.fromJson(json as Map<String, dynamic>)).toList();
           } catch (e) {
              print('[API Service] JSON Decode/Parse Error (GET $url): $e');
              throw Exception('Failed to parse my trip list: ${e.toString()}');
           }
        } else {
           throw _handleApiError(response);
        }
     } on http.ClientException catch (e) {
        print('[API Service] Network Error (GET $url): ${e.message}');
        throw Exception('Network Error: ${e.message}');
     } catch (e) {
        print('[API Service] Unexpected Error (GET $url): ${e.toString()}');
        if (e is Exception) { rethrow; } // Rethrow known exceptions
        throw Exception('Unexpected Error: ${e.toString()}');
     }
  }

  // --- getPendingTripRequests (UPDATED Return Type and Parsing) ---
  Future<List<MyTripRequestViewModel>> getPendingTripRequests() async {
      final url = Uri.parse('$_baseUrl/trip-requests/pending');
      final headers = await _getHeaders();
      print('[API Service] GET $url');
      try {
          final response = await http.get(url, headers: headers);
          print('[API Service] GET $url Response: ${response.statusCode}');
          if (response.statusCode == 200) {
             try {
                List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
                // --- USE THE NEW VIEW MODEL ---
                return jsonList.map((json) => MyTripRequestViewModel.fromJson(json as Map<String, dynamic>)).toList();
             } catch (e) {
                print('[API Service] JSON Decode/Parse Error (GET $url): $e');
                throw Exception('Failed to parse pending trip list: ${e.toString()}');
             }
          } else {
             throw _handleApiError(response);
          }
      } on http.ClientException catch (e) {
          print('[API Service] Network Error (GET $url): ${e.message}');
          throw Exception('Network Error: ${e.message}');
      } catch (e) {
          print('[API Service] Unexpected Error (GET $url): ${e.toString()}');
           if (e is Exception) { rethrow; }
           throw Exception('Unexpected Error: ${e.toString()}');
      }
  }

  // --- acceptTripRequest (Keep as is) ---
  Future<Map<String, dynamic>> acceptTripRequest(int requestId) async {
      final url = Uri.parse('$_baseUrl/trip-requests/$requestId/accept');
      final headers = await _getHeaders();
      print('[API Service] POST $url (Accepting trip)');
      try {
          final response = await http.post(url, headers: headers);
          print('[API Service] POST $url Response: ${response.statusCode}');
          if (response.statusCode == 200) {
             try { return jsonDecode(response.body) as Map<String, dynamic>; } catch (e) { return {'message': 'Accepted (response issue).', 'accepted_trip_id': null}; }
          } else { throw _handleApiError(response); }
      } on http.ClientException catch (e) { throw Exception('Network Error: ${e.message}'); } catch (e) { if (e is Exception) { rethrow; } throw Exception('Unexpected Error: ${e.toString()}'); }
  }

 // --- getDrivingTrips (Keep as is for now - will need update later) ---
 // NOTE: This currently uses Trip.fromJson, which might break or miss fields
 // returned by the /driving endpoint. Will need updating when implementing MyDrivesScreen.
  Future<List<Trip>> getDrivingTrips() async {
      final url = Uri.parse('$_baseUrl/accepted-trips/driving');
      final headers = await _getHeaders();
      print('[API Service] GET $url');
      try {
          final response = await http.get(url, headers: headers);
          print('[API Service] GET $url Response: ${response.statusCode}');
          if (response.statusCode == 200) {
             try {
                List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
                // !! WARNING: Using Trip.fromJson here might be incorrect for the data
                // !! returned by /driving. Needs update later.
                print('[API Service] WARNING: getDrivingTrips parsing with Trip.fromJson, may be incomplete/incorrect.');
                return jsonList.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
             } catch (e) {
                print('[API Service] JSON Decode/Parse Error (GET $url): $e');
                throw Exception('Failed to parse driving trip list.');
             }
          } else { throw _handleApiError(response); }
      } on http.ClientException catch (e) { print('[API Service] Network Error (GET $url): ${e.message}'); throw Exception('Network Error: Could not reach the server.'); } catch (e) { print('[API Service] Unexpected Error (GET $url): ${e.toString()}'); if (e is Exception) { rethrow; } throw Exception('An unexpected error occurred: ${e.toString()}'); }
  }

 // *** NEW: Method to Update Trip Status ***
 // Added based on previous backend work
 Future<Map<String, dynamic>> updateTripStatus(int tripId, String status) async {
      final url = Uri.parse('$_baseUrl/accepted-trips/$tripId/status');
      final headers = await _getHeaders();
      final body = jsonEncode(<String, String>{'status': status});
      print('[API Service] PATCH $url with status: $status');

      try {
          final response = await http.patch(url, headers: headers, body: body);
          print('[API Service] PATCH $url Response: ${response.statusCode}');

          if (response.statusCode == 200) {
             try { return jsonDecode(response.body) as Map<String, dynamic>; } catch (e) { return {'message': 'Status Updated (response issue).'}; }
          } else { throw _handleApiError(response); }
      } on http.ClientException catch (e) { print('[API Service] Network Error (PATCH $url): ${e.message}'); throw Exception('Network Error: Could not reach the server.'); } catch (e) { print('[API Service] Unexpected Error (PATCH $url): ${e.toString()}'); if (e is Exception) { rethrow; } throw Exception('An unexpected error occurred: ${e.toString()}'); }
 }


  // --- _handleApiError (Keep as is) ---
  Exception _handleApiError(http.Response response) {
     String errorMessage = 'API Request Failed.';
     try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes)); // Use utf8 decode here too
        if (errorBody is Map && errorBody.containsKey('error')) {
           errorMessage = 'API Error: ${errorBody['error']}';
        } else if (errorBody is String && errorBody.isNotEmpty) {
           errorMessage = 'API Error: $errorBody'; // Backend might send plain text error
        } else if (errorBody is Map && errorBody.containsKey('message')) {
            errorMessage = 'API Error: ${errorBody['message']}'; // Some errors might use 'message'
        }
         else {
           errorMessage = 'API Error (${response.statusCode}): ${utf8.decode(response.bodyBytes)}';
        }
     } catch (_) {
        errorMessage = 'API Error (${response.statusCode}): ${(response.bodyBytes.isNotEmpty ? utf8.decode(response.bodyBytes) : "Unknown server error.")}';
     }
     print("[API Service] Handling API Error: $errorMessage");
     return Exception(errorMessage);
  }
} // End of ApiService class