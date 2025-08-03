import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk_app/main.dart';

import '../../core/utils/response_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _inactivityTimer;
  final int _inactivityTimeout = 120; // 2 minutes

  @override
  // In your home screen initState
  @override
  void initState() {
    super.initState();
    _initializeKioskMode();
    _resetInactivityTimer();
    _enableKioskMode();
  }

  void _initializeKioskMode() async {
    // Check if launched from boot
    final hasDeviceAdmin = await KioskChannel.checkDeviceAdmin();

    if (!hasDeviceAdmin) {
      // Request device admin permission
      await KioskChannel.requestDeviceAdmin();
    } else {
      // Enable kiosk mode
      await KioskChannel.enableKioskMode();
    }
  }

  void _showExitKioskConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Kiosk Mode'),
        content: Text('Are you sure you want to exit kiosk mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _disableKioskMode();
    }
  }

  Future<void> _disableKioskMode() async {
    const channel = MethodChannel('com.kiosk/native');
    try {
      await channel.invokeMethod('disableKioskMode');
      print('Kiosk mode disabled');
    } catch (e) {
      print('Failed to disable kiosk mode: $e');
    }
  }

  void _enableKioskMode() async {
    try {
      await KioskChannel.enableKioskMode();
      print('Kiosk mode enabled');
    } catch (e) {
      print('Failed to enable kiosk mode: $e');
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _inactivityTimeout), () {
      _lockApp();
    });
  }

  void _lockApp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Session Locked'),
        content: Text('The app has been locked due to inactivity.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[50]!, Colors.white],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _buildMainContent(context),
                      ),
                    ),
                    _buildFooter(context),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 🔓 Unlock / back icon to disable kiosk
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[800]),
            onPressed:
                _showExitKioskConfirmation, // <-- method to confirm & exit kiosk
          ),
          SizedBox(width: 12),

          // App title area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      16,
                    ),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Telemedicine Kiosk',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_hospital, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight * 0.6,
            maxHeight: constraints.maxHeight,
          ),
          child: ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout(context)
              : _buildTabletDesktopLayout(context),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          _buildWelcomeCard(context),
          SizedBox(height: 30),
          _buildActionButton(
            context,
            'Book Appointment',
            Icons.calendar_month,
            Colors.green,
            () => context.go('/book-appointment'),
          ),
          SizedBox(height: 16),
          _buildActionButton(
            context,
            'Doctor Status',
            Icons.people,
            Colors.blue,
            () => context.go('/doctor-status'),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWelcomeCard(context),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Book Appointment',
                Icons.calendar_month,
                Colors.green,
                () => context.go('/book-appointment'),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: _buildActionButton(
                context,
                'Doctor Status',
                Icons.people,
                Colors.blue,
                () => context.go('/doctor-status'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety,
              size: ResponsiveHelper.isMobile(context) ? 48 : 64,
              color: Colors.blue[600],
            ),
            SizedBox(height: 12),
            Text(
              'Your Health, Our Priority',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              'Access healthcare services quickly and easily through our telemedicine platform.',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.isMobile(context) ? double.infinity : 300,
      ),
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 8,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: ResponsiveHelper.isMobile(context) ? 40 : 48,
                    color: color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      18,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              DateTime.now().toString().split(' ')[0],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              'Kiosk ID: KSK001',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
