import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:routing/routing.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatelessWidget {
  final String? redirect;

  const LoginPage({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return LoginPageView(redirect: redirect);
  }
}

class LoginPageView extends StatelessWidget {
  final String? redirect;

  const LoginPageView({super.key, this.redirect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
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
                  Text(state.errorMessage ?? '登录失败',
                      style: const TextStyle(color: Colors.red),),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.status == LoginStatus.loading
                      ? null
                      : cubit.login,
                  child: const Text('登录'),
                ),
                TextButton(
                  onPressed: () => context.go('${AppRoutes.register}?redirect=$redirect',),
                  child: const Text('没有账号？注册'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}