import 'package:flutter/material.dart';
import '../../../model/entities/movimiento_inventario.dart';

@immutable
abstract class MovimientoInventarioState {}

class MovimientoInventarioInitial extends MovimientoInventarioState {}

class MovimientoInventarioLoading extends MovimientoInventarioState {}

class MovimientoInventarioLoaded extends MovimientoInventarioState {
  final List<MovimientoInventario> movimientos;

  MovimientoInventarioLoaded(this.movimientos);
}

class MovimientoInventarioError extends MovimientoInventarioState {
  final String message;

  MovimientoInventarioError(this.message);
}
