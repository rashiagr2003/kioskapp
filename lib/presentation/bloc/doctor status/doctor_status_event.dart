import '../../../data/models/doctor_model.dart';

abstract class DoctorStatusEvent {}

class LoadDoctors extends DoctorStatusEvent {}

class DoctorsUpdated extends DoctorStatusEvent {
  final List<Doctor> doctors;
  DoctorsUpdated(this.doctors);
}

class DoctorWentOffline extends DoctorStatusEvent {
  final String doctorId;
  final String doctorName;
  DoctorWentOffline(this.doctorId, this.doctorName);
}
