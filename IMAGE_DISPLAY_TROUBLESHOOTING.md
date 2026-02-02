# Image Display Troubleshooting Guide

## 🔍 Issue: Images Not Displaying in My Issues

This guide will help you diagnose and fix image display issues.

## ✅ Quick Checklist

Run through these checks:

### 1. Verify Images Are Stored in Firestore

Open your Firebase Console:
1. Go to Firestore Database
2. Open the `issues` collection
3. Find one of your issues
4. Check if it has an `encryptedImages` field
5. The field should be an array of objects with `encryptedData`

**Expected structure:**
```json
{
  "id": "1234567890",
  "title": "My Issue",
  "encryptedImages": [
    {
      "id": "img_userId_123456_0",
      "type": "image",
      "encryptedData": "base64_string_here_very_long...",
      "originalFileName": "image.jpg",
      "originalSize": 245678,
      "encryptionVersion": "AES-256-Base64-v1",
      "createdAt": 1234567890,
      "userId": "userId"
    }
  ]
}
```

### 2. Check Console Logs

When you open "My Issues", look for these logs:

**Good signs:**
```
🖼️ IssueCard - Issue: Road Pothole
🖼️ Encrypted images: 2
🖼️ Legacy URLs: 0
🖼️ First encrypted image keys: [id, type, encryptedData, originalFileName, ...]
🔓 Decrypting Firestore image: img_userId_123456_0
📄 Image data keys: [id, type, encryptedData, ...]
📄 Encrypted Base64 length: 150000 chars
✅ Image decrypted successfully: 112345 bytes
```

**Bad signs (no images stored):**
```
🖼️ Encrypted images: 0
🖼️ Legacy URLs: 0
```

**Bad signs (decryption error):**
```
❌ Error decrypting Firestore image: ...
```

### 3. Test Image Upload

Create a test issue with images:

```dart
// Test in MediaUploadTestScreen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MediaUploadTestScreen(),
  ),
);
```

Or create an issue normally:
1. Go to "Report Issue" tab
2. Select images (use small images < 1MB)
3. Fill in details and submit
4. Go to "My Issues" to see if images display

## 🐛 Common Problems & Solutions

### Problem 1: Images Not Being Stored

**Symptoms:**
- `encryptedImages` field is empty `[]` in Firestore
- Console shows: "Processed 0/2 images"

**Causes:**
- Images are too large (> 1MB after Base64 encoding)
- Image processing failed

**Solution:**
```dart
// In issue_report_screen.dart, check logs for:
debugPrint('🔐 Processing ${_selectedImages.length} images...');
// Should see:
// ✅ Successfully processed 2/2 images
```

If images are too large:
- Use smaller images
- Take photos at lower quality
- The service automatically compresses, but very large images (> 3MB original) may still fail

### Problem 2: Images Stored But Not Displaying

**Symptoms:**
- `encryptedImages` array exists in Firestore
- Console shows encrypted images count > 0
- But images show as grey boxes or broken icons

**Causes:**
- Decryption failing
- Wrong encryption service
- Data format mismatch

**Solution:**

Check the console for decryption errors:
```
❌ Error decrypting Firestore image: ...
```

If you see this, the issue might be:

1. **Different encryption keys:**
   ```dart
   // Both services must use the SAME key
   // Check: lib/services/image_encryption_service.dart
   // And: lib/services/media_encryption_service.dart
   ```

2. **Missing `encryptedData` field:**
   ```
   ❌ No encrypted data found in image data
   ```
   This means the data structure is wrong. Rebuild the issue with proper image upload.

### Problem 3: Images Display But Are Corrupted

**Symptoms:**
- Images show but look garbled or wrong colors

**Cause:**
- Encryption/decryption key mismatch

**Solution:**
The encryption key must be consistent. Check both:
- `ImageEncryptionService` (used for old issues)
- `MediaEncryptionService` (new service)

Both should have the SAME key:
```dart
final keyString = 'SIH_CIVIC_CONNECT_2024_SECURE_KEY_FOR_IMAGES';
```

### Problem 4: "setState() after dispose()" Errors

**Symptoms:**
- Error in console about setState after dispose
- Happens when navigating away quickly

