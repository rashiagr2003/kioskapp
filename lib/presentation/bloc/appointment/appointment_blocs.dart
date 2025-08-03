import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/firebase_service.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

// Update your existing AppointmentBloc
class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final FirebaseService _firebaseService = FirebaseService();

  AppointmentBloc() : super(AppointmentInitial()) {
    on<BookAppointment>(_onBookAppointment);
    on<ResetAppointmentState>(_onResetAppointmentState);
  }

  void _onBookAppointment(
    BookAppointment event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentBooking());

    try {
      bool success = await _firebaseService.bookAppointment(
        patientName: event.patientName,
        phoneNumber: event.phoneNumber,
        symptoms: event.symptoms,
        doctorId: event.doctorId,
        appointmentDate: event.appointmentDate,
        timeSlot: event.timeSlot,
      );

      if (success) {
        emit(
          AppointmentBooked(
            appointmentId: DateTime.now().millisecondsSinceEpoch.toString(),
            patientName: event.patientName,
            doctorName: 'Dr. Selected', // You can get this from doctor ID
            appointmentDate: event.appointmentDate,
            timeSlot: event.timeSlot,
          ),
        );
      } else {
        emit(AppointmentError('Failed to book appointment. Please try again.'));
      }
    } catch (e) {
      emit(AppointmentError('An error occurred: $e'));
    }
  }

  void _onResetAppointmentState(
    ResetAppointmentState event,
    Emitter<AppointmentState> emit,
  ) {
    emit(AppointmentInitial());
  }
}
