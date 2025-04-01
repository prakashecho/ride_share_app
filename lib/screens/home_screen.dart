// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_share_app/auth/app_auth_state.dart';
import 'package:ride_share_app/screens/create_trip_screen.dart';
import 'package:ride_share_app/screens/my_trips_screen.dart';
import 'package:ride_share_app/screens/browse_trips_screen.dart';
import 'package:ride_share_app/screens/my_drives_screen.dart';
// Import other screens when created
// import 'package:ride_share_app/screens/profile_screen.dart';
// import 'package:ride_share_app/screens/messages_screen.dart';
// import 'package:ride_share_app/screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- Helper method implementations are now at the END of the class ---

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AppAuthState>(context, listen: false);
    final user = authState.currentUser;
    final userEmail = user?.email ?? 'User';
    final userName = user?.userMetadata?['full_name'] as String? ?? userEmail.split('@')[0];

    final Color darkBackground = Colors.grey.shade900;
    final Color slightlyLighterDark = Colors.white.withOpacity(0.1);
    final Color tealAccent = Colors.tealAccent.shade400;
    final Color darkIconBg = Colors.grey.shade800;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        title: const Text( 'Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), ),
        // Hamburger icon appears automatically due to drawer
      ),

      // --- DRAWER ---
      drawer: Drawer(
        backgroundColor: darkBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration( color: slightlyLighterDark, ),
              child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                  const CircleAvatar( radius: 30, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 40, color: Colors.white70), ), const SizedBox(height: 10),
                  Text( userName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, ),
                  Text( userEmail, style: TextStyle(color: Colors.grey[400], fontSize: 12), overflow: TextOverflow.ellipsis, ),
                ], ), ),
            ListTile( leading: const Icon(Icons.person_outline, color: Colors.white70), title: const Text('Profile', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile screen not implemented yet.'))); }, ),
            ListTile( leading: const Icon(Icons.list_alt_rounded, color: Colors.white70), title: const Text('My Posted Trips', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTripsScreen())); }, ),
            ListTile( leading: const Icon(Icons.drive_eta_rounded, color: Colors.white70), title: const Text('My Accepted Drives', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDrivesScreen())); }, ),
            ListTile( leading: const Icon(Icons.mail_outline_rounded, color: Colors.white70), title: const Text('Messages', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messages screen not implemented yet.'))); }, ),
            ListTile( leading: const Icon(Icons.settings_outlined, color: Colors.white70), title: const Text('Settings', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings screen not implemented yet.'))); }, ),
            // --- CORRECTED DIVIDER COLOR ---
            Divider(color: Colors.grey[700]), // Use bracket notation
            ListTile( leading: const Icon(Icons.logout, color: Colors.redAccent), title: const Text('Logout', style: TextStyle(color: Colors.redAccent)), onTap: () async { Navigator.pop(context); await authState.signOut(); }, ),
          ],
        ),
      ),
      // --- END DRAWER ---


      // --- Body ---
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Welcome Text & Profile Link ---
              // --- CORRECTED Text CALL ---
              Text(
                'Welcome, $userName!', // Added actual text content
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector( // Profile Link Container
                onTap: () { ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Profile screen not implemented yet.'))); },
                child: Container( padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration( color: slightlyLighterDark, borderRadius: BorderRadius.circular(12), ),
                  child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible( child: Text( 'Welcome, $userEmail', style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis, ), ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    ], ), ), ),
              const SizedBox(height: 40),

              // --- Circular Icon Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCircularButton( context: context, icon: Icons.drive_eta_rounded, label: 'My Drives', backgroundColor: darkIconBg, iconColor: tealAccent, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const MyDrivesScreen())); }, ),
                  _buildCircularButton( context: context, icon: Icons.mail_outline_rounded, label: 'Messages', backgroundColor: tealAccent, iconColor: darkBackground, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messages screen not implemented yet.'))); }, ),
                  _buildCircularButton( context: context, icon: Icons.list_alt_rounded, label: 'My Trips', backgroundColor: tealAccent, iconColor: darkBackground, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTripsScreen())); }, ),
                  _buildCircularButton( context: context, icon: Icons.search_rounded, label: 'Browse', backgroundColor: darkIconBg, iconColor: tealAccent, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const BrowseTripsScreen())); }, ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Rectangular Buttons Row ---
              Row(
                children: [
                  _buildRectangularButton( context: context, backgroundColor: tealAccent, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTripScreen())); }, child: Text( 'Post a New Trip', style: TextStyle(color: darkBackground, fontWeight: FontWeight.bold), ) ),
                  const SizedBox(width: 16),
                  _buildRectangularButton( context: context, backgroundColor: tealAccent, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const BrowseTripsScreen())); }, child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.search_rounded, color: darkBackground, size: 28), const SizedBox(width: 10), Icon(Icons.check_circle_outline_rounded, color: darkBackground, size: 28), ], ) ),
                ],
              ),
              const SizedBox(height: 40), // Bottom spacing
            ],
          ),
        ),
      ),
    );
  } // End build


  // --- Helper Methods Implementation (MOVED TO END FOR CLARITY) ---
  Widget _buildCircularButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: backgroundColor,
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

   Widget _buildRectangularButton({
    required BuildContext context,
    required Widget child,
    required Color backgroundColor,
    required VoidCallback onTap,
    Border? border,
  }) {
     return Expanded(
       child: GestureDetector(
         onTap: onTap,
         child: Container(
           height: 80,
           decoration: BoxDecoration(
             color: backgroundColor,
             borderRadius: BorderRadius.circular(16),
             border: border,
           ),
           child: Center(child: child),
         ),
       ),
     );
  }
  // --- End Helper Methods ---

} // End HomeScreen Class