import 'package:ai_chatbot/presentation/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

///Followed https://medium.com/codetodeploy/build-a-flutter-ai-chatbot-from-scratch-in-30-minutes-no-experience-needed-4ee0b5957862
void main() async {
  // Assicura che i binding di Flutter siano pronti
  WidgetsFlutterBinding.ensureInitialized();

  // Carica il file .env
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
