import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/response_helper.dart';
import '../../data/models/doctor_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/appointment/appointment_blocs.dart';
import '../bloc/appointment/appointment_event.dart';
import '../bloc/appointment/appointment_state.dart';
import '../bloc/doctor status/doctor_status_bloc.dart';
import '../bloc/doctor status/doctor_status_event.dart';
import '../bloc/doctor status/doctor_status_state.dart';

class BookAppointmentScreen extends StatefulWidget {
  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _symptomsController = TextEditingController();

  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    // Load available doctors from Firebase
    context.read<DoctorStatusBloc>().add(LoadDoctors());
  }

  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Appointment'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (context, state) {
            if (state is AppointmentBooked) {
              _showSuccessDialog(state);
            } else if (state is AppointmentError) {
              _showErrorSnackBar(state.message);
            }
          },
          builder: (context, appointmentState) {
            return BlocBuilder<DoctorStatusBloc, DoctorStatusState>(
              builder: (context, doctorState) {
                return SingleChildScrollView(
                  padding: ResponsiveHelper.getResponsivePadding(context),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Patient Information'),
                        SizedBox(height: 16),
                        _buildPatientInfoSection(),
                        SizedBox(height: 32),
                        _buildSectionTitle('Appointment Details'),
                        SizedBox(height: 16),
                        _buildAppointmentDetailsSection(doctorState),
                        SizedBox(height: 32),
                        _buildBookButton(appointmentState),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsSection(DoctorStatusState doctorState) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDoctorSelection(doctorState),
            SizedBox(height: 20),
            _buildDateSelection(),
            SizedBox(height: 20),
            _buildTimeSlotSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSelection(DoctorStatusState doctorState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Doctor',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        if (doctorState is DoctorStatusLoading)
          Container(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (doctorState is DoctorStatusLoaded)
          _buildDoctorList(
            doctorState.doctors.where((d) => d.status == 'online').toList(),
          )
        else if (doctorState is DoctorStatusError)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load doctors. Please check your connection.',
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<DoctorStatusBloc>().add(LoadDoctors());
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(16),
            child: Text('Loading doctors...'),
          ),
      ],
    );
  }

  Widget _buildDoctorList(List<Doctor> availableDoctors) {
    if (availableDoctors.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'No doctors are currently available online.',
              style: TextStyle(color: Colors.orange[800]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: availableDoctors.map((doctor) {
          return RadioListTile<String>(
            title: Text(doctor.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.specialty),
                if (doctor.rating != null)
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        doctor.rating.toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
            value: doctor.id,
            groupValue: _selectedDoctor,
            onChanged: (value) => setState(() => _selectedDoctor = value),
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: Colors.green[700]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookButton(AppointmentState appointmentState) {
    bool isLoading = appointmentState is AppointmentBooking;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _bookAppointment,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.blue[600],
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'BOOKING...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
                'BOOK APPOINTMENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _bookAppointment() async {
    if (!_validateForm()) return;

    context.read<AppointmentBloc>().add(
      BookAppointment(
        patientName: _patientNameController.text,
        phoneNumber: _phoneController.text,
        symptoms: _symptomsController.text,
        doctorId: _selectedDoctor!,
        appointmentDate: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
      ),
    );
  }

  void _showSuccessDialog(AppointmentBooked state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Appointment Booked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your appointment has been successfully booked with Firebase.',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Appointment ID: ${state.appointmentId}'),
                  Text('Patient: ${state.patientName}'),
                  Text('Doctor: ${state.doctorName}'),
                  Text(
                    'Date: ${state.appointmentDate.day}/${state.appointmentDate.month}/${state.appointmentDate.year}',
                  ),
                  Text('Time: ${state.timeSlot}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentBloc>().add(ResetAppointmentState());
              context.go('/home');
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Keep all your existing methods like _buildPatientInfoSection, _buildDateSelection, etc.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              controller: _patientNameController,
              label: 'Patient Name',
              icon: Icons.person,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter patient name' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter phone number' : null,
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _symptomsController,
              label: 'Symptoms / Reason for Visit',
              icon: Icons.medical_services,
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please describe symptoms' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 16),
      validator: validator,
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[600]),
                SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select Date',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 4,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = _timeSlots[index];
            final isSelected = _selectedTimeSlot == timeSlot;

            return InkWell(
              onTap: () => setState(() => _selectedTimeSlot = timeSlot),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                  ),
                ),
                child: Center(
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedDoctor == null) {
      _showErrorSnackBar('Please select a doctor');
      return false;
    }
    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a date');
      return false;
    }
    if (_selectedTimeSlot == null) {
      _showErrorSnackBar('Please select a time slot');
      return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[600]),
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _phoneController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }
}
