# Nakshatra Sales — Flutter starter

A minimal Flutter Android catalog prototype for Nakshatra Sales hardware products, with product browsing, variants, cart quantities, and WhatsApp order-message generation.

## Build locally

1. Install Flutter and Android Studio.
2. Extract this project and open a terminal in the project directory.
3. Run:

   ```bash
   flutter create --platforms=android --project-name nakshatra_sales .
   flutter pub get
   flutter build apk --release
   ```

4. The APK will be at:

   `build/app/outputs/flutter-apk/app-release.apk`

## Build an APK using GitHub Actions

This project includes `.github/workflows/build-apk.yml`.

1. Create a GitHub repository and upload the contents of this folder.
2. Push the files to the `main` branch (or open **Actions** and run **Build Nakshatra Sales APK** manually).
3. Wait for the workflow to finish successfully.
4. Open the completed workflow run and download the `nakshatra-sales-android-apk` artifact. It contains `app-release.apk`.

The workflow creates the Android platform folder, installs dependencies, builds a release APK, and uploads it as a downloadable artifact.

## Prototype limitations

- The catalog currently uses sample products and placeholder product imagery.
- Replace the demo products in `lib/main.dart` with your real product list.
- WhatsApp ordering is configured for business number `919022657558`.
- WhatsApp opens with a pre-filled message; the customer must tap Send.
- Phone OTP login is not implemented yet.
- Products are stored in code, not Firestore. Add Firebase, an admin-only product management workflow, and security rules before publishing.
- Product prices, stock, taxes, delivery charges, and pack sizes must be confirmed by the business before accepting orders.
- This is an unsigned/test release build workflow, not a Play Store publishing setup. Configure signing and test the app on Android devices before public release.
