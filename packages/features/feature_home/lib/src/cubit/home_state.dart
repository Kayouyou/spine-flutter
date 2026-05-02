import 'package:equatable/equatable.dart';
import 'package:domain/domain.dart';

/// 首页状态基类
///
/// 使用sealed class确保状态类型完整，
/// switch语句可穷举所有状态，编译器检查遗漏。
sealed class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始状态
///
/// 首页刚打开，尚未加载数据
class HomeInitial extends HomeState {}

/// 加载中状态
///
/// 正在从服务器获取数据
class HomeLoading extends HomeState {}

/// 加载成功状态
///
/// 数据加载完成，可展示内容
class HomeLoaded extends HomeState {
  /// 首页数据
  final Map<String, dynamic> data;

  HomeLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// 加载失败状态
///
/// 数据加载出错，展示错误提示
class HomeError extends HomeState {
  /// 错误信息
  final String errorCode;

  HomeError(this.errorCode);

  @override
  List<Object?> get props => [errorCode];
}