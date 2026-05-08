// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:component_library/component_library.dart';
//
// void main() {
//   group('CustomAppBar', () {
//     testWidgets('renders title correctly', (tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             appBar: CustomAppBar(title: '测试标题'),
//           ),
//         ),
//       );
//
//       expect(find.text('测试标题'), findsOneWidget);
//     });
//
//     testWidgets('shows back button when canPop and showBackButton is true',
//         (tester) async {
//       // Push a second route so Navigator.canPop() returns true
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Builder(
//             builder: (context) => Scaffold(
//               body: ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(
//                       builder: (_) => const Scaffold(
//                         appBar: CustomAppBar(title: '标题', showBackButton: true),
//                       ),
//                     ),
//                   );
//                 },
//                 child: const Text('Push'),
//               ),
//             ),
//           ),
//         ),
//       );
//
//       await tester.tap(find.text('Push'));
//       await tester.pumpAndSettle();
//
//       expect(find.byType(BackButton), findsOneWidget);
//     });
//
//     testWidgets('hides back button when showBackButton is false', (tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             appBar: CustomAppBar(title: '标题', showBackButton: false),
//           ),
//         ),
//       );
//
//       expect(find.byType(BackButton), findsNothing);
//     });
//
//     testWidgets('renders actions correctly', (tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             appBar: CustomAppBar(
//               title: '标题',
//               actions: [
//                 IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
//               ],
//             ),
//           ),
//         ),
//       );
//
//       expect(find.byIcon(Icons.refresh), findsOneWidget);
//     });
//
//     testWidgets('implements PreferredSizeWidget with correct height',
//         (tester) async {
//       final appBar = CustomAppBar(title: '标题');
//
//       expect(appBar.preferredSize.height, equals(kToolbarHeight));
//     });
//   });
// }
