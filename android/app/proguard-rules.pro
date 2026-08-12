# ML Kit text recognition (business-card scanner).
#
# The google_mlkit_text_recognition plugin compiles against all five script
# recognisers but only bundles the Latin one, so the other four are absent at
# runtime by design. R8 sees the references and fails the release build unless
# it is told these classes are meant to be missing.
#
# The app only ever constructs TextRecognitionScript.latin, so nothing here can
# be reached — see lib/features/Leads/data/business_card_scanner.dart.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
