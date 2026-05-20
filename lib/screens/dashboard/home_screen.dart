import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';

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
  void dispose() {
    // Note: Provider usually handles this if defined correctly, 
    // but we can explicitly stop if needed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('EV Charge Park', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeProvider>().fetchData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('CURRENTLY CHARGING'),
              const ActiveChargingCard(),
              const SizedBox(height: 24),
              _buildSectionHeader('QUEUE'),
              const QueueList(),
              const SizedBox(height: 24),
              const EstimatorCard(),
              const SizedBox(height: 80), // Space for buttons
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const ActionButtons(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class ActiveChargingCard extends StatelessWidget {
  const ActiveChargingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<HomeProvider>().activeSession;
    if (session == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(child: Text('No currently charging', style: TextStyle(color: Colors.grey[600]))),
        ),
      );
    }

    // Simple progress calc for demo
    final total = session.estimatedEndTime!.difference(session.startTime).inSeconds;
    final elapsed = DateTime.now().difference(session.startTime).inSeconds;
    double progress = (elapsed / total).clamp(0.0, 1.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: Colors.green[100], child: const Icon(Icons.electric_car, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.carModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('By ${session.userName}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  session.estimatedEndTime!.difference(DateTime.now()).inMinutes > 0
                      ? '${session.estimatedEndTime!.difference(DateTime.now()).inMinutes}m'
                      : 'Done',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class QueueList extends StatelessWidget {
  const QueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<HomeProvider>().queue;
    if (queue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Free to go', style: TextStyle(color: Colors.green)),
      );
    }

    return Column(
      children: queue.map((entry) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: Text('${entry.position}', style: const TextStyle(fontSize: 12)),
          ),
          title: Text(entry.userName),
          subtitle: Text(entry.carModel),
          trailing: Text('~${entry.estimatedWaitMinutes}m', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      )).toList(),
    );
  }
}

class EstimatorCard extends StatefulWidget {
  const EstimatorCard({super.key});

  @override
  State<EstimatorCard> createState() => _EstimatorCardState();
}

class _EstimatorCardState extends State<EstimatorCard> {
  double _currentCharge = 20;
  double _desiredCharge = 80;
  final _batteryController = TextEditingController(text: '75');
  
  String? _estTime, _estEnergy, _estCost;

  void _calculate() async {
    final res = await context.read<HomeProvider>().getEstimate({
      'batteryCapacity': double.tryParse(_batteryController.text) ?? 75,
      'currentCharge': _currentCharge,
      'desiredCharge': _desiredCharge,
      'chargerPower': 11.0,
      'costPerKwh': 7.0,
    });
    setState(() {
      _estTime = '${res['timeHours'].toStringAsFixed(1)}h';
      _estEnergy = '${res['energyKwh'].toStringAsFixed(1)} kWh';
      _estCost = '₹${res['cost'].toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('Charging Estimator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Battery Capacity (kWh)', style: TextStyle(fontSize: 12)),
            TextField(controller: _batteryController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Text('Current Charge: ${_currentCharge.toInt()}%', style: const TextStyle(fontSize: 12)),
            Slider(
              value: _currentCharge,
              onChanged: (v) => setState(() {
                _currentCharge = v;
                if (_desiredCharge < _currentCharge) _desiredCharge = _currentCharge;
              }),
              min: 0, max: 100,
            ),
            Text('Desired Charge: ${_desiredCharge.toInt()}%', style: const TextStyle(fontSize: 12)),
            Slider(
              value: _desiredCharge,
              onChanged: (v) => setState(() {
                _desiredCharge = v;
                if (_currentCharge > _desiredCharge) _currentCharge = _desiredCharge;
              }),
              min: 0, max: 100,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _calculate, child: const Text('Get Estimate')),
            ),
            if (_estTime != null) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultItem(Icons.access_time, _estTime!, 'Time'),
                  _buildResultItem(Icons.battery_charging_full, _estEnergy!, 'Energy'),
                  _buildResultItem(Icons.currency_rupee, _estCost!, 'Cost'),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    // Simplified logic for demo
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.bolt), 
              label: const Text('Start Charging'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.people), 
              label: const Text('Join Queue'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
