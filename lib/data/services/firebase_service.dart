import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simple initialization
  Future<void> initialize() async {
    print("🚀 FirebaseService initialized");
  }

  // Check connectivity
  Future<bool> checkConnectivity() async {
    try {
      await _firestore.collection('doctors').limit(1).get();
      return true;
    } catch (e) {
      print('❌ Connectivity check failed: $e');
      return false;
    }
  }

  // Get doctors stream with proper error handling
  Stream<List<Doctor>> getDoctorsStream() {
    print("📡 Starting doctors stream...");

    return _firestore
        .collection('doctors')
        .snapshots()
        .map((snapshot) {
          print("📊 Got ${snapshot.docs.length} doctors from Firestore");

          return snapshot.docs.map((doc) {
            try {
              Map<String, dynamic> data = doc.data();
              print("👨‍⚕️ Processing doctor: ${data['name']}");

              return Doctor(
                id: doc.id,
                name: data['name']?.toString() ?? 'Unknown Doctor',
                specialty: data['specialty']?.toString() ?? 'General',
                status: data['status']?.toString() ?? 'offline',
                rating: _parseDouble(data['rating']),
                lastSeen: _parseDateTime(data['lastSeen']),
              );
            } catch (e) {
              print("❌ Error processing doctor ${doc.id}: $e");
              // Return a default doctor if parsing fails
              return Doctor(
                id: doc.id,
                name: 'Error Loading Doctor',
                specialty: 'Unknown',
                status: 'offline',
                rating: 0.0,
                lastSeen: DateTime.now(),
              );
            }
          }).toList();
        })
        .handleError((error) {
          print("❌ Firestore stream error: $error");
          throw error;
        });
  }

  // Helper method to safely parse double
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Helper method to safely parse DateTime
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return DateTime.now();
  }

  // Simple appointment booking
  Future<bool> bookAppointment({
    required String patientName,
    required String phoneNumber,
    required String symptoms,
    required String doctorId,
    required DateTime appointmentDate,
    required String timeSlot,
  }) async {
    try {
      print("📝 Booking appointment for $patientName");

      await _firestore.collection('appointments').add({
        'patient_name': patientName,
        'phone_number': phoneNumber,
        'symptoms': symptoms,
        'doctor_id': doctorId,
        'appointment_date': appointmentDate.toIso8601String(),
        'time_slot': timeSlot,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'device_id': 'KIOSK_001',
      });

      print("✅ Appointment booked successfully");
      return true;
    } catch (e) {
      print("❌ Error booking appointment: $e");
      return false;
    }
  }

  // Simple session logging
  Future<void> logUserSession({
    required String sessionId,
    required DateTime startTime,
    DateTime? endTime,
  }) async {
    try {
      await _firestore.collection('user_sessions').doc(sessionId).set({
        'device_id': 'KIOSK_001',
        'start_time': Timestamp.fromDate(startTime),
        'end_time': endTime != null ? Timestamp.fromDate(endTime) : null,
        'status': endTime != null ? 'completed' : 'active',
      });
      print("📊 Session logged: $sessionId");
    } catch (e) {
      print("❌ Error logging session: $e");
    }
  }
}