**This is fixed!** The updated code now checks `mounted` before calling `setState()`.

## 🔧 Manual Verification Steps

### Step 1: Check Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Navigate to `issues` collection
5. Open any issue document
6. Look for `encryptedImages` array

**What to check:**
- Does the array exist?
- Is it empty `[]` or have objects?
- Do objects have `encryptedData` field?
- Is `encryptedData` a long Base64 string?

### Step 2: Test Image Upload

1. Open app
2. Go to "Report Issue"
3. Take/select 1-2 small images
4. Fill in details
5. Submit issue

**Watch console for:**
```
🔐 Processing 2 images for Firestore storage...
✅ Successfully processed 2/2 images for Firestore
💾 Storing issue in Firestore database...
✅ Issue stored in Firestore successfully
```

### Step 3: Verify in My Issues

1. Go to "My Issues" tab
2. Find the issue you just created
3. Images should display as thumbnails

**Watch console for:**
```
🖼️ IssueCard - Issue: Your Issue Title
🖼️ Encrypted images: 2
🔓 Decrypting Firestore image: img_...
✅ Image decrypted successfully: 123456 bytes
```

## 📋 Debug Checklist

If images still don't display, go through this checklist:

- [ ] Images are being selected (check image picker works)
- [ ] Images are being processed (check console logs during submission)
- [ ] Images are stored in Firestore (check Firebase Console)
- [ ] Issues are being retrieved (check "My Issues" loads)
- [ ] `encryptedImages` field is populated (check console logs in My Issues)
- [ ] Decryption is working (check for decryption success messages)
- [ ] No errors in console (check for ❌ messages)

## 🚀 Quick Fixes

### Fix 1: Clear App Data & Retry

```bash
# Stop app
flutter clean
flutter pub get
flutter run
```

Then:
1. Login again
2. Create a NEW issue with images
3. Check if it displays

### Fix 2: Use Test Screen

The app has a built-in test screen:

```dart
// Add this button temporarily to test
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaUploadTestScreen(),
      ),
    );
  },
  child: Text('Test Image Upload'),
)
```

This will:
- Test image picking
- Test encryption
- Test Firestore storage
- Show detailed logs

### Fix 3: Check Firestore Rules

Your Firestore rules must allow reading/writing:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /issues/{issueId} {
      // Allow authenticated users to read
      allow read: if request.auth != null;
      
      // Allow authenticated users to write their own issues
      allow create: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
      
      // Allow users to update their own issues
      allow update: if request.auth != null && 
                      resource.data.userId == request.auth.uid;
    }
  }
}
```

## 💡 Expected Behavior

### When Creating Issue:
1. User selects 1-3 images
2. Images are compressed automatically
3. Images are encrypted with AES-256
4. Images are converted to Base64
5. Images are stored in `encryptedImages` array
6. Success message shows

### When Viewing My Issues:
1. Issues load from Firestore
2. For each issue with `encryptedImages`:
   - Up to 3 thumbnails display
   - Images decrypt automatically
   - "+N" badge shows if > 3 images
3. Tapping issue shows full-size images

## 📞 Still Not Working?

If images still don't display after all these checks:

1. **Check exact error message** in console
2. **Take screenshot** of Firebase Console showing the issue document
3. **Check app logs** when opening My Issues screen

Look for:
- Empty `encryptedImages` array → Images not being stored
- No decryption logs → Widget not rendering
- Decryption errors → Key mismatch or data corruption

## 🎯 Quick Test Commands

```dart
// Add this to any screen to test
void _debugImages() async {
  final firestore = FirebaseFirestore.instance;
  final issues = await firestore.collection('issues')
      .where('userId', isEqualTo: currentUser.id)
      .limit(1)
      .get();
  
  if (issues.docs.isNotEmpty) {
    final data = issues.docs.first.data();
    print('Issue data keys: ${data.keys.toList()}');
    print('Encrypted images: ${data['encryptedImages']}');
    print('Image URLs: ${data['imageUrls']}');
  }
}
```

---

**Most Common Solution:** The issue is usually that old issues don't have `encryptedImages`, only new ones do. Create a NEW issue with images after running the latest code!

