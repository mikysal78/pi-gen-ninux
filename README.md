# Overlay pi-gen: stage `ninux`

Questo archivio contiene esclusivamente lo stage personalizzato Ninux da copiare nella radice del repository pi-gen ufficiale. Non contiene una copia completa di pi-gen.

## Installazione

Copia la directory `ninux/` nella radice del repository, allo stesso livello di `stage0/`, `stage1/` e `stage2/`.

Nel file `config` della build imposta, mantenendo gli altri stage che ti servono:

```bash
STAGE_LIST="stage0 stage1 stage2 ninux"
```

Per una build Mini, inserisci `ninux` dopo l'ultimo stage standard previsto dalla tua lista Mini. Il nome dello stage è esattamente `ninux`, non `stage-ninux`.

## Cosa fa

- Lascia invariata la configurazione DHCP predefinita dell'immagine.
- Installa la chiave SSH pubblica fornita per `root` e per `FIRST_USER_NAME`.
- Installa e abilita il servizio SSH.
- Installa `/root/ninux-configure-network`, da eseguire manualmente dopo il flash.

## Configurazione IP dopo il flash

Configurazione statica interattiva:

```bash
sudo /root/ninux-configure-network
```

Ripristino DHCP:

```bash
sudo /root/ninux-configure-network --dhcp
```

Lo script gestisce NetworkManager tramite `nmcli` (presente nella configurazione Raspberry Pi OS di partenza). Lo stage non installa né riconfigura NetworkManager: non viene eseguito durante la build e non cambia la rete dell'immagine finché non viene lanciato manualmente.

## Nota

Lo stage richiede che lo stage precedente abbia già creato l'utente indicato da `FIRST_USER_NAME`. La chiave SSH pubblica è incorporata nello stage come richiesto; non contiene credenziali private.
