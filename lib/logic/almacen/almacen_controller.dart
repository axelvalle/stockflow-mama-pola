import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/entities/almacen.dart';
import '../../model/repository/almacen_repository.dart';

class AlmacenController with ChangeNotifier {
  final AlmacenRepository _repository;

  List<Almacen> _almacenes = [];
  bool _isLoading = false;
  String? _error;

  List<Almacen> get almacenes => _almacenes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AlmacenController(SupabaseClient client)
      : _repository = AlmacenRepository(client);

  Future<void> cargarAlmacenes() async {
    _setLoading(true);
    try {
      _almacenes = await _repository.getAll();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar almacenes: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> agregarAlmacen(Almacen almacen) async {
    _setLoading(true);
    try {
      await _repository.insert(almacen);
      await cargarAlmacenes();
    } catch (e) {
      _error = 'Error al agregar: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> actualizarAlmacen(Almacen almacen) async {
    _setLoading(true);
    try {
      await _repository.update(almacen);
      await cargarAlmacenes();
    } catch (e) {
      _error = 'Error al actualizar: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> eliminarAlmacen(int id) async {
    _setLoading(true);
    try {
      await _repository.deleteById(id);
      await cargarAlmacenes();
    } catch (e) {
      _error = 'Error al eliminar: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// 📌 Riverpod provider para AlmacenController
final almacenControllerProvider = ChangeNotifierProvider(
  (ref) => AlmacenController(Supabase.instance.client),
);
