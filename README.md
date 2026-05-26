# KittyCheck (cat_pain_detector)

KittyCheck is a Flutter mobile application that helps assess acute pain in cats using the Feline Grimace Scale (FGS). The app combines AI-assisted facial analysis with manual adjustment and history tracking for research and educational use.

## Key features

- AI-assisted FGS scoring from a photo of a cat's face
- Manual adjustment of each facial action unit
- Save assessment results to history for later review
- In-app guide and attribution links

## The Feline Grimace Scale (FGS)

The FGS is a validated tool for assessing acute pain in cats by evaluating five facial action units (each scored 0–2). The five units used by KittyCheck are:

1. Ear Position
2. Orbital Tightening
3. Muzzle Tension
4. Whiskers Change
5. Head Position

Total scores range 0–10. Higher scores indicate a greater likelihood of pain; a score of 4 or above may suggest the need for analgesic treatment depending on the clinical context. KittyCheck is intended for acute pain assessment only and is not a substitute for professional veterinary care.

## How it works

1. Capture or upload a photo of the cat's face
2. The system detects the face and extracts key facial regions
3. Trained models produce automated scores for each FGS unit
4. Users can manually adjust scores with the in-app guidance
5. Save results to the app history for tracking

## Installation & Development

Prerequisites: Flutter SDK (see https://docs.flutter.dev)

Run locally:

```bash
flutter pub get
flutter run
```

Build an APK:

```bash
flutter clean
flutter pub get
flutter build apk
# Release APK is at: build/app/outputs/flutter-apk/app-release.apk
```

Run on an Android emulator (examples):

```bash
flutter emulators --launch Pixel_6_API_34
flutter emulators --launch Pixel_6a
flutter run
```

## Responsible use & Disclaimer

This app is designed to assist cat owners and researchers in detecting signs of acute pain using the Feline Grimace Scale. It is not a diagnostic tool and must not replace professional veterinary judgment or clinical examination. Always consult a qualified veterinarian for diagnosis and treatment.

## Attribution & Credits

- FGS reference: Evangelista et al., 2019
- Official FGS website: https://felinegrimacescale.com
- Cat face icons: Emoji icons created by Ains - Flaticon (https://www.flaticon.com/free-icons/emoji)

AI and developer credits:

- Face detection & facial region detection: Custom-trained models (method inspired by Automated Detection of Cat Facial Landmarks)
- Developer: Ralph Philip M. Caoile

## Version

KittyCheck — Version 1.1.0

