# Roadmap

Geplante Features für App **und** Web-UI. Legende: ✅ fertig · 🔜 als Nächstes · ⬜ offen

## 🎮 Steuerung
- ✅ **#1 Spielstand-Browser & Backup-Wiederherstellung** — Saves laden/löschen, Backups (lokal/NAS) per Tipp wiederherstellen. *(`/api/saves*`, `/api/backups`)*
- ✅ **#2 Server-Einstellungen live ändern** — Auto-Pause, Speichern-beim-Verlassen, Autosave-Intervall. *(`/api/settings`)*
- ⬜ **#3 Geplanter Neustart mit Vorwarnung** — Zeitplan-UI + ntfy-Vorwarnung + „nur wenn leer". *(`/api/schedule`)* — Hinweis: In-Game-Chat-Warnung **nicht möglich** (Server-API bietet keine Broadcast-Funktion).
- ✅ **#4 Mod-Liste** — installierte Mods (Ordner/Datei, Größe). *(`/api/mods`)* — Update-Abgleich gegen ficsit.app später.

## 📊 Überwachung
- ⬜ **#5 Live-Karte** — Spieler/Züge/Fahrzeuge/Marker auf der Satisfactory-Karte. *(FRM `getMapMarkers`/`getPlayer`/`getVehicles`/`getTrains`/`getDrone`)*
- ✅ **#6 Produktions-Statistik** — Items/min (Produktion & Verbrauch), Auslastung. *(FRM `getProdStats`)*
- ⬜ **#7 Host- & Ressourcen-Monitor** — Host-CPU/RAM, freier Speicher, Uptime, Spiel-/SML-Version, Steam-Update; Alarm bei wenig Platz. *(neuer Host-Endpunkt)*
- ✅ **#8 Transport (Züge/Fahrzeuge/Drohnen)** — Liste + Entgleisungs-/Autopilot-Status. *(FRM `getTrains`/`getVehicles`/`getDrone`)*
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
