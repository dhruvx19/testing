import 'package:flutter/cupertino.dart';
import 'package:page_transition/page_transition.dart';

class EcliniqRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> push<T extends Object?>(
    Widget page, {
    bool fullscreenDialog = false,
    PageTransitionType transition = PageTransitionType.rightToLeft,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator is not initialized. Make sure navigatorKey is set in MaterialApp.',
      );
    }
    return navigator.push(
      _appRoute<T>(
        page,
        fullscreenDialog: fullscreenDialog,
        transition: transition,
      ),
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    Widget page,
    RoutePredicate predicate, {
    bool fullscreenDialog = false,
    PageTransitionType transition = PageTransitionType.rightToLeft,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator is not initialized. Make sure navigatorKey is set in MaterialApp.',
      );
    }
    return navigator.pushAndRemoveUntil(
      _appRoute<T>(
        page,
        fullscreenDialog: fullscreenDialog,
        transition: transition,
      ),
      predicate,
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    bool fullscreenDialog = false,
    PageTransitionType transition = PageTransitionType.rightToLeft,
    Duration? duration,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator is not initialized. Make sure navigatorKey is set in MaterialApp.',
      );
    }
    return navigator.pushReplacement(
      _appRoute<T>(
        page,
        fullscreenDialog: fullscreenDialog,
        transition: transition,
        duration: duration,
      ),
    );
  }

  static void pop<T extends Object?>([T? result]) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator is not initialized. Make sure navigatorKey is set in MaterialApp.',
      );
    }
    navigator.pop(result);
  }
      

  static Route<T> _appRoute<T>(
    Widget page, {
    bool fullscreenDialog = false,
    PageTransitionType transition = PageTransitionType.rightToLeft,
    Duration? duration,
  }) {
    return PageTransition(
      type: transition,
      child: page,
      curve: Curves.easeInOut,
      isIos: transition == PageTransitionType.rightToLeft,
      fullscreenDialog: fullscreenDialog,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }
  
  static Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    bool fullscreenDialog = false,
    PageTransitionType transition = PageTransitionType.rightToLeft,
    Duration? duration,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator is not initialized. Make sure navigatorKey is set in MaterialApp.',
      );
    }
    return navigator.push(
      _appRoute<T>(
        page,
        fullscreenDialog: fullscreenDialog,
        transition: transition,
        duration: duration,
      ),
    );
  }
}