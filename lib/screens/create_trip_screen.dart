import 'package:flutter/material.dart';
import 'package:ride_share_app/services/api_service.dart'; // Import your API service
import 'package:intl/intl.dart'; // For date formatting in display
import 'package:geolocator/geolocator.dart'; // For current location
// Import the screen you want to navigate to after posting
// Make sure you create this file (e.g., a simple StatefulWidget for now)
import 'package:ride_share_app/screens/my_trips_screen.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Form field controllers
  final _originAddressController = TextEditingController();
  final _originLatController = TextEditingController();
  final _originLonController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final _destinationLatController = TextEditingController();
  final _destinationLonController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();

  // State variables for date/time picking
  DateTime? _earliestDeparture;
  TimeOfDay? _earliestTime;
  DateTime? _latestDeparture;
  TimeOfDay? _latestTime;

  bool _isLoading = false;
  bool _isGettingLocation = false;

  // --- Date/Time Picker Logic ---
  Future<void> _selectDate(BuildContext context, bool isEarliest) async {
    final DateTime initial = (isEarliest ? _earliestDeparture : _latestDeparture) ?? DateTime.now();
    final DateTime first = DateTime.now().subtract(const Duration(days: 1)); // Allow today
    final DateTime last = DateTime.now().add(const Duration(days: 365));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay initialTime = (isEarliest ? _earliestTime : _latestTime) ?? TimeOfDay.fromDateTime(DateTime.now());
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (pickedTime != null && mounted) {
        setState(() {
          final combinedDateTime = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );

          // Prevent setting time in the past for today
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          final pickedDateOnly = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
          if (pickedDateOnly == todayDate && combinedDateTime.isBefore(now)) {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Cannot select a time in the past.'))
              );
              return; // Don't update if time is in the past
          }


          if (isEarliest) {
            _earliestDeparture = combinedDateTime;
            _earliestTime = pickedTime;
            // Ensure latest is not before earliest
            if (_latestDeparture != null && _latestDeparture!.isBefore(_earliestDeparture!)) {
               _latestDeparture = _earliestDeparture;
               _latestTime = _earliestTime;
            }
          } else {
             // Ensure latest is not before earliest
             if (_earliestDeparture != null && combinedDateTime.isBefore(_earliestDeparture!)){
                ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Latest departure cannot be before earliest departure.'))
                );
             } else {
                _latestDeparture = combinedDateTime;
                _latestTime = pickedTime;
             }
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Select Date & Time';
    return DateFormat('MMM d, yyyy hh:mm a').format(date);
  }
  // --- End Date/Time Picker Logic ---


  // --- Get Current Location Logic ---
  Future<void> _getCurrentLocation() async {
    setState(() { _isGettingLocation = true; });
    String? errorMsg;

    try {
        bool serviceEnabled;
        LocationPermission permission;

        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled && mounted) { // Check mounted before showing snackbar
            errorMsg = 'Location services are disabled.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
            await Geolocator.openLocationSettings(); // Prompt user to open settings
            throw Exception(errorMsg);
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied && mounted) {
              errorMsg = 'Location permissions denied.';
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
              throw Exception(errorMsg);
            }
        }

        if (permission == LocationPermission.deniedForever && mounted) {
            errorMsg = 'Location permissions permanently denied.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
             await Geolocator.openAppSettings(); // Prompt user to open app settings
             throw Exception(errorMsg);
        }

        // Permissions are granted (or GrantedWhenInUse/Always)
        print("Location Permissions granted. Getting position...");
        Position position = await Geolocator.getCurrentPosition();
        print("Position obtained: ${position.latitude}, ${position.longitude}");

        // Update the text controllers
        if (mounted) {
          setState(() {
              _originLatController.text = position.latitude.toStringAsFixed(6);
              _originLonController.text = position.longitude.toStringAsFixed(6);
              // Clear address field, user should verify/enter it or use reverse geocoding
              _originAddressController.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location coordinates updated. Please enter/verify address.'))
              );
          });
           // --- Optional: Reverse Geocoding ---
           /*
           try {
             print("Attempting reverse geocoding...");
             // Add geocoding package dependency: geocoding: ^latest_version
             List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
             print("Placemarks found: ${placemarks.length}");
             if (placemarks.isNotEmpty && mounted) {
               Placemark place = placemarks.first;
               // Construct a readable address - adjust formatting as needed
               String formattedAddress = [place.street, place.locality, place.postalCode, place.country]
                  .where((part) => part != null && part.isNotEmpty)
                  .join(', ');

               setState(() {
                 _originAddressController.text = formattedAddress;
               });
               print("Reverse geocoding successful: $formattedAddress");
             } else {
                 print("No placemarks found for coordinates.");
             }
           } catch (geoError) {
              print("Reverse geocoding failed: $geoError");
              // Don't overwrite address field if reverse geocoding fails
           }
           */
           // --- End Optional: Reverse Geocoding ---
        }

    } catch (e) {
        print("Error in _getCurrentLocation: $e");
        // Use the specific error message if set, otherwise use generic message
        errorMsg = errorMsg ?? "Could not get current location.";
         if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg!), backgroundColor: Theme.of(context).colorScheme.error)
            );
         }
    } finally {
        if (mounted) {
            setState(() { _isGettingLocation = false; });
        }
    }
  }
  // --- End Get Current Location Logic ---


  // --- Form Submission Logic (Corrected Parameter Names) ---
  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      if (_earliestDeparture == null || _latestDeparture == null) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please select departure date/time range.'))
         );
         return;
      }

      setState(() { _isLoading = true; });
      String? errorMessage;

      try {
        // Parse numeric values safely
        final double originLat = double.parse(_originLatController.text.trim());
        final double originLon = double.parse(_originLonController.text.trim());
        final double destLat = double.parse(_destinationLatController.text.trim());
        final double destLon = double.parse(_destinationLonController.text.trim());
        final int seats = int.parse(_seatsController.text.trim());
        final double? price = _priceController.text.trim().isEmpty
             ? null
             : double.tryParse(_priceController.text.trim());

        // Call the API service - Using correct parameter names
        final result = await _apiService.createTripRequest(
          originAddress: _originAddressController.text.trim(), // Correct name
          originLat: originLat,
          originLon: originLon,
          destinationAddress: _destinationAddressController.text.trim(), // Correct name
          destinationLat: destLat,
          destinationLon: destLon,
          departureEarliest: _earliestDeparture!,
          departureLatest: _latestDeparture!,
          seatsNeeded: seats,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          offeredPrice: price,
        );

        // Success!
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                  content: Text('Trip Request created successfully! ID: ${result['id']}'),
                  backgroundColor: Colors.green,
               )
             );
             // Navigate to My Trips screen and replace the current screen
             Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyTripsScreen()) // Ensure MyTripsScreen exists
             );
         }

      } catch (e) {
         errorMessage = e.toString();
         if (errorMessage.startsWith("Exception: ")) {
            errorMessage = errorMessage.substring("Exception: ".length);
         }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
          if (errorMessage != null) {
             showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Failed to Create Trip'),
                  content: Text(errorMessage!),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                  ],
                ),
             );
          }
        }
      }
    }
  }
 // --- End Form Submission Logic ---

  @override
  void dispose() {
    _originAddressController.dispose();
    _originLatController.dispose();
    _originLonController.dispose();
    _destinationAddressController.dispose();
    _destinationLatController.dispose();
    _destinationLonController.dispose();
    _seatsController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Trip Request')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Origin ---
              Text('Origin', style: Theme.of(context).textTheme.titleMedium),
              TextFormField(
                controller: _originAddressController,
                decoration: const InputDecoration(
                    labelText: 'Address / Description',
                    hintText: 'e.g., Main Street Cafe or City Center'),
                validator: (value) => (value?.trim().isEmpty ?? true) ? 'Origin address required' : null,
              ),
              Row(children: [
                 Expanded(child: TextFormField(controller: _originLatController, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lat' : null)),
                 const SizedBox(width: 8),
                 Expanded(child: TextFormField(controller: _originLonController, decoration: const InputDecoration(labelText: 'Lon'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lon' : null)),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _isGettingLocation
                  ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                  : OutlinedButton.icon(
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Use Current Location for Origin'),
                      onPressed: _isLoading ? null : _getCurrentLocation,
                    ),
              ),
              const SizedBox(height: 16),

              // --- Destination ---
              Text('Destination', style: Theme.of(context).textTheme.titleMedium),
              TextFormField(
                 controller: _destinationAddressController,
                 decoration: const InputDecoration(
                     labelText: 'Address / Description',
                     hintText: 'e.g., Airport Terminal B or Oak Street Mall'),
                 validator: (value) => (value?.trim().isEmpty ?? true) ? 'Destination address required' : null,
               ),
              Row(children: [
                 Expanded(child: TextFormField(controller: _destinationLatController, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lat' : null)),
                 const SizedBox(width: 8),
                 // --- CORRECTED TYPO HERE ---
                 Expanded(child: TextFormField(controller: _destinationLonController, decoration: const InputDecoration(labelText: 'Lon'), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid Lon' : null)),
              ]),
               const SizedBox(height: 16),

              // --- Departure Window ---
              Text('Departure Window', style: Theme.of(context).textTheme.titleMedium),
              ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: const Icon(Icons.calendar_today),
                 title: const Text('Earliest Departure'),
                 subtitle: Text(_formatDateTime(_earliestDeparture)),
                 trailing: const Icon(Icons.arrow_drop_down),
                 onTap: _isLoading ? null : () => _selectDate(context, true),
              ),
               ListTile(
                 contentPadding: EdgeInsets.zero,
                 leading: const Icon(Icons.watch_later_outlined),
                 title: const Text('Latest Departure'),
                 subtitle: Text(_formatDateTime(_latestDeparture)),
                 trailing: const Icon(Icons.arrow_drop_down),
                 onTap: _isLoading ? null : () => _selectDate(context, false),
              ),
               const SizedBox(height: 16),

               // --- Seats Needed ---
              TextFormField(
                controller: _seatsController,
                decoration: const InputDecoration(labelText: 'Seats Needed', prefixIcon: Icon(Icons.chair)),
                keyboardType: TextInputType.number,
                validator: (value) {
                   final seats = int.tryParse(value ?? '');
                   if (seats == null || seats <= 0) {
                     return 'Enter a valid number of seats (1 or more)';
                   }
                   return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Optional Fields ---
              TextFormField(
                 controller: _notesController,
                 decoration: const InputDecoration(
                     labelText: 'Notes (Optional)',
                     hintText: 'e.g., Bringing luggage, flexible times',
                     prefixIcon: Icon(Icons.note)),
                 maxLines: 3,
                 textCapitalization: TextCapitalization.sentences,
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _priceController,
                 decoration: const InputDecoration(labelText: 'Offered Price (Optional)', prefixIcon: Icon(Icons.attach_money)),
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 validator: (value) {
                     if (value == null || value.trim().isEmpty) return null;
                     final price = double.tryParse(value.trim());
                     if (price == null) return 'Enter a valid price or leave blank';
                     if (price < 0) return 'Price cannot be negative';
                     return null;
                 }
               ),
              const SizedBox(height: 30),

              // --- Submit Button ---
              _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Post Request'),
                    onPressed: _submitForm,
                  ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}