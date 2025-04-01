import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // For StreamSubscription

// Renamed class to avoid conflict with Supabase's internal AuthState
class AppAuthState extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  bool _isLoading = true; // Start as true until initial check is done
  // Subscription to Supabase's auth state stream
  StreamSubscription<AuthState>? _authStateSubscription; // Type is Supabase's AuthState

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Constructor: Initialize and start listening
  AppAuthState() {
    _initialize();
  }

  // Check initial state and set up listener
  void _initialize() {
    _currentUser = _supabase.auth.currentUser;
    _isLoading = false; // Initial check done
    notifyListeners(); // Notify about initial state

    // Listen for subsequent changes (login, logout, token refresh etc.)
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) { // data is Supabase's AuthState
      final Session? session = data.session; // Get session from Supabase's state object
      _currentUser = session?.user; // Update our user state based on the session
      print('Auth State Change Detected: User is ${_currentUser?.id ?? 'null'}');
      _isLoading = false; // Ensure loading is false after any change
      notifyListeners(); // Notify listeners (like the Consumer in main.dart)
    });
  }

  // Sign Up method - Handles potential email confirmation requirement
  Future<void> signUp(String email, String password, String fullName) async {
     bool needsConfirmation = false;
     try {
      _setLoading(true);
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // Used by profile creation trigger
      );

      // Check if signup likely requires email confirmation
      // Supabase returns a user but potentially a null session if confirmation is needed.
      if (res.user != null && res.session == null) {
         needsConfirmation = true;
         print('Signup successful, requires email confirmation.');
      } else if (res.session != null) {
          print('Signup successful and user logged in.');
          // State update will be handled by the onAuthStateChange listener
      }

      _setLoading(false); // Set loading false after Supabase call

      // Throw specific exception if confirmation is needed so UI can handle it
      if (needsConfirmation) {
          throw Exception("Signup successful! Please check your email to confirm your account before logging in.");
      }

    } on AuthException catch (e) {
       _setLoading(false);
       print('Signup Auth Error: ${e.message}');
       rethrow; // Re-throw AuthException for specific handling in UI if needed
    } catch (e) {
       _setLoading(false);
       print('Unexpected Signup Error: $e');
       // Check if it was our specific confirmation exception
       if (e is Exception && e.toString().contains("check your email")) {
          rethrow; // Rethrow the confirmation message
       } else {
          // Rethrow other unexpected errors as a generic message
           throw Exception("An unexpected error occurred during signup.");
       }
    }
  }

  // Sign In method
  Future<void> signIn(String email, String password) async {
    try {
      _setLoading(true);
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Successful sign-in triggers onAuthStateChange, no need to set _currentUser here
      _setLoading(false);
    } on AuthException catch (e) {
      _setLoading(false);
      print('Signin Error: ${e.message}');
      rethrow; // Re-throw for UI handling
    } catch (e) {
      _setLoading(false);
      print('Unexpected Signin Error: $e');
      rethrow;
    }
  }

  // Sign Out method
  Future<void> signOut() async {
    try {
      _setLoading(true); // Optional: show loading indicator during sign out
      await _supabase.auth.signOut();
      // Successful sign-out triggers onAuthStateChange, setting _currentUser to null
      _setLoading(false);
    } catch (e) {
       _setLoading(false);
       print('Signout Error: $e');
       // Consider how to handle signout errors, maybe show a message
    }
  }

  // Helper to manage loading state
  void _setLoading(bool value) {
    // Avoid unnecessary notifications if state hasn't changed
    if (_isLoading != value) {
       _isLoading = value;
       notifyListeners();
    }
  }

  // Clean up the listener when this object is disposed
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    print("AppAuthState disposed and listener cancelled.");
    super.dispose();
  }
}