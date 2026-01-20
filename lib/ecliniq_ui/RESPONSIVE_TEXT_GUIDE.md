# Responsive Text Styles Guide

## Overview

The responsive text system automatically scales font sizes for smaller devices while maintaining the original design for iPhone 12/13 (390px width) and larger devices.

## Design Base

- **Base Design Width**: 390px (iPhone 12/13)
- **Minimum Scale Factor**: 0.85 (prevents fonts from becoming too small)
- **Scaling Logic**: 
  - Devices >= 390px: No scaling (original size)
  - Devices < 390px: Proportional scaling (deviceWidth / 390)

## Usage Methods

### Method 1: Using Responsive Style Methods (Recommended)

Use the `responsive*` methods when you want automatic scaling:

```dart
// Instead of:
EcliniqText(
  'Hello World',
  style: EcliniqTextStyles.headlineLarge,
)

// Use:
EcliniqText(
  'Hello World',
  style: EcliniqTextStyles.responsiveHeadlineLarge(context),
)
```

### Method 2: Using EcliniqText with useResponsiveScaling

Enable automatic responsive scaling on the `EcliniqText` widget:

```dart
EcliniqText(
  'Hello World',
  style: EcliniqTextStyles.headlineLarge,
  useResponsiveScaling: true, // Automatically scales the font
)
```

### Method 3: Manual Scaling for Custom Styles

For custom text styles, use the helper method:

```dart
final customStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

// Apply responsive scaling
final responsiveStyle = EcliniqTextStyles.getResponsiveStyle(context, customStyle);

EcliniqText(
  'Hello World',
  style: responsiveStyle,
)
```

### Method 4: Get Responsive Font Size Directly

```dart
final fontSize = EcliniqTextStyles.getResponsiveFontSize(context, 18.0);
// Returns scaled font size for smaller devices, original size for larger devices
```

## Migration Guide

### Before (Fixed Sizes)
```dart
EcliniqText(
  'Title',
  style: EcliniqTextStyles.headlineLarge,
)
```

### After (Responsive)
```dart
// Option 1: Use responsive method
EcliniqText(
  'Title',
  style: EcliniqTextStyles.responsiveHeadlineLarge(context),
)

// Option 2: Use useResponsiveScaling flag
EcliniqText(
  'Title',
  style: EcliniqTextStyles.headlineLarge,
  useResponsiveScaling: true,
)
```

## Available Responsive Methods

All text styles have corresponding responsive methods:

- `responsiveHeadlineXLarge(context)`
- `responsiveTitleInitial(context)`
- `responsiveHeadlineLarge(context)`
- `responsiveHeadlineLargeBold(context)`
- `responsiveHeadlineZMedium(context)`
- `responsiveHeadlineBMedium(context)`
- `responsiveHeadlineMedium(context)`
- `responsiveHeadlineXMedium(context)`
- `responsiveHeadlineXLMedium(context)`
- `responsiveHeadlineSmall(context)`
- `responsiveBodyLarge(context)`
- `responsiveBodyMedium(context)`
- `responsiveBodyMediumProminent(context)`
- `responsiveBodySmall(context)`
- `responsiveBodySmallProminent(context)`
- `responsiveBodyXSmall(context)`
- `responsiveBodyXSmallProminent(context)`
- `responsiveBody2xSmall(context)`
- `responsiveBody2xSmallProminent(context)`
- `responsiveBody2xSmallRegular(context)`
- `responsiveTitleXBLarge(context)`
- `responsiveTitleXLarge(context)`
- `responsiveTitleMedium(context)`
- `responsiveTitleSmall(context)`
- `responsiveButtonXLarge(context)`
- `responsiveButtonXLargeProminent(context)`
- `responsiveButtonLarge(context)`
- `responsiveButtonMedium(context)`
- `responsiveButtonMediumProminent(context)`
- `responsiveButtonSmall(context)`
- `responsiveLabelMedium(context)`
- `responsiveLabelMediumProminent(context)`
- `responsiveLabelSmall(context)`
- `responsiveLabelSmallProminent(context)`
- `responsiveLabelXSmall(context)`
- `responsiveLabelXSmallProminent(context)`
- `responsiveHeadlineXXLarge(context)`
- `responsiveHeadlineXXLargeBold(context)`
- `responsiveHeadlineXXXLarge(context)`

## Examples

### Example 1: Button Text
```dart
EcliniqButton(
  label: 'Submit',
  type: EcliniqButtonType.primary,
  // Button internally uses responsiveButtonXLargeProminent
)
```

### Example 2: Screen Title
```dart
EcliniqText(
  'My Profile',
  style: EcliniqTextStyles.responsiveHeadlineLarge(context),
)
```

### Example 3: Body Text with Custom Color
```dart
EcliniqText(
  'This is body text',
  style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
    color: Colors.blue,
  ),
)
```

### Example 4: Using with copyWith
```dart
EcliniqText(
  'Custom styled text',
  style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
    color: Colors.red,
    letterSpacing: 0.5,
  ),
)
```

## Important Notes

1. **Original Styles Preserved**: The original static styles (e.g., `EcliniqTextStyles.headlineLarge`) remain unchanged and can still be used for non-responsive cases.

2. **Context Required**: Responsive methods require `BuildContext` to access screen dimensions.

3. **Minimum Scale**: Fonts will never scale below 85% of the original size to maintain readability.

4. **Backward Compatible**: Existing code using static styles will continue to work without changes.

5. **Performance**: The scaling calculation is lightweight and performed at build time.

## Device Examples

- **iPhone 12/13 (390px)**: No scaling (100%)
- **iPhone SE (375px)**: ~96% scaling
- **Small Android (360px)**: ~92% scaling
- **Very Small (320px)**: 85% scaling (minimum)

## Testing

Test your responsive text on:
- iPhone 12/13 (390px) - Should show original sizes
- iPhone SE (375px) - Should show slightly smaller fonts
- Small Android devices (360px and below) - Should show scaled fonts



