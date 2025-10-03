import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/trip_response.dart';
import '../../services/trip_service.dart';
import 'create_trip_page.dart';

class TripsListPage extends StatefulWidget {
  const TripsListPage({super.key});

  @override
  State<TripsListPage> createState() => _TripsListPageState();
}

class _TripsListPageState extends State<TripsListPage> {
  final TripService _tripService = TripService();
  List<TripResponse> trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.getInt("schoolId") ?? 1;

    final result = await _tripService.getTripsBySchool(schoolId);

    setState(() {
      trips = result;
      _loading = false;
    });
  }

  Future<void> _openCreateTrip() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripPage()),
    );

    if (created == true) {
      _loadTrips(); // ✅ refresh trips after creating
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trips")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
              ? const Center(child: Text("No trips found."))
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return Card(
                        child: ListTile(
                          title: Text(trip.tripName),
                          subtitle: Text("Vehicle: ${trip.vehicleNumber}"),
                          trailing: Text("No: ${trip.tripNumber}"),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTrip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
