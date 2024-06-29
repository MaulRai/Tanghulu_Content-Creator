import 'dart:typed_data';

import 'package:content_creator/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:brain_fusion/brain_fusion.dart';
import 'package:provider/provider.dart';

const apiKey = "AIzaSyBatUW7pEBpkEEa5Kqgw5GZUgzg0s01lcU";

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String displayedResponse = "";
  double temperature = 1.0;
  bool waitingForResponse = false;
  Widget? displayedImage;
  final AI ai = AI();

  final geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ]);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double height = size.height;
    double width = size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("What content do you want to make?"),
      ),
      resizeToAvoidBottomInset: true, // This property prevents overflow
      body: SingleChildScrollView(
        child: IntrinsicHeight(
          child: Column(
            children: [
              _typingBox(),
              Row(
                children: [
                  const Text("       Randomness temperature"),
                  const Icon(
                    Icons.thermostat_outlined,
                    color: Colors.blue,
                  ),
                  Text(" : ${temperature.toStringAsFixed(2)}"),
                ],
              ),
              Slider(
                  value: temperature,
                  onChanged: (newValue) {
                    setState(() {
                      temperature = newValue;
                    });
                  }),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(displayedResponse),
              ),
              if (waitingForResponse)
                JumpingDots(
                  color: Colors.blue,
                  radius: 10,
                  numberOfDots: 3,
                  animationDuration: Duration(milliseconds: 200),
                ),
              Container(
                alignment: Alignment.center,
                height: 320,
                width: 320,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(
                      12.0,
                    )),
                // child: Image.memory(fWatch.imageData!),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _typingBox() {
    Size size = MediaQuery.of(context).size;
    double height = size.height;
    double width = size.width;
    TextEditingController chatController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(left: 10),
            width: width - 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(width: 3, color: Colors.blue),
            ),
            child: TextField(
              controller: chatController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              ),
            ),
          ),
          IconButton(
              onPressed: () {
                _handleSendMessage(chatController.text, temperature);
                chatController.clear();
              },
              icon: Icon(Icons.send))
        ],
      ),
    );
  }

  void _handleSendMessage(String text, double temperature) async {
    if (text.trim() != "") {
      final response = await _getResponse(text, temperature);
      setState(() {
        displayedResponse = response;
      });
      final imagePrompt = "$response make an image based on this recipe";
      _processPromptToImage(imagePrompt);
      await Future.delayed(Duration(seconds: 20));
      setState(() {

        // displayedImage = picture;
        waitingForResponse = false;
      });
    }
  }

  void _processPromptToImage(String imagePrompt) {
    final homeProvider = Provider.of<HomeProvider>(context);
    homeProvider.textToImage(imagePrompt, context);
  }

  Future<String> _getResponse(String text, double temperature) async {
    final prompt =
        '''You're an instagram content creator who likes anime. You will generate 1 recipe from popular anime
        with emojis that are less than 300 characters. You're going to make the recipe I want, with the temperature
        ranging from 0 to 1, which 0 determine more predictable, deterministic outputs, tends to stick to the most 
        likely next words, leading to less surprising and more "safe" results. while closer to 1 means creative and 
        explore different possibilities. I want to make $text. With temperature ${temperature.toStringAsFixed(2)}''';
    setState(() {
      waitingForResponse = true;
    });
    final response = await geminiModel.generateContent([Content.text(prompt)]);
    // setState(() {
    //   waitingForResponse = false;
    // });
    return response.text!;
  }
}
