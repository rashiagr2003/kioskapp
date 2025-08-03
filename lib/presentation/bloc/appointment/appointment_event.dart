abstract class AppointmentEvent {}

class BookAppointment extends AppointmentEvent {
  final String patientName;
  final String phoneNumber;
  final String symptoms;
  final String doctorId;
  final DateTime appointmentDate;
  final String timeSlot;

  BookAppointment({
    required this.patientName,
    required this.phoneNumber,
    required this.symptoms,
    required this.doctorId,
    required this.appointmentDate,
    required this.timeSlot,
  });
}
