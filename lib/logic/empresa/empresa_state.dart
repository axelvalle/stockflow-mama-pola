import 'package:mamapola_app_v1/model/entities/empresa.dart';

class EmpresaState {
  final List<Empresa> empresas;
  final bool isLoading;

  EmpresaState({this.empresas = const [], this.isLoading = false});

  EmpresaState copyWith({List<Empresa>? empresas, bool? isLoading}) {
    return EmpresaState(
      empresas: empresas ?? this.empresas,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
