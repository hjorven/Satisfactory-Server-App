# Roadmap

Geplante Features für App **und** Web-UI. Legende: ✅ fertig · 🔜 als Nächstes · ⬜ offen

## 🎮 Steuerung
- ✅ **#1 Spielstand-Browser & Backup-Wiederherstellung** — Saves laden/löschen, Backups (lokal/NAS) per Tipp wiederherstellen. *(`/api/saves*`, `/api/backups`)*
- ✅ **#2 Server-Einstellungen live ändern** — Auto-Pause, Speichern-beim-Verlassen, Autosave-Intervall. *(`/api/settings`)*
- ✅ **#3 Neustart-Zeitplan** — täglich (Uhrzeit, "nur wenn leer", ntfy-Vorwarnung) + einmaliger Timer. *(`/api/schedule`, `/api/restart-timer`)* In-Game-Chat nicht möglich.
- ✅ **#4 Mod-Liste** — installierte Mods (Ordner/Datei, Größe). *(`/api/mods`)* — Update-Abgleich gegen ficsit.app später.

## 📊 Überwachung
- ✅ **#5 Karte** — native SwiftUI-Karte (Zoom/Pan, Glas-Look): Spieler, Marker, Fahrzeuge, Gebäude-Footprint. *(FRM `getPlayer`/`getMapMarkers`/`getFactory`/`getVehicles`)*
- ✅ **#6 Produktions-Statistik** — Items/min (Produktion & Verbrauch), Auslastung. *(FRM `getProdStats`)*
- ✅ **#7 Host-Monitor** — Uptime, RAM, Load, Speicherplatz (frei/belegt). *(`/api/host`)*
- ✅ **#8 Transport (Züge/Fahrzeuge/Drohnen)** — Liste + Entgleisungs-/Autopilot-Status. *(FRM `getTrains`/`getVehicles`/`getDrone`)*
- ✅ **Strom-Verlaufsdiagramm** — Erzeugung/Verbrauch über Zeit (Teil der Übersicht/Strom).

## 🔔 Infos & Benachrichtigung
- ✅ **#9 Alarm-Center** — Ereignisse ein/aus (Strom, Entgleisung, Spieler join/leave, Server down, wenig Speicher), Schwelle, Verlauf. *(`/api/alerts/*`)*
- ✅ **#10 Spieler-Online-Anzeige** — wer online ist (Name, HP, tot), Online-/Gesamt-Zähler. *(FRM `getPlayer`)*

## Später / Extra
- Widgets + Live Activity + Apple-Watch-Komplikation (Strom/Spieler am Sperrbildschirm)
- In-Game-Chat-Relay / Broadcast aus der App
- Tech-/Meilenstein-Fortschritt (Spielphase, Elevator-Teile)
- Multi-Server-Unterstützung
- SideStore-Umstieg, sobald Apple-Login (Anisette) wieder funktioniert → automatische 7-Tage-Erneuerung

---
*Alle 10 Kernfeatures umgesetzt. Als Nächstes die „Später / Extra"-Liste (Widgets/Live Activity, Mod-Update-Abgleich, SideStore-Umstieg).*
