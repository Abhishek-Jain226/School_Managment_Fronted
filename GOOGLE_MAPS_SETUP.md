# Google Maps Setup for Flutter Web

## Error Explanation

The error **"TypeError: Cannot read properties of undefined (reading 'maps')"** occurs because:

1. **Google Maps JavaScript API is not loaded**: The `web/index.html` file was missing the Google Maps JavaScript API script tag
2. **Flutter Web requires the JavaScript API**: Unlike mobile apps, Flutter Web needs the Google Maps JavaScript API to be loaded in the HTML file
3. **The API tries to access `google.maps`**: When the Flutter code tries to render the map, it looks for the `google.maps` object, but it's `undefined` because the script wasn't loaded

## Fix Applied

✅ Added Google Maps JavaScript API script to `web/index.html`
✅ Added error handling in the Flutter code
✅ Added loading state while waiting for driver location

## Required Steps

### 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable **Maps JavaScript API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Maps JavaScript API"
   - Click "Enable"
4. Create an API Key:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the API key
5. **Restrict the API Key** (Recommended for production):
   - Click on the API key to edit it
   - Under "Application restrictions", select "HTTP referrers (web sites)"
   - Add your domain (e.g., `localhost:*, 127.0.0.1:*`)
   - Under "API restrictions", select "Restrict key" and choose "Maps JavaScript API"

### 2. Configure API Key in index.html

Open `web/index.html` and replace `YOUR_API_KEY` with your actual API key:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&libraries=places"></script>
```

**Example:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&libraries=places"></script>
```

### 3. Restart Flutter App

After adding the API key, restart your Flutter web app:
```bash
flutter run -d chrome
```

## Testing

1. **Without API Key**: You'll see the error "Cannot read properties of undefined (reading 'maps')"
2. **With Invalid API Key**: You'll see a Google Maps error message
3. **With Valid API Key**: The map should load and display correctly

## Cost Considerations

- Google Maps JavaScript API has a free tier: **$200 credit per month**
- This typically covers:
  - ~28,000 map loads per month
  - ~40,000 directions requests per month
- For most school tracking applications, this should be sufficient
- Monitor usage in Google Cloud Console

## Alternative Solutions

If you don't want to use Google Maps, you can:
1. Use **OpenStreetMap** with `flutter_map` package
2. Use **Mapbox** (requires API key but different pricing)
3. Use **Apple Maps** (iOS only)

## Troubleshooting

### Error: "This API key is not authorized"
- Make sure Maps JavaScript API is enabled
- Check API key restrictions

### Error: "RefererNotAllowedMapError"
- Add your domain to API key restrictions
- For localhost: Add `localhost:*` and `127.0.0.1:*`

### Map not showing
- Check browser console for errors
- Verify API key is correct
- Check if Maps JavaScript API is enabled
- Ensure script tag is in `<head>` section

---

**Note**: The API key is visible in the HTML source code. For production, consider:
- Using environment variables
- Implementing a proxy server to hide the API key
- Using API key restrictions to limit usage

