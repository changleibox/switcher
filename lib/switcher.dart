/*
 * Copyright (c) 2020 CHANGLEI. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

const Duration _kDelayedDuration = Duration(milliseconds: 2000);
const int _kScrollDelta = 30;
const int _kMaxScrollDelta = 1000;

class Switcher extends StatefulWidget {
  const Switcher.vertical({
    Key key,
    @required this.children,
    this.scrollDelta = _kScrollDelta,
    this.delayedDuration = _kDelayedDuration,
    this.curve = Curves.linearToEaseOut,
    this.placeholder,
  })  : assert(scrollDelta != null &&
            scrollDelta > 0 &&
            scrollDelta <= _kMaxScrollDelta),
        assert(delayedDuration != null),
        assert(curve != null),
        spacing = 0,
        _scrollDirection = Axis.vertical,
        super(key: key);

  const Switcher.horizontal({
    Key key,
    @required this.children,
    this.scrollDelta = _kScrollDelta,
    this.delayedDuration = _kDelayedDuration,
    this.curve = Curves.linear,
    this.placeholder,
    this.spacing = 10,
  })  : assert(scrollDelta != null &&
            scrollDelta > 0 &&
            scrollDelta <= _kMaxScrollDelta),
        assert(delayedDuration != null),
        assert(curve != null),
        assert(spacing != null && spacing >= 0 && spacing < double.infinity),
        _scrollDirection = Axis.horizontal,
        super(key: key);

  final List<Widget> children;
  final double spacing;
  final int scrollDelta;
  final Duration delayedDuration;
  final Curve curve;
  final Widget placeholder;
  final Axis _scrollDirection;

  @override
  _SwitcherState createState() => _SwitcherState();

  @override
  String toStringShort() {
    String type;
    if (_scrollDirection == Axis.vertical) {
      type = '${objectRuntimeType(this, 'Switcher')}.vertical';
    } else if (_scrollDirection == Axis.horizontal) {
      type = '${objectRuntimeType(this, 'Switcher')}.horizontal';
    } else {
      type = super.toStringShort();
    }
    return key == null ? type : '$type-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('spacing', spacing, defaultValue: null));
    properties.add(IntProperty('scrollDelta', scrollDelta, defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>(
        'delayedDuration', delayedDuration,
        defaultValue: null));
    properties.add(EnumProperty<Curve>('curve', curve, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget>('placeholder', placeholder,
        ifNull: 'SizedBox.shrink'));
    properties.add(DiagnosticsProperty<List<Widget>>('children', children,
        defaultValue: null));
    properties.add(EnumProperty<Axis>('_scrollDirection', _scrollDirection,
        defaultValue: null));
  }
}

class _SwitcherState extends State<Switcher> {
  final _controller = ScrollController();

  int _childCount = 0;
  double _scrollOffset = 0;
  Timer _timer;

  _initializationElements() {
    _childCount = 0;
    if (widget.children != null) {
      _childCount = widget.children.length;
    }
    if (_childCount > 0 && widget._scrollDirection == Axis.vertical) {
      _childCount++;
    }
  }

  _initializationScroll() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted || !_controller.hasClients || _childCount == 0) {
        return;
      }
      _timer?.cancel();
      _timer = null;
      _scrollOffset = 0;
      _controller.jumpTo(0);
      if (widget._scrollDirection == Axis.vertical) {
        _animateVertical();
      } else {
        _animateHorizontal();
      }
    });
  }

  _animateVertical() {
    if (!_controller.hasClients || widget._scrollDirection != Axis.vertical) {
      return;
    }
    if (_scrollOffset >= _controller.position.maxScrollExtent) {
      _controller.jumpTo(0);
      _scrollOffset = 0;
    }
    _timer?.cancel();
    _timer = Timer(widget.delayedDuration, () {
      var renderBox = context.findRenderObject() as RenderBox;
      if (!mounted ||
          !_controller.hasClients ||
          renderBox == null ||
          !renderBox.hasSize) {
        return;
      }
      var height = renderBox.size.height;
      var duration = _computeScrollDuration(height);
      _scrollOffset += height;
      _controller
          .animateTo(_scrollOffset, duration: duration, curve: widget.curve)
          .whenComplete(() {
        _animateVertical();
      });
    });
  }

  _animateHorizontal() {
    if (!_controller.hasClients || widget._scrollDirection != Axis.horizontal) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(widget.delayedDuration, () {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      var maxScrollExtent = _controller.position.maxScrollExtent;
      if (_scrollOffset >= maxScrollExtent) {
        _controller.jumpTo(0);
        _scrollOffset = 0;
        _animateHorizontal();
      } else {
        var duration = _computeScrollDuration(maxScrollExtent);
        _scrollOffset += maxScrollExtent;
        _controller
            .animateTo(_scrollOffset, duration: duration, curve: widget.curve)
            .whenComplete(() {
          _animateHorizontal();
        });
      }
    });
  }

  Duration _computeScrollDuration(double extent) {
    return Duration(
        milliseconds:
            (extent * Duration.millisecondsPerSecond / widget.scrollDelta)
                .floor());
  }

  _onScrollListener() {
    var position = _controller.position;
    var maxScrollExtent = position.maxScrollExtent;
    if (maxScrollExtent < position.pixels) {
      _timer?.cancel();
      _timer = null;
      _scrollOffset = maxScrollExtent;
      _controller.jumpTo(maxScrollExtent);
      if (widget._scrollDirection == Axis.vertical) {
        _animateVertical();
      } else {
        _animateHorizontal();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializationElements();
    _initializationScroll();
    _controller.addListener(_onScrollListener);
  }

  @override
  void didUpdateWidget(Switcher oldWidget) {
    var childrenChanged = widget.children?.length != oldWidget.children?.length;
    if (widget._scrollDirection != oldWidget._scrollDirection ||
        childrenChanged) {
      _initializationElements();
      _initializationScroll();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_childCount == 0) {
      return widget.placeholder ?? SizedBox.shrink();
    }
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        _initializationScroll();
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizeChangedLayoutNotifier(
            child: ListView.separated(
              itemCount: _childCount,
              physics: NeverScrollableScrollPhysics(),
              controller: _controller,
              scrollDirection: widget._scrollDirection,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final child = widget.children[index % widget.children.length];
                return Container(
                  alignment: Alignment.centerLeft,
                  height: constraints.constrainHeight(),
                  child: child,
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(
                  width: widget.spacing,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
