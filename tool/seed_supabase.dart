// ignore_for_file: avoid_print
// Seed les références (catégories + aliments) dans Postgres/Supabase via
// PostgREST, en réutilisant le catalogue applicatif (FoodSeedData).
//
// Usage (PowerShell) :
//   $env:SUPABASE_URL="https://<ref>.supabase.co"
//   $env:SUPABASE_SERVICE_ROLE="<service_role_key>"
//   dart run tool/seed_supabase.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:vitatrack/data/datasources/food_seed_data.dart';

Future<void> main() async {
  final url = Platform.environment['SUPABASE_URL'];
  final serviceKey = Platform.environment['SUPABASE_SERVICE_ROLE'];
  if (url == null || serviceKey == null) {
    stderr.writeln('SUPABASE_URL et SUPABASE_SERVICE_ROLE requis.');
    exitCode = 2;
    return;
  }
  final headers = {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates,return=minimal',
  };

  Future<int> post(String table, List<Map<String, dynamic>> rows) async {
    final res = await http.post(
      Uri.parse('$url/rest/v1/$table'),
      headers: headers,
      body: jsonEncode(rows),
    );
    print('$table: HTTP ${res.statusCode} ${res.body}');
    return res.statusCode;
  }

  final categories = FoodSeedData.categories
      .map((c) => {
            'id': c.id,
            'name': c.name,
            'emoji': c.emoji,
            'data': c.toMap(),
          })
      .toList();

  final foods = FoodSeedData.foods
      .map((f) => {
            'id': f.id,
            'name': f.name,
            'category_id': f.categoryId,
            'is_active': f.isActive,
            'image_url': f.imageUrl,
            'data': f.toMap(),
          })
      .toList();

  await post('categories', categories);
  await post('foods', foods);
  print('Seed terminé : ${categories.length} catégories, ${foods.length} aliments.');
}
