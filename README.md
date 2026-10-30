# Satisfactory Server App

Native iPhone-App (SwiftUI, iOS 26 / Liquid Glass) als Client für den eigenen
Satisfactory-Dedicated-Server. Zeigt Übersicht, Strom-Monitoring und erlaubt
Steuerung – und findet den Server automatisch im WLAN.

Alarme (Stromausfall / Zugentgleisung) laufen **nicht** über diese App, sondern
serverseitig als Push über **ntfy** (siehe unten) – damit sie auch bei
geschlossener App und ohne bezahlten Apple-Developer-Account funktionieren.

## Architektur
- Die App spricht ausschließlich mit der **WebUI-API** des Servers (Port 3000):
  `/api/overview`, `/api/frm/getPower`, `/api/control/*`, `/api/simulation`, …
- **Auto-Discovery** per Bonjour (`_satisctl._tcp`); Fallback: manuelle Adresse
  oder Tailscale-Adresse (Einstellungen).
- Admin-Passwort wird im **Schlüsselbund** gespeichert (nur für Steuerung nötig;
  Ansicht geht als Gast ohne Passwort).

## Bauen ohne Mac (GitHub Actions + SideStore)
Das Projekt wird mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus
`project.yml` erzeugt und per GitHub Actions auf einem macOS-Runner gebaut.

- **Jeder Push auf `main`** baut ein unsigniertes `Satisfactory.ipa` und lädt es
  als Workflow-Artefakt hoch (zum Testen des Builds).
- **Ein Tag `vX.Y.Z`** (z. B. `git tag v1.0.0 && git push --tags`) baut die IPA,
  erstellt ein **GitHub Release** mit der IPA und aktualisiert `apps.json`.

### Auf dem iPhone installieren (SideStore)
1. [SideStore](https://sidestore.io) mit gratis Apple-ID einrichten.
2. In SideStore unter *Sources* diese Quelle hinzufügen:
   `https://raw.githubusercontent.com/hjorven/Satisfactory-Server-App/main/apps.json`
3. App „Satisfactory" installieren. SideStore signiert mit deiner Apple-ID und
   erneuert die 7-Tage-Signatur automatisch.

> Erst nach dem ersten Tag/Release existiert die IPA, auf die `apps.json` zeigt.

## Alarme (ntfy)
Serverseitig ist ein Alarm-Wächter aktiv, der FRM (`getPower`/`getTrains`)
überwacht und bei Stromausfall/Entgleisung einen Push an ein ntfy-Topic sendet.
Auf dem iPhone die **ntfy-App** installieren und das Topic abonnieren
(Topic steht in der `.env` des Servers: `NTFY_TOPIC`).

## Lokale Entwicklung (falls doch ein Mac da ist)
```bash
brew install xcodegen
xcodegen generate
open SatisfactoryServerApp.xcodeproj
```

## Struktur
```
project.yml              XcodeGen-Projektdefinition
Sources/                 Swift-Code (App, API, Discovery, Store, Views)
Resources/Assets.xcassets App-Icon & Akzentfarbe
.github/workflows/       CI-Build
apps.json                SideStore-/AltStore-Quelle
```
