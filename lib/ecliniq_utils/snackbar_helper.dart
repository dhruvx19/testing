import 'package:flutter/material.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';

/// Utility class for showing snackbars with consistent behavior across the app.
/// All snackbars created through this utility are dismissible by swiping and positioned at the top.
class SnackBarHelper {
  /// Shows a simple snackbar with the given message.
  /// The snackbar is dismissible by swiping horizontally and positioned at the top.
  /// For action snackbars, use showActionSnackBar instead.
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    // If action is provided, use CustomActionSnackBar, otherwise use success snackbar
    if (action != null) {
      CustomActionSnackBar.show(
        context: context,
        title: 'Notification',
        subtitle: message,
        duration: duration,
      );
    } else {
      CustomSuccessSnackBar.show(
        context: context,
        title: 'Notification',
        subtitle: message,
        duration: duration,
      );
    }
  }

  /// Shows an error snackbar with custom error styling.
  /// The snackbar is dismissible by swiping horizontally and positioned at the top.
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    CustomErrorSnackBar.show(
      context: context,
      title: 'Error',
      subtitle: message,
      duration: duration,
    );
  }

  /// Shows a success snackbar with custom success styling.
  /// The snackbar is dismissible by swiping horizontally and positioned at the top.
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomSuccessSnackBar.show(
      context: context,
      title: 'Success',
      subtitle: message,
      duration: duration,
    );
  }

  /// Shows an action snackbar with custom action styling.
  /// The snackbar is dismissible by swiping horizontally and positioned at the top.
  static void showActionSnackBar(
    BuildContext context,
    String title,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomActionSnackBar.show(
      context: context,
      title: title,
      subtitle: message,
      duration: duration,
    );
  }

  /// Shows a warning snackbar with custom action styling (uses action snackbar).
  /// The snackbar is dismissible by swiping horizontally and positioned at the top.
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomActionSnackBar.show(
      context: context,
      title: 'Warning',
      subtitle: message,
      duration: duration,
    );
  }
}
