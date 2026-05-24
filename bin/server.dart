import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:crypto/crypto.dart';

class Database {
  static Db? _db;
  static DbCollection? _users;
  static DbCollection? _sessions;
  static DbCollection? _queue;

  static Future<void> connect() async {
    try {
      stdout.writeln("Connecting to MongoDB...");
      _db = await Db.create("mongodb+srv://Gautham:sdqfblXnOhFv9PXN@clustere.vruatel.mongodb.net/ev_app?retryWrites=true&w=majority&safeAtlas=true");
      await _db!.open(secure: true);
      
      _users = _db!.collection("users");
      _sessions = _db!.collection("sessions");
      _queue = _db!.collection("queue");
      
      await _users!.createIndex(key: 'username', unique: true);
      stdout.writeln("Connected to MongoDB Atlas successfully.");
    } catch (e) {
      stdout.writeln("Error connecting to MongoDB: $e");
      rethrow;
    }
  }

  static DbCollection get users => _users!;
  static DbCollection get sessions => _sessions!;
  static DbCollection get queue => _queue!;
}

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

Future<Response> _registerHandler(Request request) async {
  try {
    final payload = jsonDecode(await request.readAsString());
    final username = payload['username'];
    final password = payload['password'];
    final carModel = payload['carModel'];
    final parkingSlot = payload['parkingSlot'];

    final existingUser = await Database.users.findOne(where.eq('username', username));
    if (existingUser != null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Username already exists'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    await Database.users.insertOne({
      'username': username,
      'password': hashPassword(password),
      'carModel': carModel,
      'parkingSlot': parkingSlot,
      'created_at': DateTime.now().toIso8601String(),
    });

    return Response.ok(
      jsonEncode({'message': 'User registered successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Server error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> _loginHandler(Request request) async {
  try {
    final payload = jsonDecode(await request.readAsString());
    final username = payload['username'];
    final password = payload['password'];

    final user = await Database.users.findOne(where.eq('username', username));
    if (user == null || user['password'] != hashPassword(password)) {
      return Response.forbidden(
        jsonEncode({'error': 'Invalid username or password'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({
        'message': 'Login successful',
        'token': 'mock_jwt_token_${user['_id']}',
        'id': user['_id'].toString(),
        'username': user['username'],
        'carModel': user['carModel'],
        'parkingSlot': user['parkingSlot'],
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Server error: $e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> _activeSessionHandler(Request request) async {
  return Response.ok(jsonEncode({
    'session': null
  }), headers: {'Content-Type': 'application/json'});
}

Future<Response> _queueStatusHandler(Request request) async {
  return Response.ok(jsonEncode({
    'queue': []
  }), headers: {'Content-Type': 'application/json'});
}

Future<Response> _estimateHandler(Request request) async {
  final payload = jsonDecode(await request.readAsString());
  final double battery = (payload['batteryCapacity'] as num).toDouble();
  final double current = (payload['currentCharge'] as num).toDouble();
  final double desired = (payload['desiredCharge'] as num).toDouble();
  final double power = (payload['chargerPower'] as num).toDouble();
  final double costPerKwh = (payload['costPerKwh'] as num).toDouble();

  final double energyNeeded = battery * (desired - current) / 100;
  final double hours = energyNeeded / (power * 0.85); // 85% efficiency
  
  return Response.ok(jsonEncode({
    'success': true,
    'timeHours': hours,
    'energyKwh': energyNeeded,
    'cost': energyNeeded * costPerKwh,
  }), headers: {'Content-Type': 'application/json'});
}

Future<Response> _startChargingHandler(Request request) async {
  try {
    return Response.ok(
      jsonEncode({'message': 'Charging started successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _joinQueueHandler(Request request) async {
  try {
    return Response.ok(
      jsonEncode({'message': 'Joined queue successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

Future<Response> _updateUserHandler(Request request) async {
  try {
    await request.readAsString();
    return Response.ok(
      jsonEncode({'message': 'Profile updated successfully'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
  }
}

final _router = Router()
  ..get('/test', (Request request) => Response.ok('Server is working!'))
  ..post('/register', _registerHandler)
  ..post('/login', _loginHandler)
  ..get('/api/sessions/active', _activeSessionHandler)
  ..get('/api/queue/status', _queueStatusHandler)
  ..post('/api/sessions/estimate', _estimateHandler)
  ..get('/api/sessions/history', _historyHandler)
  ..post('/api/sessions/start', _startChargingHandler)
  ..post('/api/queue/join', _joinQueueHandler)
  ..post('/api/user/update', _updateUserHandler);

Future<Response> _historyHandler(Request request) async {
  return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
}

void main(List<String> args) async {
  try {
    await Database.connect();
    
    final handler = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addMiddleware((innerHandler) {
          return (request) async {
            stdout.writeln('DEBUG: Received ${request.method} request for ${request.url}');
            return await innerHandler(request);
          };
        })
        .addHandler(_router.call);

    final port = int.parse(Platform.environment['PORT'] ?? '3001');
    final server = await serve(handler, InternetAddress.anyIPv4, port);
    stdout.writeln('Server listening on port ${server.port}');
  } catch (e) {
    stdout.writeln('Failed to start server: $e');
  }
}
