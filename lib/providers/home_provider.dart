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
  Timer? _pollingTimer;
  Timer? _liveTimer;

  // Live Computed Values
  double _liveProgress = 0.0;
  String _liveRemainingTime = '';
  bool _userInQueue = false;

  ChargingSession? get activeSession => _activeSession;
  List<QueueEntry> get queue => _queue;
  bool get isLoading => _isLoading;
  double get liveProgress => _liveProgress;
  String get liveRemainingTime => _liveRemainingTime;
  bool get userInQueue => _userInQueue;

  // Logic: isChargingAvailable = (no one charging && queue is empty)
  bool get isChargingAvailable => _activeSession == null && _queue.isEmpty;

  void startPolling() {
    fetchData();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetchData());
    
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateLiveState());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _liveTimer?.cancel();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _activeSession = await _apiService.getActiveSession();
    _queue = await _apiService.getQueueStatus();
    _isLoading = false;
    _updateQueueWaitTimes();
    notifyListeners();
  }

  void _updateLiveState() {
    if (_activeSession == null) return;

    final now = DateTime.now();
    final startTime = _activeSession!.startTime;
    
    // logic from calculateChargingTime(data)
    final totalEnergyNeeded = _activeSession!.batteryCapacity * (_activeSession!.desiredCharge - _activeSession!.currentCharge) / 100;
    final totalTimeHours = totalEnergyNeeded / _activeSession!.chargerPower;

    // logic from calculateCurrentCharge(session)
    final elapsedHours = now.difference(startTime).inMilliseconds / 3600000;
    final chargeProgress = (elapsedHours / totalTimeHours) * (_activeSession!.desiredCharge - _activeSession!.currentCharge);
    final currentCharge = min(_activeSession!.currentCharge + chargeProgress, _activeSession!.desiredCharge);
    
    // Update progress bar (0.0 to 1.0)
    final totalRange = _activeSession!.desiredCharge - _activeSession!.currentCharge;
    _liveProgress = totalRange > 0 ? ((currentCharge - _activeSession!.currentCharge) / totalRange).clamp(0.0, 1.0) : 1.0;

    // logic from calculateRemainingTime
    final remainingCharge = _activeSession!.desiredCharge - currentCharge;
    if (remainingCharge <= 0) {
      _liveRemainingTime = 'Done';
      if (now.isAfter(_activeSession!.estimatedEndTime!)) {
        stopCharging(); // auto-end when finished
      }
    } else {
      final remainingEnergy = (_activeSession!.batteryCapacity * remainingCharge) / 100;
      final remainingHours = remainingEnergy / _activeSession!.chargerPower;
      final h = remainingHours.toInt();
      final m = ((remainingHours - h) * 60).toInt();
      _liveRemainingTime = h > 0 ? '${h}h ${m}m' : '${m}m';
    }

    notifyListeners();
  }

  // logic from useQueueManager -> updateQueueTimes
  void _updateQueueWaitTimes() {
    if (_queue.isEmpty) return;
    
    final now = DateTime.now();
    DateTime nextAvailableTime = _activeSession?.estimatedEndTime ?? now;

    _queue = _queue.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      
      final baseWaitMinutes = nextAvailableTime.difference(now).inMinutes;
      final queueWaitMinutes = i * 120; // 2 hours per person ahead
      
      return e.copyWith(
        position: i + 1,
        estimatedWaitMinutes: max(0, baseWaitMinutes + queueWaitMinutes),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getEstimate(Map<String, dynamic> data) async {
    return await _apiService.post('/api/sessions/estimate', data);
  }

  // logic from handleStartCharging
  Future<void> startCharging() async {
    if (isChargingAvailable) {
      await _apiService.startCharging();
      await fetchData();
    } else {
      throw Exception('Charger Unavailable');
    }
  }

  // logic from handleStopCharging
  Future<void> stopCharging() async {
    _activeSession = null;
    notifyListeners();
    await fetchData(); // Immediately update queue times
  }

  // logic from handleJoinQueue
  Future<void> toggleQueue() async {
    if (_userInQueue) {
      // leaveQueue() logic
    } else {
      await _apiService.joinQueue();
    }
    await fetchData();
  }
}
