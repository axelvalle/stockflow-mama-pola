// logic/proveedor/proveedor_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/repository/persona_repository.dart';
import 'package:mamapola_app_v1/model/repository/proveedor_repository.dart';
import 'package:mamapola_app_v1/model/entities/persona.dart';
import 'package:mamapola_app_v1/logic/proveedor/proveedor_state.dart'; // Asegúrate de la ruta correcta

// Proveedor para PersonaRepository (si no existe, créalo)
final personaRepositoryProvider = Provider((ref) => PersonaRepository());
final proveedorRepositoryProvider = Provider((ref) => ProveedorRepository());

final proveedorControllerProvider = StateNotifierProvider<ProveedorController, ProveedorState>((ref) {
  return ProveedorController(
    ref.read(personaRepositoryProvider),
    ref.read(proveedorRepositoryProvider), // Usamos el proveedor ya definido
  );
});

class ProveedorController extends StateNotifier<ProveedorState> {
  final PersonaRepository _personaRepo;
  final ProveedorRepository _proveedorRepo;

  // Inyectamos ambos repositorios
  ProveedorController(this._personaRepo, this._proveedorRepo) : super(ProveedorState.initial());

  Future<void> loadProveedores() async {
    state = state.copyWith(isLoading: true);
    try {
      final proveedores = await _proveedorRepo.getProveedores();
      state = state.copyWith(proveedores: proveedores, isLoading: false, error: null); // Limpiar error
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> registrarProveedor(Persona persona) async {
    state = state.copyWith(isLoading: true);
    try {
      final idPersona = await _personaRepo.createPersona(persona);
      await _proveedorRepo.createProveedor(idPersona);
      await loadProveedores();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow; // Lanzar el error para que la UI lo maneje si es necesario
    }
  }

  Future<void> actualizarProveedor(Persona persona) async {
    state = state.copyWith(isLoading: true);
    try {
      await _personaRepo.updatePersona(persona);
      await loadProveedores();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> eliminarProveedor(int idPersona) async {
    state = state.copyWith(isLoading: true);
    try {
      await _proveedorRepo.deleteProveedorByPersona(idPersona);
      await _personaRepo.deletePersona(idPersona);
      await loadProveedores();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> asignarProveedor(int idProveedor, int idEmpresa) async {
    state = state.copyWith(isLoading: true);
    try {
      await _proveedorRepo.asignarProveedorAEmpresa(idProveedor, idEmpresa);
      await loadProveedores();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> desasignarProveedor(int idProveedor) async {
    state = state.copyWith(isLoading: true);
    try {
      await _proveedorRepo.desasignarProveedorDeEmpresa(idProveedor);
      await loadProveedores();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}