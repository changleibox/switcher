import 'package:flutter/cupertino.dart';
import 'package:switcher/switcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              height: 40,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: CupertinoTheme.of(context).primaryColor,
                  width: 0.0,
                ),
              ),
              child: Switcher.horizontal(
                scrollDelta: 30,
                children: [
                  Text('mainAxisAl'),
                  Text('crossAxis'),
                  Text('mainAxisSize: '),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                //padding: EdgeInsets.symmetric(
                //  horizontal: 10,
                //),
                decoration: BoxDecoration(
                  //borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: CupertinoTheme.of(context).primaryColor,
                    width: 0.0,
                  ),
                ),
                child: Switcher.vertical(
                  scrollDelta: 800,
                  children: [
                    Container(
                      color: CupertinoColors.systemRed,
                    ),
                    Container(
                      color: CupertinoColors.systemGreen,
                    ),
                    Container(
                      color: CupertinoColors.systemPink,
                    ),
                    Container(
                      color: CupertinoColors.systemBlue,
                    ),
                    Container(
                      color: CupertinoColors.systemOrange,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
