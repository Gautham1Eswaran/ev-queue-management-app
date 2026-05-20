import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  ChargingSession? _activeSession;
  List<QueueEntry> _queue = [];
  final bool _isLoading = false;
  Timer? _timer;

  ChargingSession? get activeSession => _activeSession;
  List<QueueEntry> get queue => _queue;
  bool get isLoading => _isLoading;

  void startPolling() {
    fetchData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchData());
  }

  void stopPolling() {
    _timer?.cancel();
  }

  Future<void> fetchData() async {
    _activeSession = await _apiService.getActiveSession();
    _queue = await _apiService.getQueueStatus();
    notifyListeners();
  }

  Future<Map<String, dynamic>> getEstimate(Map<String, dynamic> data) async {
    return await _apiService.post('/api/sessions/estimate', data);
  }
}
