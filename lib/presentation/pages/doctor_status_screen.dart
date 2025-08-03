import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk_app/core/utils/response_helper.dart';
import 'package:kiosk_app/data/models/doctor_model.dart';

import '../bloc/doctor status/doctor_status_bloc.dart';
import '../bloc/doctor status/doctor_status_event.dart';
import '../bloc/doctor status/doctor_status_state.dart';

class DoctorStatusScreen extends StatefulWidget {
  @override
  _DoctorStatusScreenState createState() => _DoctorStatusScreenState();
}

class _DoctorStatusScreenState extends State<DoctorStatusScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorStatusBloc>().add(LoadDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<DoctorStatusBloc>().add(LoadDoctors());
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: BlocConsumer<DoctorStatusBloc, DoctorStatusState>(
          listener: (context, state) {
            if (state is DoctorOfflineAlert) {
              _showDoctorOfflineAlert(state.doctorName);
            } else if (state is DoctorStatusError) {
              _showErrorSnackBar(state.message);
            }
          },
          builder: (context, state) {
            if (state is DoctorStatusLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is DoctorStatusLoaded) {
              return Padding(
                padding: ResponsiveHelper.getResponsivePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConnectionStatus(state.isConnected),
                    SizedBox(height: 16),
                    _buildStatusSummary(context, state.doctors),
                    SizedBox(height: 20),
                    Expanded(child: _buildDoctorsList(context, state.doctors)),
                  ],
                ),
              );
            } else if (state is DoctorStatusError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(state.message, style: TextStyle(fontSize: 18)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DoctorStatusBloc>().add(LoadDoctors());
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return Container(); // For DoctorStatusInitial or fallback
          },
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isConnected ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
          SizedBox(width: 8),
          Text(
            isConnected ? 'Connected to Firebase' : 'Offline Mode',
            style: TextStyle(
              color: isConnected ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDoctorOfflineAlert(String doctorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Doctor Offline'),
          ],
        ),
        content: Text(
          '$doctorName has gone offline and is no longer available for appointments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            context.read<DoctorStatusBloc>().add(LoadDoctors());
          },
        ),
      ),
    );
  }

  Widget _buildStatusSummary(BuildContext context, List<Doctor> doctors) {
    final onlineDoctors = doctors.where((d) => d.status == 'online').length;
    final busyDoctors = doctors.where((d) => d.status == 'busy').length;
    final offlineDoctors = doctors.where((d) => d.status == 'offline').length;

    return Card(
      elevation: 6,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Availability Summary',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 16),
            ResponsiveHelper.isMobile(context)
                ? _buildMobileSummaryCards(
                    onlineDoctors,
                    busyDoctors,
                    offlineDoctors,
                  )
                : _buildDesktopSummaryCards(
                    onlineDoctors,
                    busyDoctors,
                    offlineDoctors,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSummaryCards(int online, int busy, int offline) {
    return Column(
      children: [
        _buildSummaryCard('Available', online, Colors.blue, Icons.check_circle),
        SizedBox(height: 12),
        _buildSummaryCard('Busy', busy, Colors.orange, Icons.access_time),
        SizedBox(height: 12),
        _buildSummaryCard('Offline', offline, Colors.red, Icons.cancel),
      ],
    );
  }

  Widget _buildDesktopSummaryCards(int online, int busy, int offline) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Available',
            online,
            Colors.blue,
            Icons.check_circle,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Busy',
            busy,
            Colors.orange,
            Icons.access_time,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Offline',
            offline,
            Colors.red,
            Icons.cancel,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '$count doctors',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsList(BuildContext context, List<Doctor> doctors) {
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No doctors available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildDoctorCard(context, doctor),
        );
      },
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: ResponsiveHelper.isMobile(context)
            ? _buildMobileDoctorCard(doctor, context)
            : _buildDesktopDoctorCard(doctor, context),
      ),
    );
  }

  Widget _buildMobileDoctorCard(Doctor doctor, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDoctorAvatar(doctor),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctor.specialty,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _buildStatusChip(doctor.status),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRatingWidget(doctor.rating),
            if (doctor.status == 'online')
              ElevatedButton(
                style: ButtonStyle(),
                onPressed: () => _bookAppointment(doctor, context),
                child: Text('Book Appointment'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopDoctorCard(Doctor doctor, BuildContext context) {
    return Row(
      children: [
        _buildDoctorAvatar(doctor),
        SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                doctor.specialty,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(child: _buildRatingWidget(doctor.rating)),
        _buildStatusChip(doctor.status),
        SizedBox(width: 16),
        if (doctor.status == 'online')
          ElevatedButton(
            onPressed: () => _bookAppointment(doctor, context),
            child: Text('Book Appointment'),
          ),
      ],
    );
  }

  void _bookAppointment(Doctor doctor, BuildContext context) {
    context.go('/book-appointment');
  }

  Widget _buildDoctorAvatar(Doctor doctor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getStatusColor(doctor.status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _getStatusColor(doctor.status), width: 2),
      ),
      child: Icon(
        Icons.person,
        size: 30,
        color: _getStatusColor(doctor.status),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingWidget(double? rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: 20),
        SizedBox(width: 4),
        Text(
          rating.toString(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.blue;
      case 'busy':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
