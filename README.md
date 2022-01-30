# Divera-Monitor-Raspberry-Pi Shell Scripts Only (based on Dustin1358)

Ich möchte in diesem Repository einige Anpassungen an den Shell Skripten vorstellen, die ich auf Basis des Projektes von @Dustin1358 vorgenommen habe.

# Verwendung eines Basisordners statt dem HOME Folder

Konfigurierbar in der Variable BASEFOLDER

# Duty Time Ermittelung 
Umgestellt auf einen API Call in die Divera API v2. Die daraus entstehende Datei wird einmal am Tag als events.json heruntergeladen. Eine regelmäßige Aktivzeit kann dennoch im Skript festgelegt werden, diese wird als weiterer Eintrag in der JSON hinzugefügt.

# Weitere Pläne
- [ ] Variable einfügen für die Aktivzeit vor/nach den Dienstzeiten
- [ ] Updatezeitraum in JSON einfügen
- [ ] Logging optimieren
