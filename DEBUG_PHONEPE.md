# PhonePe Payment Integration - Debugging Guide

## 🔍 Quick Diagnosis Checklist

### 1. Check Backend Response
Add this logging in `review_details_screen.dart` after line 721:

```dart
// After receiving response from bookAppointment
print('========== BOOKING RESPONSE DEBUG ==========');
print('Success: ${response.success}');
print('Response data type: ${response.data.runtimeType}');
if (response.data is Map<String, dynamic>) {
  final data = response.data as Map<String, dynamic>;
  print('Contains token: ${data.containsKey("token")}');
  print('Token value: ${data["token"]}');
  print('Requires gateway: ${data["requiresGateway"]}');
  print('Merchant TxnId: ${data["merchantTransactionId"]}');
}
print('============================================');
```

### 2. Check Token in PaymentProcessingScreen
Add logging in `payment_processing_screen.dart` after line 130:

```dart
print('========== PHONEPE PAYMENT DEBUG ==========');
print('Token length: ${widget.token.length}');
print('Token (first 50 chars): ${widget.token.substring(0, min(50, widget.token.length))}');
print('App Schema: ${widget.appSchema}');
print('Merchant ID: M237OHQ3YCVAO_2511191950');
print('==========================================');
```

### 3. Check PhonePe SDK Initialization
Add logging in `payment_processing_screen.dart` after line 107:

```dart
print('========== SDK INIT DEBUG ==========');
print('SDK Initialized: $initialized');
print('Environment: ${_phonePeService.environment}');
print('Package Name: ${_phonePeService.packageName}');
print('====================================');
```

### 4. Check Payment Result
Add logging in `payment_processing_screen.dart` after line 133:

```dart
print('========== PAYMENT RESULT DEBUG ==========');
print('Result Success: ${result.success}');
print('Result Status: ${result.status}');
print('Result Error: ${result.error}');
print('Result Data: ${result.data}');
print('=========================================');
```

## 🎯 Common Issues & Solutions

### Issue 1: Token is null or empty
**Symptom**: PhonePe doesn't open or crashes immediately
**Cause**: Backend not returning token
**Solution**: 
- Check backend logs for `/api/appointments/book`
- Ensure backend generates PhonePe payment request and encodes to base64
- Backend should call PhonePe initiate payment API first

### Issue 2: "App not installed" error
**Symptom**: Error saying PhonePe app not found
**Cause**: Testing on emulator or PhonePe simulator not installed
**Solution**:
- For SANDBOX: Install PhonePe Simulator app
- For PRODUCTION: Install PhonePe app
- Or use web redirect mode

### Issue 3: App doesn't return after payment
**Symptom**: Stuck on PhonePe app
**Cause**: App schema not configured correctly
**Solution**: 
- Check AndroidManifest.xml has intent-filter for "ecliniq" scheme
- Check Info.plist has CFBundleURLSchemes for "ecliniq"
- Test deep link: `adb shell am start -a android.intent.action.VIEW -d "ecliniq://callback"`

### Issue 4: Payment successful but verification fails
**Symptom**: PhonePe shows success but app shows failure
**Cause**: Backend webhook not updating status or polling endpoint issue
**Solution**:
- Check `/api/payments/status/:merchantTxnId` returns correct status
- Ensure backend receives PhonePe callback webhook
- Check PhonePe dashboard for transaction status

### Issue 5: "Initialization failed" error
**Symptom**: SDK initialization returns false
**Cause**: Invalid merchant ID or incorrect environment
**Solution**:
- Verify merchant ID: `M237OHQ3YCVAO_2511191950`
- Ensure using SANDBOX for testing
- Check if app has internet permission

## 📊 Backend Requirements

### PhonePe Payment Flow on Backend

1. **Initiate Payment** (when booking):
```typescript
POST https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/pay
Headers:
  Content-Type: application/json
  X-VERIFY: SHA256(base64Body + /pg/v1/pay + saltKey) + ### + saltIndex

Body (base64 encoded):
{
  "merchantId": "M237OHQ3YCVAO_2511191950",
  "merchantTransactionId": "TXN_" + timestamp,
  "merchantUserId": patientId,
  "amount": 50000,  // In paise (500 INR)
  "redirectUrl": "https://yourbackend.com/phonepe/callback",
  "redirectMode": "REDIRECT",
  "callbackUrl": "https://yourbackend.com/phonepe/webhook",
  "mobileNumber": "9999999999",
  "paymentInstrument": {
    "type": "PAY_PAGE"
  }
}

Response:
{
  "success": true,
  "code": "PAYMENT_INITIATED",
  "message": "Payment initiated",
  "data": {
    "merchantId": "...",
    "merchantTransactionId": "...",
    "instrumentResponse": {
      "type": "PAY_PAGE",
      "redirectInfo": {
        "url": "...",
        "method": "GET"
      }
    }
  }
}
```

2. **Return to Flutter App**:
Return the base64 encoded request body as `token` to Flutter app.

3. **Handle Webhook** (when PhonePe sends callback):
```typescript
POST /phonepe/webhook
Body:
{
  "response": "base64EncodedResponse"
}

Decode response:
{
  "code": "PAYMENT_SUCCESS",
  "merchantId": "...",
  "merchantTransactionId": "...",
  "transactionId": "...",
  "amount": 50000,
  "state": "COMPLETED"
}

Update payment status in database
```

4. **Status Check Endpoint** (for polling):
```typescript
GET /api/payments/status/:merchantTxnId
Response:
{
  "success": true,
  "data": {
    "merchantTransactionId": "...",
    "status": "SUCCEEDED",  // or PENDING, FAILED, etc.
    "amount": 500,
    "checkedAt": "2025-01-01T10:00:00Z"
  }
}
```

## 🧪 Testing Steps

### 1. Test with Mock Data (Skip PhonePe)
Temporarily modify backend to return `requiresGateway: false` and test wallet-only flow.

### 2. Test PhonePe Simulator
Install PhonePe Simulator app on physical device and test with test credentials.

### 3. Test with Logs
Enable all debug logs above and trace the exact point of failure.

### 4. Test Deep Link
Test if app responds to deep link:
```bash
# Android
adb shell am start -a android.intent.action.VIEW -d "ecliniq://callback?status=success"

# iOS
xcrun simctl openurl booted "ecliniq://callback?status=success"
```

## 📱 PhonePe Simulator Details

**Download**: Search "PhonePe Simulator" on Play Store
**Test Credentials**: Available in PhonePe sandbox documentation
**Environment**: SANDBOX
**Package**: `com.phonepe.simulator`

## 🔗 Useful Links

- PhonePe PG Docs: https://developer.phonepe.com/docs/
- Sandbox Environment: https://sandbox.phonepe.com/
- Flutter Package: https://pub.dev/packages/phonepe_payment_sdk

---

## 🎯 Next Steps

1. Add all debug logs
2. Test booking flow and check console logs
3. Identify where exactly it's failing
4. Check if token is being received from backend
5. Verify app schema configuration
6. Test with PhonePe Simulator app

If you share the console logs, I can help identify the exact issue!

