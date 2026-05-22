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
  Timer? _dataTimer;
  Timer? _progressTimer;

  double _liveProgress = 0.0;
  String _liveRemainingTime = '';
  bool _userInQueue = false;

  ChargingSession? get activeSession => _activeSession;
  List<QueueEntry> get queue => _queue;
  bool get isLoading => _isLoading;
  double get liveProgress => _liveProgress;
  String get liveRemainingTime => _liveRemainingTime;
  bool get userInQueue => _userInQueue;

  void startPolling() {
    fetchData();
    _dataTimer?.cancel();
    _dataTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchData());
    
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLiveProgress());
  }

  void stopPolling() {
    _dataTimer?.cancel();
    _progressTimer?.cancel();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _activeSession = await _apiService.getActiveSession();
    _queue = await _apiService.getQueueStatus();
    _userInQueue = _queue.isNotEmpty; 
    _isLoading = false;
    notifyListeners();
  }

  void _updateLiveProgress() {
    if (_activeSession == null) return;

    final now = DateTime.now();
    final startTime = _activeSession!.startTime;
    final totalTimeHours = _calculateChargingTime(
      _activeSession!.batteryCapacity, 
      _activeSession!.currentCharge, 
      _activeSession!.desiredCharge, 
      _activeSession!.chargerPower
    );

    final elapsedHours = now.difference(startTime).inMilliseconds / 3600000;
    final chargeProgress = (elapsedHours / totalTimeHours) * (_activeSession!.desiredCharge - _activeSession!.currentCharge);
    
    final currentCharge = min(_activeSession!.currentCharge + chargeProgress, _activeSession!.desiredCharge);
    
    final totalRange = _activeSession!.desiredCharge - _activeSession!.currentCharge;
    final currentRange = currentCharge - _activeSession!.currentCharge;
    _liveProgress = totalRange > 0 ? (currentRange / totalRange).clamp(0.0, 1.0) : 1.0;

    final remainingCharge = _activeSession!.desiredCharge - currentCharge;
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

  double _calculateChargingTime(double battery, double current, double desired, double power) {
    final energyNeeded = battery * (desired - current) / 100;
    return energyNeeded / (power * 0.85);
  }

  Future<Map<String, dynamic>> getEstimate(Map<String, dynamic> data) async {
    return await _apiService.post('/api/sessions/estimate', data);
  }

  Future<void> startCharging() async {
    if (_activeSession != null) return;
    await _apiService.startCharging();
    await fetchData();
  }

  Future<void> stopCharging() async {
    _activeSession = null;
    notifyListeners();
    await fetchData();
  }

  Future<void> toggleQueue() async {
    if (_userInQueue) {
      // Logic for leaving queue
    } else {
      await _apiService.joinQueue();
    }
    await fetchData();
  }
}
