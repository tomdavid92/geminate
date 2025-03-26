# Gemini Integration Instructions

Follow these steps to integrate the Gemini image generation API into your app:

## 1. Add New Files

Add these files to your project:
- `Secrets.swift` - For securely storing your API key
- `GeminiService.swift` - Service for communicating with the Gemini API
- Updated `ResultView.swift` - Updated to use the Gemini service

## 2. Set Your API Key

Open `Secrets.swift` and replace `YOUR_GEMINI_API_KEY` with your actual Gemini API key.

## 3. Update Info.plist

Add the following entries to your Info.plist file for proper permissions:

```xml
<!-- Permission for saving photos to the gallery -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save edited images to your photo gallery.</string>

<!-- Permission for accessing the photo library (may already be included) -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to select photos for editing.</string>
```

## 4. Add to .gitignore

Add `Secrets.swift` to your `.gitignore` file to keep your API key secure:

```
# API Keys
Secrets.swift
```

## 5. Testing

The app should now:
1. Allow users to select an image
2. Send it to Gemini with their prompt
3. Display the edited image
4. Allow further editing with new prompts
5. Support saving to the photo gallery

## Troubleshooting

If you encounter issues:
- Verify your API key is correct
- Check internet connectivity
- Ensure you're using the approved Gemini model name
- Consider rate limiting if making many requests
