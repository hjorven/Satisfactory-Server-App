# Roadmap

Geplante Features für App **und** Web-UI. Legende: ✅ fertig · 🔜 als Nächstes · ⬜ offen

## 🎮 Steuerung
- ✅ **#1 Spielstand-Browser & Backup-Wiederherstellung** — Saves laden/löschen, Backups (lokal/NAS) per Tipp wiederherstellen. *(`/api/saves*`, `/api/backups`)*
- ⬜ **#2 Server-Einstellungen live ändern** — Autosave-Intervall, Auto-Pause, Max-Spieler, Tickrate aus App/Web. *(`/api/settings`)*
- ⬜ **#3 Geplanter Neustart mit In-Game-Vorwarnung** — Chat-Warnung an Online-Spieler + ntfy vor Neustart; optional nur wenn leer. *(`/api/schedule`, FRM)*
- ⬜ **#4 Mod-Verwaltung mit Update-Check** — installierte Mods + Versionen, Abgleich gegen ficsit.app, hoch-/entfernen. *(`/api/mods`)*

## 📊 Überwachung
- ⬜ **#5 Live-Karte** — Spieler/Züge/Fahrzeuge/Marker auf der Satisfactory-Karte. *(FRM `getMapMarkers`/`getPlayer`/`getVehicles`/`getTrains`/`getDrone`)*
- ⬜ **#6 Produktions-/Fabrik-Statistik** — Items/min, Maschinen laufend vs. blockiert, Lagerstände, Trend. *(FRM `getFactory`)*
- ⬜ **#7 Host- & Ressourcen-Monitor** — Host-CPU/RAM, freier Speicher, Uptime, Spiel-/SML-Version, Steam-Update; Alarm bei wenig Platz. *(neuer Host-Endpunkt)*
- ⬜ **#8 Zug- & Fahrzeug-Zustand** — Entgleisung, Treibstoff, „steht seit X min", Routenprobleme. *(FRM `getTrains`/`getVehicles`/`getDrone`)*
- ✅ **Strom-Verlaufsdiagramm** — Erzeugung/Verbrauch über Zeit (Teil der Übersicht/Strom).

## 🔔 Infos & Benachrichtigung
- ⬜ **#9 Konfigurierbares Alarm-Center** — Ereignisse ein/aus (Stromausfall, Entgleisung, Spieler kommt/geht, Server down, wenig Speicher, Backup fehlgeschlagen), Schwellwerte, Ruhezeiten, Verlauf. *(ntfy-Wächter erweitern)*
- ✅ **#10 Spieler-Online-Anzeige** — wer online ist (Name, HP, tot), Online-/Gesamt-Zähler. *(FRM `getPlayer`)*

## Später / Extra
- Widgets + Live Activity + Apple-Watch-Komplikation (Strom/Spieler am Sperrbildschirm)
- In-Game-Chat-Relay / Broadcast aus der App
- Tech-/Meilenstein-Fortschritt (Spielphase, Elevator-Teile)
- Multi-Server-Unterstützung
- SideStore-Umstieg, sobald Apple-Login (Anisette) wieder funktioniert → automatische 7-Tage-Erneuerung

---
*Reihenfolge nach Sofort-Nutzen/Aufwand. Nächste Kandidaten: #2 (Einstellungen), #5 (Karte), #8 (Züge).*
