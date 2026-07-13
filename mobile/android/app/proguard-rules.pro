# =====================================================
# Regras R8/ProGuard - GDM Job Cars (release)
# =====================================================

# Google ML Kit - reconhecimento de texto (leitura de placa).
# O R8 referencia modelos de idioma opcionais (chines, japones, coreano,
# devanagari) que nao sao empacotados. Mantemos as classes usadas e
# ignoramos as opcionais para nao quebrar a minificacao.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
