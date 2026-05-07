import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../repository/mock_auth_repository.dart';

class RegisterPage extends StatelessWidget {
  final String? redirect;

  const RegisterPage({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(MockAuthRepository()),
      child: RegisterPageView(redirect: redirect),
    );
  }
}

class RegisterPageView extends StatelessWidget {
  final String? redirect;

  const RegisterPageView({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            final target = redirect ?? AppRoutes.home;
            context.go(target);
          }
        },
        builder: (context, state) {
          final cubit = context.read<LoginCubit>();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                TextField(
                  decoration: const InputDecoration(labelText: '用户名'),
                  onChanged: cubit.setUsername,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  onChanged: cubit.setPassword,
                ),
                const SizedBox(height: 24),
                if (state.status == LoginStatus.loading)
                  const CircularProgressIndicator(),
                if (state.status == LoginStatus.error)
                  Text(state.errorMessage ?? '注册失败',
                      style: const TextStyle(color: Colors.red),),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.status == LoginStatus.loading
                      ? null
                      : cubit.register,
                  child: const Text('注册'),
                ),
                TextButton(
                  onPressed: () => context.go('${AppRoutes.login}?redirect=$redirect',),
                  child: const Text('已有账号？登录'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}