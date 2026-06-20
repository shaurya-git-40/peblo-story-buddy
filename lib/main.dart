import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChangeNotifierProvider(
        create: (_) => StoryProvider(),
        child: HomeScreen(),
      ),
    );
  }
}

class Quiz {
  final String question;
  final List<String> options;
  final String answer;
  Quiz({required this.question, required this.options, required this.answer});
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      question: json['question'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
    );
  }
}

enum AppState { idle, speaking, loading, quiz, success }

class StoryProvider with ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final ConfettiController _confettiController = ConfettiController(duration: Duration(seconds: 2));

  AppState _state = AppState.idle;
  AppState get state => _state;

  final String storyText = "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

  final Quiz quiz = Quiz.fromJson({
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue"
  });

  bool answered = false;
  bool isCorrect = false;

  StoryProvider() {
    _tts.setCompletionHandler(() {
      _state = AppState.quiz;
      notifyListeners();
    });
    _tts.setErrorHandler((msg) {
      _state = AppState.idle;
      notifyListeners();
    });
  }

  Future<void> playStory() async {
    _state = AppState.loading;
    notifyListeners();
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.2);
    await _tts.setSpeechRate(0.5);
    _state = AppState.speaking;
    notifyListeners();
    await _tts.speak(storyText);
  }

  void checkAnswer(String selected) {
    if(answered) return;
    answered = true;
    if(selected == quiz.answer) {
      isCorrect = true;
      _state = AppState.success;
      _confettiController.play();
    } else {
      isCorrect = false;
      Vibration.vibrate(duration: 200);
      Future.delayed(Duration(milliseconds: 600), () {
        answered = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  ConfettiController get confetti => _confettiController;

  @override
  void dispose() {
    _tts.stop();
    _confettiController.dispose();
    super.dispose();
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9C4),
      body: Consumer<StoryProvider>(
        builder: (context, provider, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue[100]),
                      padding: EdgeInsets.all(20),
                      child: Icon(Icons.smart_toy, size: 100, color: Colors.blue[800]),
                    ),
                    SizedBox(height: 30),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 100),
                      transform: Matrix4.translationValues(provider.answered &&!provider.isCorrect? 8 : 0, 0, 0),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(provider.storyText, style: TextStyle(fontSize: 18, height: 1.5)),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    if(provider.state == AppState.idle)
                      ElevatedButton(
                        onPressed: provider.playStory,
                        child: Text("Read Me a Story", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    if(provider.state == AppState.loading || provider.state == AppState.speaking)
                      Column(children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 10),
                        Text("Story sun rahi hu...", style: TextStyle(fontSize: 16))
                      ]),
                    if(provider.state == AppState.quiz || provider.state == AppState.success)
                      Column(
                        children: [
                          Text(provider.quiz.question,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                          SizedBox(height: 20),
                       ...provider.quiz.options.map((opt) =>
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: provider.answered? null : () => provider.checkAnswer(opt),
                                  child: Text(opt, style: TextStyle(fontSize: 20)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue[800],
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                ),
                              )
                            )
                          ),
                          if(provider.state == AppState.success)
                            Padding(
                              padding: EdgeInsets.only(top: 30),
                              child: Text("🎉 Success! Shabaash!",
                                style: TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold)),
                            )
                        ],
                      )
                  ],
                ),
              ),
              ConfettiWidget(
                confettiController: provider.confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ],
          );
        },
      ),
    );
  }
}
