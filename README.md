## 简介

本文介绍怎么在Flutter里使用ListView实现Android的跑马灯，然后再扩展一下，实现上下滚动。

该小控件已经成功上传到[pub.dev](https://pub.dev/packages/ "pub.dev")，安装方式：

```markdown
dependencies:
   switcher: ^1.0.0+1
```

### 效果图

先上效果图：

##### 垂直模式

![垂直滚动](https://oscimg.oschina.net/oscnet/up-1c791c2c924e74f0ad5da76e712b6c5b812.gif)

##### 水平模式

![水平滚动](https://oscimg.oschina.net/oscnet/up-fc4bde67866cda1f6aa97d4cdb093ddde80.gif)

## 上代码

主要有两种滚动模式，垂直模式和水平模式，所以我们定义两个构造方法。
参数分别有滚动速度（单位是`pixels/second`）、每次滚动的延迟、滚动的曲线变化和`children`为空的时候的占位控件。

```dart
class Switcher {
  const Switcher.vertical({
    Key key,
    @required this.children,
    this.scrollDelta = _kScrollDelta,
    this.delayedDuration = _kDelayedDuration,
    this.curve = Curves.linearToEaseOut,
    this.placeholder,
  })  : assert(scrollDelta != null && scrollDelta > 0 && scrollDelta <= _kMaxScrollDelta),
        assert(delayDuration != null),
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
  })  : assert(scrollDelta != null && scrollDelta > 0 && scrollDelta <= _kMaxScrollDelta),
        assert(delayDuration != null),
        assert(curve != null),
        assert(spacing != null && spacing >= 0 && spacing < double.infinity),
        _scrollDirection = Axis.horizontal,
        super(key: key);
}
```

### 实现思路

实现思路有两种：

- 第一种是用`ListView`；

- 第二种是用`CustomPaint`自己画；

这里我们选择用`ListView`方式实现，方便后期扩展可手动滚动，如果用`CustomPaint`，实现起来就比较麻烦。

接下来我们分析一下究竟该怎么实现：

### 垂直模式

首先分析一下垂直模式，如果想实现循环滚动，那么`children`的数量就应该比原来的多一个，当滚动到最后一个的时候，立马跳到第一个，这里的最后一个实际就是原来的第一个，所以用户不会有任何察觉，这种实现方式在前端开发中应用很多，比如实现`PageView`的循环滑动，所以这里我们先定义`childCount`：

```dart
_initalizationElements() {
  _childCount = 0;
  if (widget.children != null) {
    _childCount = widget.children.length;
  }
  if (_childCount > 0 && widget._scrollDirection == Axis.vertical) {
    _childCount++;
  }
}
```

当`children`改变的时候，我们重新计算一次`childCount`，

```dart
@override
void didUpdateWidget(Switcher oldWidget) {
  var childrenChanged = (widget.children?.length ?? 0) != (oldWidget.children?.length ?? 0);
  if (widget._scrollDirection != oldWidget._scrollDirection || childrenChanged) {
    _initalizationElements();
    _initializationScroll();
  }
  super.didUpdateWidget(oldWidget);
}
```

这里判断如果是垂直模式，我们就`childCount++`，接下来，实现一下`build`方法：

```dart
@override
Widget build(BuildContext context) {
  if (_childCount == 0) {
    return widget.placeholder ?? SizedBox.shrink();
  }
  return LayoutBuilder(
    builder: (context, constraints) {
      return ConstrainedBox(
        constraints: constraints,
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
  );
}
```

接下来实现垂直滚动的主要逻辑：

```dart
_animateVertical(double extent) {
  if (!_controller.hasClients || widget._scrollDirection != Axis.vertical) {
    return;
  }
  if (_selectedIndex == _childCount - 1) {
    _selectedIndex = 0;
    _controller.jumpTo(0);
  }
  _timer?.cancel();
  _timer = Timer(widget.delayedDuration, () {
    _selectedIndex++;
    var duration = _computeScrollDuration(extent);
    _controller.animateTo(extent * _selectedIndex, duration: duration, curve: widget.curve).whenComplete(() {
      _animateVertical(extent);
    });
  });
}
```

解释一下这段逻辑，先判断`ScrollController`有没有加载完成，然后当前的滚动方向是不是垂直的，不是就直接返回，然后当前的`index`是最后一个的时候，立马跳到第一个，`index`初始化为0，接下来，取消前一个定时器，开一个新的定时器，定时器的时间为我们传进来的间隔时间，然后每间隔`widget.delayedDuration`的时间滚动一次，这里调用`ScrollController.animateTo`，滚动距离为每个`item`的高度乘以当前的索引，滚动时间根据滚动速度算出来：

```dart
Duration _computeScrollDuration(double extent) {
  return Duration(milliseconds: (extent * Duration.millisecondsPerSecond / widget.scrollDelta).floor());
}
```

这里是我们小学就学过的，`距离 = 速度 x 时间`，所以根据距离和速度我们就可以得出需要的时间，这里乘以`Duration.millisecondsPerSecond`的原因是转换成毫秒，因为我们的速度是`pixels/second`。

当完成当前滚动的时候，进行下一次，这里递归调用`_animateVertical`，这样我们就实现了垂直的循环滚动。

### 水平模式

接下去实现水平模式，和垂直模式类似：

```dart
_animateHorizonal(double extent, bool needsMoveToTop) {
  if (!_controller.hasClients || widget._scrollDirection != Axis.horizontal) {
    return;
  }
  _timer?.cancel();
  _timer = Timer(widget.delayedDuration, () {
    if (needsMoveToTop) {
      _controller.jumpTo(0);
      _animateHorizonal(extent, false);
    } else {
      var duration = _computeScrollDuration(extent);
      _controller.animateTo(extent, duration: duration, curve: widget.curve).whenComplete(() {
        _animateHorizonal(extent, true);
      });
    }
  });
}
```

这里解释一下`needsMoveToTop`，因为水平模式下，首尾都要停顿，所以我们加个参数判断下，如果是当前执行的滚动到头部的话，`needsMoveToTop`传`false`，如果是已经滚动到了尾部，`needsMoveToTop`传`true`，表示我们的下一次的行为是滚动到头部，而不是开始滚动到整个列表。

接下来我们看看在哪里开始滚动。

首先在页面加载的时候我们开始滚动，然后还有当方向和`childCount`改变的时候，重新开始滚动，所以：

```dart
@override
void initState() {
  super.initState();
  _initalizationElements();
  _initializationScroll();
}

@override
void didUpdateWidget(Switcher oldWidget) {
  var childrenChanged = (widget.children?.length ?? 0) != (oldWidget.children?.length ?? 0);
  if (widget._scrollDirection != oldWidget._scrollDirection || childrenChanged) {
    _initalizationElements();
    _initializationScroll();
  }
  super.didUpdateWidget(oldWidget);
}
```

然后是`_initializationScroll`方法：

```dart
_initializationScroll() {
  SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
    if (!mounted) {
      return;
    }
    var renderBox = context?.findRenderObject() as RenderBox;
    if (!_controller.hasClients || _childCount == 0 || renderBox == null || !renderBox.hasSize) {
      return;
    }
    var position = _controller.position;
    _timer?.cancel();
    _timer = null;
    position.moveTo(0);
    _selectedIndex = 0;
    if (widget._scrollDirection == Axis.vertical) {
      _animateVertical(renderBox.size.height);
    } else {
      var maxScrollExtent = position.maxScrollExtent;
      _animateHorizonal(maxScrollExtent, false);
    }
  });
}
```

这里在页面绘制完成的时候，我们判断，如果`ScrollController`没有加载，`childCount == 0`或者大小没有计算完成的时候直接返回，然后获取`position`，取消上一个计时器，然后把列表滚到头部，`index`初始化为0，判断是垂直模式，开始垂直滚动，如果是水平模式开始水平滚动。

**这里注意，垂直滚动的时候，每次的滚动距离是每个item的高度，而水平滚动的时候，滚动距离是列表可滚动的最大长度**。

到这里我们已经实现了Android的跑马灯，而且还增加了垂直滚动，是不是很简单呢。

如有问题、意见和建议，都可以在评论区里告诉我，我将及时修改和参考你的意见和建议，对代码做出优化。
