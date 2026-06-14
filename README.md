# 👁️ Identificador de Cataratas — UPAO

Aplicación móvil desarrollada en Flutter para la clasificación automática de cataratas a partir de imágenes de lámpara de hendidura, utilizando un modelo de deep learning basado en MobileNetV2.

---

## 📋 Descripción

Esta herramienta permite a oftalmólogos cargar imágenes retinales y obtener un diagnóstico automático del tipo de catarata presente, con indicador de confianza y métricas de rendimiento en tiempo real.

---

## 🔬 Tipos de Catarata Detectados

- **Normal** — Sin presencia de catarata
- **Catarata Cortical** — Opacidad en la corteza del cristalino
- **Catarata Nuclear** — Opacidad en el núcleo del cristalino
- **Catarata Subcapsular** — Opacidad en la cápsula posterior del cristalino

---

## 🧠 Modelo de IA

- Arquitectura: **MobileNetV2** (Transfer Learning)
- Framework de entrenamiento: **TensorFlow / Keras**
- Formato de despliegue: **TFLite**
- Precisión obtenida: **92%**
- Normalización: ImageNet (media y desviación estándar por canal)
- Clases: 4 (Cortical, Normal, Nuclear, Subcapsular)

---

## 📱 Funcionalidades

- Carga de imágenes desde la galería del dispositivo
- Clasificación automática con porcentaje de confianza
- Indicador de velocidad de inferencia (< 200ms)
- Monitoreo de uso de RAM en tiempo real
- Interfaz clínica limpia y accesible

---

## 🛠️ Tecnologías Utilizadas

- **Flutter** — Framework de desarrollo móvil
- **Dart** — Lenguaje de programación
- **TFLite Flutter** — Inferencia del modelo en dispositivo
- **Image Picker** — Selección de imágenes desde galería
- **MobileNetV2** — Arquitectura base del modelo

---

## ⚙️ Requisitos

- Flutter SDK `^3.12.2`
- Android 5.0 (API 21) o superior
- Dispositivo físico recomendado para pruebas de rendimiento

---

## 🚀 Instalación y Ejecución

```bash
# Clonar el repositorio
git clone https://github.com/fab7cio/IdentificadorCataratas.git

# Entrar al directorio
cd IdentificadorCataratas

# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo
flutter run

# Generar APK
flutter build apk --release
```

---

## 👥 Autores

- **Alain Lanfranko Alcántara López**
- **Fabricio Alexander Ulco Lazo**

Universidad Privada Antenor Orrego — UPAO  
Facultad de Ingeniería

---

## 📄 Licencia

Proyecto académico — Universidad Privada Antenor Orrego. Todos los derechos reservados.
