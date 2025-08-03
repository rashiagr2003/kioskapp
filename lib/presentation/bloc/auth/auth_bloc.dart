import 'auth_event.dart';
import 'auth_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginSuccess>((event, emit) => emit(AuthAuthenticated()));
  }
}
