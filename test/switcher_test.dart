import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:switcher/switcher.dart';

const Duration _kDelayedDuration = Duration(seconds: 2);
const double _kHeight = 30;
const int _kScrollSpeed = 30;

Duration _computeScrollDuration(double extent, int speed) {
  return Duration(milliseconds: (extent * Duration.millisecondsPerSecond / speed).floor());
}

void main() {
  test('滚动速度测试', () {
    var duration = _computeScrollDuration(30, 30);
    expect(1, duration.inSeconds);
  });

  testWidgets('Switcher垂直测试', (tester) async {
    final text = '1234';
    final childCount = 4;

    double scrollExtent = 0.0;

    await tester.pumpWidget(
      _TestWidgetPage(
        builder: (context, setState) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              setState(() {
                scrollExtent = notification.metrics.pixels;
              });
              return false;
            },
            child: SizedBox(
              height: _kHeight,
              child: Switcher.vertical(
                delayedDuration: _kDelayedDuration,
                scrollDelta: _kScrollSpeed,
                children: List.generate(childCount, (index) {
                  return Text(text);
                }),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text(text), findsNWidgets(1));

    var widget = tester.widget(find.byType(ListView)) as ListView;
    expect(widget.childrenDelegate.estimatedChildCount, equals((childCount << 1) + 1));

    await tester.pump(_kDelayedDuration);
    expect(scrollExtent, equals(0));

    await tester.pump(_computeScrollDuration(_kHeight, _kScrollSpeed));
    expect(scrollExtent, equals(_kHeight));
  });

  testWidgets('Switcher水平测试', (tester) async {
    final text = '1234';
    final childCount = 4;

    double scrollExtent = 0.0;

    await tester.pumpWidget(
      _TestWidgetPage(
        builder: (context, setState) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              var metrics = notification.metrics;
              setState(() {
                scrollExtent = metrics.pixels;
              });
              return false;
            },
            child: SizedBox(
              height: _kHeight,
              child: Switcher.horizontal(
                delayedDuration: _kDelayedDuration,
                scrollDelta: _kScrollSpeed,
                spacing: 0,
                children: List.generate(childCount, (index) {
                  return Text(text);
                }),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text(text).evaluate().length, inInclusiveRange(1, childCount));

    var widget = tester.widget(find.byType(ListView)) as ListView;
    var maxScrollExtent = widget.controller.position.maxScrollExtent;
    expect(widget.childrenDelegate.estimatedChildCount, equals((childCount << 1) - 1));

    await tester.pump(_kDelayedDuration);
    expect(scrollExtent, equals(0));

    final seconds = 3;
    await tester.pump(Duration(seconds: seconds));
    if (maxScrollExtent <= 0) {
      expect(scrollExtent, equals(0));
    } else {
      expect(scrollExtent, equals(_kScrollSpeed * seconds));
    }
  });
}

class _TestWidgetPage extends StatelessWidget {
  final StatefulWidgetBuilder builder;

  const _TestWidgetPage({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: StatefulBuilder(
                builder: builder,
              ),
            );
          },
        ),
      ),
    );
  }
}
