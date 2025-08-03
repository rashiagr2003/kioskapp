import '../../../data/models/doctor_model.dart';

abstract class DoctorStatusState {}

class DoctorStatusInitial extends DoctorStatusState {}

class DoctorStatusLoading extends DoctorStatusState {}

class DoctorStatusLoaded extends DoctorStatusState {
  final List<Doctor> doctors;
  final bool isConnected;
  DoctorStatusLoaded(this.doctors, {this.isConnected = true});
}

class DoctorStatusError extends DoctorStatusState {
  final String message;
  DoctorStatusError(this.message);
}

class DoctorOfflineAlert extends DoctorStatusState {
  final String doctorName;
  DoctorOfflineAlert(this.doctorName);
}
