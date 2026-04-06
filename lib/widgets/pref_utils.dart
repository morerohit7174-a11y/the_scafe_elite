import 'dart:async' show Future;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class SharedPreferenceUtils {
  static late final SharedPreferences instance;
  
  static Future<SharedPreferences> init() async =>
      instance = await SharedPreferences.getInstance();

  //MODEL
  static Future<bool> setModel(String key, dynamic model) async {
    var prefs = instance;
    String modelJson = json.encode(model.toJson()); // Assuming the model has toJson() method
    return prefs.setString(key, modelJson);
  }

  static Future<bool> setModelList(String key, List<dynamic> models) async {
    try {
      List<String> jsonList =
      models.map((e) => json.encode(e.toJson())).toList();

      return instance.setStringList(key, jsonList);
    } catch (e) {
      print("Error saving model list: $e");
      return false;
    }
  }

  static List<T> getModelList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    try {
      final List<String>? jsonList = instance.getStringList(key);

      if (jsonList != null) {
        return jsonList
            .map((e) => fromJson(json.decode(e)))
            .toList();
      }
    } catch (e) {
      print("Error getting model list: $e");
    }

    return [];
  }

  // Retrieve model class from SharedPreferences
  static T? getModel<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final jsonString = instance.getString(key);
      if (jsonString != null) {
        final Map<String, dynamic> decodedJson = json.decode(jsonString);
        return fromJson(decodedJson);
      }
    } catch (e) {
      // Log the exception if needed
      print('Error getting model for key $key: $e');
    }
    return null;
  }

  //GET String
  static String getString(String key, [String? defValue]) {
    return instance.getString(key) ?? defValue ?? "";
  }

  //SET String
  static Future<bool> setString(String key, String value) async {
    var prefs = instance;
    return prefs.setString(key, value);
  }

  //GET bool
  static bool getBool(String key, [bool? defValue]) {
    return instance.getBool(key) ?? defValue ?? false;
  }

  //SET bool
  static Future<bool> setBool(String key, bool value) async {
    var prefs = instance;
    return prefs.setBool(key, value);
  }

  // Store List
  static Future<bool> setList(String key, List<String> list) async {
    var prefs = instance;
    return prefs.setStringList(key, list);
  }

  // Retrieve List
  static List<String> getList(String key, [List<String>? defValue]) {
    return instance.getStringList(key) ?? defValue ?? [];
  }

   static Future<bool> remove(String key) async {
    var prefs = instance;
    return prefs.remove(key);
  }

// CHECK if key exists (optional but useful)
  static bool containsKey(String key) {
    return instance.containsKey(key);
  }

  clearData()async{
    await instance.clear();
  }

}