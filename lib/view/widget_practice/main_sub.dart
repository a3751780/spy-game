import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async{
  // setupWindow();
  runApp(MaterialApp(
    title: 'Simple Demo',
    home: PageA(),
  ));
}

class PageA extends StatelessWidget {
  const PageA({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("A 頁面")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PageB()),
            );
          },
          child: Text("跳到 B 頁面"),
        ),
      ),
    );
  }
}

class PageB extends StatelessWidget {
  const PageB({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("B 頁面"),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon:Icon(FontAwesomeIcons.dartLang),
          padding:EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),),
      body: Center(
        child: Text("你現在在 B 頁面"),
      ),
    );
  }
}