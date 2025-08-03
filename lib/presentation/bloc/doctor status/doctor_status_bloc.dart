import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/doctor_model.dart';
import '../../../data/services/firebase_service.dart';
import 'doctor_status_event.dart';
import 'doctor_status_state.dart';

class DoctorStatusBloc extends Bloc<DoctorStatusEvent, DoctorStatusState> {
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<List<Doctor>>? _doctorsSubscription;

  DoctorStatusBloc() : super(DoctorStatusInitial()) {
    on<LoadDoctors>(_onLoadDoctors);
    on<DoctorsUpdated>(_onDoctorsUpdated);
    on<DoctorWentOffline>(_onDoctorWentOffline);
  }

  void _onLoadDoctors(
    LoadDoctors event,
    Emitter<DoctorStatusState> emit,
  ) async {
    emit(DoctorStatusLoading());

    try {
      // Check connectivity
      bool isConnected = await _firebaseService.checkConnectivity();

      if (!isConnected) {
        emit(DoctorStatusError('No internet connection'));
        return;
      }

      // Listen to real-time updates
      _doctorsSubscription?.cancel();
      _doctorsSubscription = _firebaseService.getDoctorsStream().listen(
        (doctors) {
          add(DoctorsUpdated(doctors));
        },
        onError: (error) {
          emit(DoctorStatusError('Failed to load doctors: $error'));
        },
      );
    } catch (e) {
      emit(DoctorStatusError('Failed to load doctors: $e'));
    }
  }

  void _onDoctorsUpdated(
    DoctorsUpdated event,
    Emitter<DoctorStatusState> emit,
  ) async {
    // Check for doctors who went offline
    if (state is DoctorStatusLoaded) {
      final currentState = state as DoctorStatusLoaded;
      final previousDoctors = currentState.doctors;

      for (var previousDoc in previousDoctors) {
        final currentDoc = event.doctors.firstWhere(
          (d) => d.id == previousDoc.id,
          orElse: () =>
              Doctor(id: '', name: '', specialty: '', status: 'offline'),
        );

        if (previousDoc.status == 'online' && currentDoc.status == 'offline') {
          add(DoctorWentOffline(currentDoc.id, currentDoc.name));
        }
      }
    }

    bool isConnected = await _firebaseService.checkConnectivity();
    emit(DoctorStatusLoaded(event.doctors, isConnected: isConnected));
  }

  void _onDoctorWentOffline(
    DoctorWentOffline event,
    Emitter<DoctorStatusState> emit,
  ) {
    // Emit alert state temporarily
    emit(DoctorOfflineAlert(event.doctorName));

    // Return to loaded state after alert
    if (state is DoctorStatusLoaded) {
      final loadedState = state as DoctorStatusLoaded;
      emit(
        DoctorStatusLoaded(
          loadedState.doctors,
          isConnected: loadedState.isConnected,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _doctorsSubscription?.cancel();
    return super.close();
  }
}
