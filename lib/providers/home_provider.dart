import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  ChargingSession? _activeSession;
  List<QueueEntry> _queue = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  Timer? _liveTimer;

  // Live Computed Values
  double _liveProgress = 0.0;
  String _liveRemainingTime = '';
  bool _userInQueue = false;

  // Form Values (Moved here to share with Start Button)
  double batteryCapacity = 75.0;
  double chargerPower = 7.4;
  double currentCharge = 20.0;
  double desiredCharge = 80.0;
  double costPerKwh = 7.0;

  ChargingSession? get activeSession => _activeSession;
  List<QueueEntry> get queue => _queue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get liveProgress => _liveProgress;
  String get liveRemainingTime => _liveRemainingTime;
  bool get userInQueue => _userInQueue;

  bool get isChargingAvailable => _activeSession == null && _queue.isEmpty;

  void updateEstimator({double? battery, double? power, double? current, double? desired, double? cost}) {
    if (battery != null) batteryCapacity = battery;
    if (power != null) chargerPower = power;
    if (current != null) currentCharge = current;
    if (desired != null) desiredCharge = desired;
    if (cost != null) costPerKwh = cost;
    notifyListeners();
  }

  void startPolling() {
    fetchData();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchData());
    
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLiveState());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _liveTimer?.cancel();
  }

  Future<void> fetchData() async {
    try {
      _activeSession = await _apiService.getActiveSession();
      _queue = await _apiService.getQueueStatus();
      _userInQueue = _queue.any((e) => e.userId == 'user_1'); 
      _errorMessage = null;
      _updateQueueWaitTimes();
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void _updateLiveState() {
    if (_activeSession == null) {
      _liveProgress = 0.0;
      _liveRemainingTime = '';
      return;
    }

    final now = DateTime.now();
    final startTime = _activeSession!.startTime;
    
    final totalEnergyNeeded = _activeSession!.batteryCapacity * (_activeSession!.desiredCharge - _activeSession!.currentCharge) / 100;
    final totalTimeHours = totalEnergyNeeded / (_activeSession!.chargerPower * 0.85);

    if (totalTimeHours <= 0) {
      _liveProgress = 1.0;
      _liveRemainingTime = 'Done';
      return;
    }

    final elapsedHours = now.difference(startTime).inMilliseconds / 3600000;
    final chargeGain = (elapsedHours / totalTimeHours) * (_activeSession!.desiredCharge - _activeSession!.currentCharge);
    final currentPercentage = min(_activeSession!.currentCharge + chargeGain, _activeSession!.desiredCharge);
    
    final totalRange = _activeSession!.desiredCharge - _activeSession!.currentCharge;
    _liveProgress = totalRange > 0 ? ((currentPercentage - _activeSession!.currentCharge) / totalRange).clamp(0.0, 1.0) : 1.0;

    final remainingCharge = _activeSession!.desiredCharge - currentPercentage;
    if (remainingCharge <= 0) {
      _liveRemainingTime = 'Done';
    } else {
      final remainingEnergy = (_activeSession!.batteryCapacity * remainingCharge) / 100;
      final remainingHours = remainingEnergy / (_activeSession!.chargerPower * 0.85);
      final h = remainingHours.toInt();
      final m = ((remainingHours - h) * 60).toInt();
      _liveRemainingTime = h > 0 ? '${h}h ${m}m' : '${m}m';
    }

    notifyListeners();
  }

  void _updateQueueWaitTimes() {
    if (_queue.isEmpty) return;
    final now = DateTime.now();
    DateTime nextAvailableTime = _activeSession?.estimatedEndTime ?? now;

    _queue = _queue.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final baseWaitMinutes = nextAvailableTime.difference(now).inMinutes;
      final queueWaitMinutes = i * 120;
      return e.copyWith(
        position: i + 1,
        estimatedWaitMinutes: max(0, baseWaitMinutes + queueWaitMinutes),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getEstimate() async {
    return await _apiService.post('/api/sessions/estimate', {
      'batteryCapacity': batteryCapacity,
      'currentCharge': currentCharge,
      'desiredCharge': desiredCharge,
      'chargerPower': chargerPower,
      'costPerKwh': costPerKwh,
    });
  }

  Future<void> startCharging() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (!isChargingAvailable) throw Exception('Charger Unavailable');
      await _apiService.startCharging({
        'batteryCapacity': batteryCapacity,
        'currentCharge': currentCharge,
        'desiredCharge': desiredCharge,
        'chargerPower': chargerPower,
      });
      await fetchData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopCharging() async {
    await _apiService.stopCharging();
    _activeSession = null;
    notifyListeners();
    await fetchData();
  }

  Future<void> toggleQueue() async {
    try {
      if (_userInQueue) {
        // Mock leave
      } else {
        await _apiService.joinQueue();
      }
      await fetchData();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
