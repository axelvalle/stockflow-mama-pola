import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mamapola_app_v1/model/entities/empresa.dart';
import 'package:mamapola_app_v1/model/repository/empresa_repository.dart';
import 'empresa_state.dart';

final empresaControllerProvider =
    StateNotifierProvider<EmpresaController, EmpresaState>(
        (ref) => EmpresaController());

class EmpresaController extends StateNotifier<EmpresaState> {
  EmpresaController() : super(EmpresaState());

  final _repo = EmpresaRepository();

  Future<void> cargarEmpresas() async {
    state = state.copyWith(isLoading: true);
    final empresas = await _repo.getEmpresasConProveedores();
    state = state.copyWith(empresas: empresas, isLoading: false);
  }

  Future<void> agregarEmpresa(Empresa empresa) async {
    await _repo.insertarEmpresa(empresa);
    await cargarEmpresas();
  }

  Future<void> actualizarEmpresa(Empresa empresa) async {
    await _repo.actualizarEmpresa(empresa);
    await cargarEmpresas();
  }

  Future<void> eliminarEmpresa(int id) async {
    await _repo.eliminarEmpresa(id);
    await cargarEmpresas();
  }

  Future<int> agregarEmpresaYRetornarId(Empresa empresa) async {
  return await _repo.insertarEmpresaYRetornarId(empresa);
    }

}
