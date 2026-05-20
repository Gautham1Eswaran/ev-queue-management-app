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
    'session': {
      'id': '1',
      'userId': '123',
      'userName': 'David Evans',
      'carModel': 'Rivian R1T',
      'startTime': DateTime.now().subtract(Duration(minutes: 45)).toIso8601String(),
      'estimatedEndTime': DateTime.now().add(Duration(minutes: 38)).toIso8601String(),
      'currentCharge': 35.5,
      'desiredCharge': 80.0,
      'batteryCapacity': 135.0,
      'chargerPower': 11.0,
    }
  }), headers: {'Content-Type': 'application/json'});
}

Future<Response> _queueStatusHandler(Request request) async {
  return Response.ok(jsonEncode({
    'queue': [
      {
        'userId': 'q1',
        'userName': 'Eva Green',
        'carModel': 'Hyundai Ioniq 5',
        'position': 1,
        'joinedAt': DateTime.now().subtract(Duration(minutes: 20)).toIso8601String(),
        'estimatedWaitMinutes': 30,
      },
      {
        'userId': 'q2',
        'userName': 'James Miller',
        'carModel': 'Tesla Model 3',
        'position': 2,
        'joinedAt': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'estimatedWaitMinutes': 65,
      }
    ]
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

final _router = Router()
  ..get('/test', (Request request) => Response.ok('Server is working!'))
  ..post('/register', _registerHandler)
  ..post('/login', _loginHandler)
  ..get('/api/sessions/active', _activeSessionHandler)
  ..get('/api/queue/status', _queueStatusHandler)
  ..post('/api/sessions/estimate', _estimateHandler)
  ..get('/api/sessions/history', _historyHandler);

Future<Response> _historyHandler(Request request) async {
  return Response.ok(jsonEncode([
    {
      'id': 'h1',
      'startTime': DateTime.now().subtract(Duration(days: 1, hours: 2)).toIso8601String(),
      'endTime': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'energyConsumedKWh': 45.5,
      'cost': 318.5,
    },
    {
      'id': 'h2',
      'startTime': DateTime.now().subtract(Duration(days: 3, hours: 4)).toIso8601String(),
      'endTime': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
      'energyConsumedKWh': 30.2,
      'cost': 211.4,
    },
    {
      'id': 'h3',
      'startTime': DateTime.now().subtract(Duration(days: 35, hours: 1)).toIso8601String(),
      'endTime': DateTime.now().subtract(Duration(days: 35)).toIso8601String(),
      'energyConsumedKWh': 55.0,
      'cost': 385.0,
    }
  ]), headers: {'Content-Type': 'application/json'});
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
