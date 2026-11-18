# Seedlux 🌱

**Transformez votre téléphone en PPFD meter** : Seedlux estime le flux de photons
photosynthétiques (PPFD, µmol/m²/s) et le DLI à partir du capteur de luminosité
du téléphone, avec des présets par type de lampe et une calibration contre le
soleil — comme Photone, en open source.

> ⚠️ Un capteur de téléphone n'est pas un quantum meter. Précision attendue :
> ±20–30 % après calibration. Suffisant pour positionner une lampe ou comparer
> des emplacements ; pas pour de la recherche.

## Installation (Android)

1. Téléchargez le dernier APK depuis les
   [Releases](https://github.com/jmontenez/seedlux/releases/latest).
2. Autorisez l'installation depuis des sources inconnues si Android le demande.
3. C'est tout. **Les mises à jour se font ensuite dans l'app** (vérification
   automatique + bouton dans Réglages).

Compatible [Obtainium](https://github.com/ImranR98/Obtainium) si vous préférez
gérer vos mises à jour vous-même : ajoutez simplement l'URL du repo.

iOS : prévu en v1.1 via TestFlight (l'ALS n'existe pas sur iPhone, la mesure
passera par la caméra).

## Utilisation

1. **Choisissez le préset** correspondant à votre source : la conversion
   lux → PPFD dépend du spectre (soleil ÷54, LED blanche ÷66, HPS ÷82…).
   Il n'existe pas de conversion universelle.
2. **Calibrez une fois** (⚙ → Calibrer) : plein soleil de midi par ciel clair
   (~120 000 lux), bleu du ciel (~20 000 lux), ou un luxmètre de référence.
3. Placez le capteur (bord supérieur du téléphone) au niveau de la canopée,
   face à la lampe. Le DLI est calculé pour votre photopériode.

## Limites connues

- La qualité de l'ALS varie énormément selon le téléphone (quantization par
  paliers sur certains modèles — l'app vous avertit si elle le détecte).
- Le préset « LED rouge/bleu » est très approximatif : un capteur de lux est
  quasi aveugle au rouge 660 nm et au bleu 450 nm.
- Sources des facteurs : notes techniques Apogee Instruments ; méthode de
  calibration solaire du whitepaper Photone.

## Roadmap

- **v1.1** — iOS (mesure caméra via EXIF BrightnessValue, TestFlight).
- **v2** — mode caméra haute précision (RAW + équation ISO 2720 + matrices
  colorimétriques DNG, calibration solaire par modèle clear-sky).

## Build depuis les sources

```sh
flutter pub get
flutter test
flutter build apk --release
```

La CI (GitHub Actions) builde, teste et publie un APK signé à chaque tag `v*`.

## Licence

[MIT](LICENSE)
