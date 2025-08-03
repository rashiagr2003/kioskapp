import 'appointment_event.dart';

class ResetAppointmentState extends AppointmentEvent {}

// Add these states to your existing states
abstract class AppointmentState {}

class AppointmentInitial extends AppointmentState {}

class AppointmentBooking extends AppointmentState {}

class AppointmentBooked extends AppointmentState {
  final String appointmentId;
  final String patientName;
  final String doctorName;
  final DateTime appointmentDate;
  final String timeSlot;

  AppointmentBooked({
    required this.appointmentId,
    required this.patientName,
    required this.doctorName,
    required this.appointmentDate,
    required this.timeSlot,
  });
}

class AppointmentError extends AppointmentState {
  final String message;
  AppointmentError(this.message);
}
