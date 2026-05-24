import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? Colors.transparent : Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => homeProvider.fetchData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('CURRENTLY CHARGING'),
              const ActiveChargingCard(),
              const SizedBox(height: 32),
              _buildSectionHeader('QUEUE'),
              const QueueCard(),
              const SizedBox(height: 32),
              const EstimatorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2DBE44),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ActiveChargingCard extends StatelessWidget {
  const ActiveChargingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final session = provider.activeSession;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          session == null ? 'No currently charging' : 'Charging: ${session.carModel}',
          style: TextStyle(
            color: session == null ? (isDark ? Colors.grey[400] : Colors.grey[600]) : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class QueueCard extends StatelessWidget {
  const QueueCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final queue = provider.queue;
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Center(
        child: Text(
          queue.isEmpty ? 'Free to go' : '${queue.length} in queue',
          style: TextStyle(
            color: queue.isEmpty ? (isDark ? Colors.grey[400] : Colors.grey[600]) : (isDark ? Colors.white : Colors.black),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class EstimatorCard extends StatefulWidget {
  const EstimatorCard({super.key});

  @override
  State<EstimatorCard> createState() => _EstimatorCardState();
}

class _EstimatorCardState extends State<EstimatorCard> {
  final _batteryController = TextEditingController(text: '75');
  final _chargerController = TextEditingController(text: '7.4');
  final _costController = TextEditingController(text: '7');
  double _currentCharge = 20;
  double _desiredCharge = 80;
  
  Map<String, dynamic>? _results;

  void _calculate() async {
    final res = await context.read<HomeProvider>().getEstimate({
      'batteryCapacity': double.tryParse(_batteryController.text) ?? 75,
      'currentCharge': _currentCharge,
      'desiredCharge': _desiredCharge,
      'chargerPower': double.tryParse(_chargerController.text) ?? 7.4,
      'costPerKwh': double.tryParse(_costController.text) ?? 7,
    });
    setState(() {
      _results = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF2DBE44), size: 28),
              const SizedBox(width: 8),
              Text('Charging Estimator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estimate charging time and cost for your session.',
            style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildInput('Battery (kWh)', _batteryController, isDark)),
              const SizedBox(width: 16),
              Expanded(child: _buildInput('Charger (kW)', _chargerController, isDark)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSliderLabel('Current Charge', _currentCharge.toInt(), isDark),
          Slider(
            value: _currentCharge,
            onChanged: (v) => setState(() {
              _currentCharge = v;
              if (_desiredCharge < _currentCharge) _desiredCharge = _currentCharge;
            }),
            min: 0, max: 100,
            activeColor: const Color(0xFF2DBE44),
          ),
          const SizedBox(height: 12),
          _buildSliderLabel('Desired Charge', _desiredCharge.toInt(), isDark),
          Slider(
            value: _desiredCharge,
            onChanged: (v) => setState(() {
              _desiredCharge = v;
              if (_currentCharge > _desiredCharge) _currentCharge = _desiredCharge;
            }),
            min: 0, max: 100,
            activeColor: const Color(0xFF2DBE44),
          ),
          const SizedBox(height: 20),
          _buildInput('Cost per kWh (₹)', _costController, isDark),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DBE44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Get Estimate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          if (_results != null) _buildResultCard(isDark),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isDark) {
    final timeHours = _results!['timeHours'] as double;
    final energyKwh = _results!['energyKwh'] as double;
    final cost = _results!['cost'] as double;
    final hours = timeHours.toInt();
    final minutes = ((timeHours - hours) * 60).toInt();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141B12) : const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2DBE44).withAlpha(40)),
      ),
      child: Column(
        children: [
          const Text('Estimated Results', style: TextStyle(color: Color(0xFF2DBE44), fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          _buildResultItem(Icons.access_time_rounded, '${hours}h ${minutes}min', 'Time', isDark),
          const SizedBox(height: 24),
          _buildResultItem(Icons.battery_charging_full_rounded, '${energyKwh.toStringAsFixed(1)} kWh', 'Energy', isDark),
          const SizedBox(height: 24),
          _buildResultItem(Icons.currency_rupee_rounded, cost.toStringAsFixed(2), 'Cost', isDark),
        ],
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2DBE44), size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderLabel(String label, int value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('$label: $value%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
    );
  }
}
