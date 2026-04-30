import 'package:equatable/equatable.dart';
import 'package:domain_models/domain_models.dart';

/// 详情页状态基类
sealed class DetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始状态
class DetailInitial extends DetailState {}

/// 加载中状态
class DetailLoading extends DetailState {}

/// 加载成功状态
class DetailLoaded extends DetailState {
  final Map<String, dynamic> data;
  DetailLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// 加载失败状态
class DetailError extends DetailState {
  final ErrorCode errorCode;
  DetailError(this.errorCode);

  @override
  List<Object?> get props => [errorCode];
}