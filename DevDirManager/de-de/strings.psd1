# Dies ist die Stelle, an der die Zeichenfolgen stehen, die von
# Write-PSFMessage, Stop-PSFFunction oder den PSFramework-Validierungs-Scriptblocks geschrieben werden
@{
    # Import-DevDirectoryList
    'ImportDevDirectoryList.Start'                          = "Starte Import-DevDirectoryList von Pfad: '{0}', Format: '{1}'"
    'ImportDevDirectoryList.ConfigurationFormatExplicit'    = "Verwende explizit angegebenes Format: '{0}'"
    'ImportDevDirectoryList.ConfigurationFormatDefault'     = "Verwende Standardformat aus Konfiguration: '{0}'"
    'ImportDevDirectoryList.FileNotFound'                   = "Die angegebene Repository-Listendatei '{0}' existiert nicht."
    'ImportDevDirectoryList.FileNotFoundWarning'            = "Importdatei nicht gefunden: '{0}'"
    'ImportDevDirectoryList.Import'                         = "Lese Repository-Liste von: '{0}'"
    'ImportDevDirectoryList.InferFormatFailed'              = "Konnte Importformat nicht aus Pfad '{0}' ableiten. Geben Sie den Format-Parameter an."
    'ImportDevDirectoryList.FormatResolved'                 = "Aufgelöstes Importformat: '{0}'"
    'ImportDevDirectoryList.DeserializationStart'           = "Starte Deserialisierung aus {0}-Format"
    'ImportDevDirectoryList.DeserializationCSV'             = "Verwende Import-Csv für CSV-Deserialisierung"
    'ImportDevDirectoryList.TypeConversionCSV'              = "{0} Objekte aus CSV importiert, führe Typkonvertierungen durch"
    'ImportDevDirectoryList.StatusDateParsed'               = "StatusDate erfolgreich geparst: '{0}'"
    'ImportDevDirectoryList.CompleteCSV'                    = "{0} Repositories erfolgreich aus CSV-Datei importiert"
    'ImportDevDirectoryList.DeserializationJSON'            = "Verwende ConvertFrom-Json für JSON-Deserialisierung"
    'ImportDevDirectoryList.EmptyJSON'                      = "JSON-Datei ist leer oder enthält nur Leerzeichen"
    'ImportDevDirectoryList.TypeConversionJSON'             = "{0} Objekte aus JSON importiert, füge Typinformationen hinzu"
    'ImportDevDirectoryList.CompleteJSON'                   = "{0} Repositories erfolgreich aus JSON-Datei importiert"
    'ImportDevDirectoryList.DeserializationXML'             = "Verwende Import-Clixml für XML-Deserialisierung"
    'ImportDevDirectoryList.TypeConversionXML'              = "{0} Objekte aus XML importiert, füge Typinformationen hinzu"
    'ImportDevDirectoryList.CompleteXML'                    = "{0} Repositories erfolgreich aus XML-Datei importiert"

    # Export-DevDirectoryList
    'ExportDevDirectoryList.Start'                          = "Starte Export-DevDirectoryList zu Pfad: '{0}', Format: '{1}'"
    'ExportDevDirectoryList.ConfigurationFormatExplicit'    = "Verwende explizit angegebenes Format: '{0}'"
    'ExportDevDirectoryList.ConfigurationFormatDefault'     = "Verwende Standardformat aus Konfiguration: '{0}'"
    'ExportDevDirectoryList.CollectObject'                  = "Sammle Repository-Objekt in Exportliste"
    'ExportDevDirectoryList.ProcessExport'                  = "Verarbeite Export von {0} Repository-Objekten"
    'ExportDevDirectoryList.NoRepositoryEntries'            = 'Keine Repository-Einträge für Export erhalten.'
    'ExportDevDirectoryList.FormatResolved'                 = "Aufgelöstes Exportformat: '{0}'"
    'ExportDevDirectoryList.CreateOutputDirectory'          = "Erstelle Ausgabeverzeichnis: '{0}'"
    'ExportDevDirectoryList.ActionExport'                   = 'Exportiere Repository-Liste als {0}'
    'ExportDevDirectoryList.ExportCanceled'                 = "Export vom Benutzer abgebrochen (WhatIf/Confirm)"
    'ExportDevDirectoryList.SerializationStart'             = "Serialisiere {0} Repositories zu '{1}' im {2}-Format"
    'ExportDevDirectoryList.SerializationCSV'               = "Verwende Export-Csv für CSV-Serialisierung"
    'ExportDevDirectoryList.SerializationJSON'              = "Verwende ConvertTo-Json mit Tiefe 5 für JSON-Serialisierung"
    'ExportDevDirectoryList.SerializationXML'               = "Verwende Export-Clixml für XML-Serialisierung"
    'ExportDevDirectoryList.Complete'                       = "{0} Repositories erfolgreich zu '{1}' im {2}-Format exportiert"

    # Get-DevDirectory
    'GetDevDirectory.Start'                                 = "Starte Get-DevDirectory mit RootPath: '{0}', SkipRemoteCheck: {1}"
    'GetDevDirectory.ConfigurationRemoteName'               = "Verwende Remote-Namen '{0}' aus Konfiguration"
    'GetDevDirectory.ScanStart'                             = "Durchsuche Verzeichnisbaum beginnend bei: '{0}'"
    'GetDevDirectory.RepositoryFound'                       = "Repository gefunden bei: '{0}'"
    'GetDevDirectory.RemoteCheckStart'                      = "Prüfe Remote-Erreichbarkeit für: '{0}'"
    'GetDevDirectory.RemoteCheckResult'                     = "Remote-Erreichbarkeit für '{0}': {1}"
    'GetDevDirectory.RemoteCheckNoUrl'                      = "Keine Remote-URL für '{0}' gefunden, markiere als nicht erreichbar"
    'GetDevDirectory.DirectoryEnumerationFailed'            = 'Überspringe Verzeichnis {0} aufgrund von {1}.'
    'GetDevDirectory.ScanComplete'                          = "Repository-Scan abgeschlossen. {0} Repositories gefunden"

    # Restore-DevDirectory
    'RestoreDevDirectory.Start'                             = "Starte Restore-DevDirectory zu Ziel: '{0}', Force: {1}, SkipExisting: {2}, ShowGitOutput: {3}"
    'RestoreDevDirectory.ConfigurationGitExe'               = "Verwende Git-Executable: '{0}'"
    'RestoreDevDirectory.GitExeResolved'                    = "Git-Executable aufgelöst zu: '{0}'"
    'RestoreDevDirectory.GitExeNotFound'                    = "Git-Executable nicht gefunden: '{0}'"
    'RestoreDevDirectory.GitExecutableMissing'              = "Kann Git-Executable '{0}' nicht finden. Stellen Sie sicher, dass Git installiert und im PATH verfügbar ist."
    'RestoreDevDirectory.DestinationNormalized'             = "Normalisierter Zielpfad: '{0}'"
    'RestoreDevDirectory.ProcessingRepositories'            = "Verarbeite {0} Repositories für Wiederherstellung"
    'RestoreDevDirectory.MissingRemoteUrl'                  = 'Überspringe Repository ohne RemoteUrl: {0}.'
    'RestoreDevDirectory.MissingRelativePath'               = 'Überspringe Repository ohne RelativePath für Remote {0}.'
    'RestoreDevDirectory.UnsafeRelativePath'                = "Überspringe Repository mit unsicherem relativen Pfad '{0}'."
    'RestoreDevDirectory.OutOfScopePath'                    = "Überspringe Repository mit Pfad außerhalb des Gültigkeitsbereichs '{0}'."
    'RestoreDevDirectory.ExistingTargetVerbose'             = 'Überspringe vorhandenes Repository-Ziel {0}.'
    'RestoreDevDirectory.TargetExistsWarning'               = 'Zielverzeichnis {0} existiert bereits. Verwenden Sie -Force zum Überschreiben oder -SkipExisting zum Ignorieren.'
    'RestoreDevDirectory.ActionClone'                       = 'Klone Repository von {0}'
    'RestoreDevDirectory.CloneFailed'                       = "git clone für '{0}' fehlgeschlagen mit Exit-Code {1}."
    'RestoreDevDirectory.ConfigFailed'                      = "Fehler beim Setzen der git-Konfiguration {0} auf '{1}' für Repository bei {2}. Exit-Code: {3}"
    'RestoreDevDirectory.InaccessibleRemoteSkipped'         = "Überspringe Repository '{0}' mit nicht erreichbarem Remote: {1}"
    'RestoreDevDirectory.Complete'                          = "Wiederherstellungsvorgang abgeschlossen. {0} Repositories verarbeitet"

    # Sync-DevDirectoryList
    'SyncDevDirectoryList.Start'                            = "Starte Sync-DevDirectoryList mit DirectoryPath: '{0}', RepositoryListPath: '{1}', Force: {2}, SkipExisting: {3}, ShowGitOutput: {4}"
    'SyncDevDirectoryList.ConfigurationRemoteName'          = "Verwende Remote-Namen '{0}' aus Konfiguration"
    'SyncDevDirectoryList.DirectoryNormalized'              = "Normalisierter Verzeichnispfad: '{0}'"
    'SyncDevDirectoryList.SyncStart'                        = "Starte Synchronisierungsvorgang"
    'SyncDevDirectoryList.ImportingFromFile'                = "Repository-Listendatei existiert, importiere Einträge von: '{0}'"
    'SyncDevDirectoryList.ActionCreateRootDirectory'        = 'Erstelle Repository-Stammverzeichnis'
    'SyncDevDirectoryList.ActionCloneFromList'              = 'Klone {0} Repository/Repositories aus Liste'
    'SyncDevDirectoryList.ActionCreateListDirectory'        = 'Erstelle Verzeichnis für Repository-Listendatei'
    'SyncDevDirectoryList.ActionUpdateListFile'             = 'Aktualisiere Repository-Listendatei'
    'SyncDevDirectoryList.ImportFailed'                     = 'Konnte Repository-Liste nicht von {0} importieren: {1}'
    'SyncDevDirectoryList.UnsafeFileEntry'                  = 'Repository-Listeneintrag mit unsicherem relativen Pfad {0} wurde übersprungen.'
    'SyncDevDirectoryList.UnsafeLocalEntry'                 = 'Ignoriere lokales Repository mit unsicherem relativen Pfad {0}.'
    'SyncDevDirectoryList.RemoteUrlMismatch'                = 'Remote-URL-Konflikt für {0}. Behalte lokalen Wert {1} statt Dateiwert {2}.'
    'SyncDevDirectoryList.MissingRemoteUrl'                 = 'Repository-Listeneintrag {0} hat keine RemoteUrl und kann nicht geklont werden.'
    'SyncDevDirectoryList.MissingRootDirectory'             = 'Repository-Stammverzeichnis {0} existiert nicht; überspringe Klon-Operationen.'
    'SyncDevDirectoryList.InaccessibleRemoteSkipped'        = "Überspringe Repository '{0}' mit nicht erreichbarem Remote: {1}"
    'SyncDevDirectoryList.Complete'                         = "Synchronisierung abgeschlossen. Endgültige Repository-Anzahl: {0}"

    # Publish-DevDirectoryList
    'PublishDevDirectoryList.Start'                         = "Starte Publish-DevDirectoryList mit ParameterSet: '{0}', Public: {1}, GistId: '{2}'"
    'PublishDevDirectoryList.AuthenticationDecrypt'         = "Entschlüssele AccessToken für GitHub-API-Authentifizierung"
    'PublishDevDirectoryList.TokenEmpty'                    = 'Das bereitgestellte Zugriffstoken ist nach der Konvertierung leer.'
    'PublishDevDirectoryList.TokenEmptyError'               = "AccessToken ist leer oder null"
    'PublishDevDirectoryList.ConfigurationApiUrl'           = "Konfigurierter API-Endpunkt: '{0}'"
    'PublishDevDirectoryList.CollectPipelineObject'         = "Sammle Repository-Objekt aus Pipeline"
    'PublishDevDirectoryList.NoPipelineData'                = 'Keine Repository-Metadaten aus der Pipeline erhalten.'
    'PublishDevDirectoryList.ConvertToJson'                 = "Konvertiere {0} Pipeline-Objekte zu JSON"
    'PublishDevDirectoryList.ReadFile'                      = "Lese Repository-Liste aus Datei: '{0}'"
    'PublishDevDirectoryList.FormatDetected'                = "Erkanntes Dateiformat: '{0}'"
    'PublishDevDirectoryList.ReadJsonDirect'                = "Datei ist JSON, lese direkt"
    'PublishDevDirectoryList.ConvertFormat'                 = "Konvertiere {0} zu JSON"
    'PublishDevDirectoryList.EmptyContent'                  = 'Der Inhalt der Repository-Liste ist leer. Es wird nichts veröffentlicht.'
    'PublishDevDirectoryList.SearchGist'                    = "Suche nach vorhandenem Gist mit Beschreibung 'GitRepositoryList'"
    'PublishDevDirectoryList.GistFound'                     = "Vorhandener Gist gefunden mit ID: '{0}'"
    'PublishDevDirectoryList.GistNotFound'                  = "Kein vorhandener Gist gefunden, erstelle neuen"
    'PublishDevDirectoryList.QueryGistFailed'               = 'Fehler beim Abfragen vorhandener Gists: {0}'
    'PublishDevDirectoryList.UsingProvidedGistId'           = "Verwende bereitgestellte GistId: '{0}'"
    'PublishDevDirectoryList.PublishCanceled'               = "Veröffentlichung vom Benutzer abgebrochen (WhatIf/Confirm)"
    'PublishDevDirectoryList.UpdatingGist'                  = "Aktualisiere vorhandenen Gist: '{0}'"
    'PublishDevDirectoryList.CreatingGist'                  = "Erstelle neuen Gist"
    'PublishDevDirectoryList.Complete'                      = "Repository-Liste erfolgreich zu Gist veröffentlicht. GistId: '{0}', URL: '{1}'"
    'PublishDevDirectoryList.CleanupTokens'                 = "Räume Authentifizierungstokens auf"
    'PublishDevDirectoryList.ActionPublish'                 = 'Veröffentliche DevDirManager-Repository-Liste zu GitHub-Gist'
    'PublishDevDirectoryList.TargetLabelCreate'             = 'Erstelle Gist GitRepositoryList'
    'PublishDevDirectoryList.TargetLabelUpdate'             = 'Aktualisiere Gist {0}'

    # Internal functions - Get-DevDirectoryRemoteUrl
    'GetDevDirectoryRemoteUrl.Start'                        = "Extrahiere Remote-URL für '{0}' aus Repository: '{1}'"
    'GetDevDirectoryRemoteUrl.ConfigPath'                   = "Git-Config-Pfad: '{0}'"
    'GetDevDirectoryRemoteUrl.ConfigMissing'                = 'Keine .git\\config-Datei gefunden bei {0}.'
    'GetDevDirectoryRemoteUrl.ConfigNotFound'               = "Git-Config-Datei nicht gefunden, gebe null zurück"
    'GetDevDirectoryRemoteUrl.ReadingConfig'                = "Lese Git-Config-Datei"
    'GetDevDirectoryRemoteUrl.SearchingSection'             = "Suche nach Abschnittsmuster: '{0}'"
    'GetDevDirectoryRemoteUrl.RemoteUrlFound'               = "Remote-URL für '{0}': '{1}'"
    'GetDevDirectoryRemoteUrl.RemoteNotFound'               = "Remote '{0}' nicht gefunden oder hat keine URL konfiguriert"

    # Internal functions - Get-DevDirectoryUserInfo
    'GetDevDirectoryUserInfo.Start'                         = "Extrahiere Benutzerinfo aus Repository: '{0}'"
    'GetDevDirectoryUserInfo.ConfigPath'                    = "Git-Config-Pfad: '{0}'"
    'GetDevDirectoryUserInfo.ConfigMissing'                 = "Keine .git\\config-Datei gefunden bei {0}."
    'GetDevDirectoryUserInfo.ConfigNotFound'                = "Git-Config-Datei nicht gefunden, gebe Null-Werte zurück"
    'GetDevDirectoryUserInfo.ReadingConfig'                 = "Lese Git-Config-Datei"
    'GetDevDirectoryUserInfo.SectionFound'                  = "[user]-Abschnitt in Git-Config gefunden"
    'GetDevDirectoryUserInfo.UserNameFound'                 = "user.name gefunden: '{0}'"
    'GetDevDirectoryUserInfo.UserEmailFound'                = "user.email gefunden: '{0}'"
    'GetDevDirectoryUserInfo.Result'                        = "Benutzerinfo extrahiert - UserName: '{0}', UserEmail: '{1}'"

    # Internal functions - Test-DevDirectoryRemoteAccessible
    'TestDevDirectoryRemoteAccessible.EmptyUrl'             = "Remote-URL ist leer oder Leerzeichen; überspringe Remote-Erreichbarkeitsprüfung."
    'TestDevDirectoryRemoteAccessible.CheckingRemote'       = "Prüfe Remote-Erreichbarkeit für: {0}"
    'TestDevDirectoryRemoteAccessible.Timeout'              = "Remote-Prüfung nach {0} Sekunden abgelaufen für: {1}"
    'TestDevDirectoryRemoteAccessible.Accessible'           = "Remote ist erreichbar: {0}"
    'TestDevDirectoryRemoteAccessible.NotAccessible'        = "Remote ist nicht erreichbar (Exit-Code {0}): {1}"
    'TestDevDirectoryRemoteAccessible.Error'                = "Fehler bei Prüfung der Remote-Erreichbarkeit für {0}: {1}"
    'TestDevDirectoryRemoteAccessible.ProcessStartFailed'   = "Konnte git ls-remote nicht für Remote '{0}' starten. Überprüfen Sie den Git-Executable-Pfad."

    # Internal functions - ConvertTo-NormalizedRelativePath
    'ConvertToNormalizedRelativePath.Start'                 = "Normalisiere relativen Pfad: '{0}'"
    'ConvertToNormalizedRelativePath.EmptyPath'             = "Pfad ist leer, Leerzeichen oder '.', gebe '.' zurück"
    'ConvertToNormalizedRelativePath.AfterTrim'             = "Nach Trim: '{0}'"
    'ConvertToNormalizedRelativePath.AfterCleanup'          = "Nach Slash-Bereinigung: '{0}'"
    'ConvertToNormalizedRelativePath.BecameEmpty'           = "Pfad wurde nach Normalisierung leer, gebe '.' zurück"
    'ConvertToNormalizedRelativePath.Result'                = "Pfad normalisiert: '{0}' -> '{1}'"

    # Internal functions - Add-RepositoryTypeName
    'AddRepositoryTypeName.Start'                           = "Füge DevDirManager.Repository-Typnamen zum Objekt hinzu"
    'AddRepositoryTypeName.Result'                          = "Typname zum Objekt hinzugefügt"

    # Show-DevDirectoryDashboard
    'ShowDevDirectoryDashboard.Start'                       = "Starte Show-DevDirectoryDashboard mit RootPath '{0}' (ShowWindow={1}, PassThru={2})."
    'ShowDevDirectoryDashboard.Complete'                    = "Show-DevDirectoryDashboard abgeschlossen."
    'ShowDevDirectoryDashboard.UnsupportedPlatform'         = "Show-DevDirectoryDashboard benötigt Windows mit WPF-Unterstützung."
    'ShowDevDirectoryDashboard.RequiresSta'                 = "Show-DevDirectoryDashboard muss in einer für STA-Threading konfigurierten PowerShell-Sitzung ausgeführt werden."
    'ShowDevDirectoryDashboard.XamlMissing'                 = "Die Dashboard-Layoutdatei '{0}' konnte nicht gefunden werden."
    'ShowDevDirectoryDashboard.WindowTitle'                 = "DevDirManager Dashboard"
    'ShowDevDirectoryDashboard.Header'                      = "DevDirManager Kontrollzentrum"
    'ShowDevDirectoryDashboard.SubHeader'                   = "Entdecken, exportieren, wiederherstellen und synchronisieren Sie Repositories an einem Ort."
    'ShowDevDirectoryDashboard.DiscoverTabHeader'           = "Entdecken & Exportieren"
    'ShowDevDirectoryDashboard.DiscoverPathLabel'           = "Quellordner:"
    'ShowDevDirectoryDashboard.BrowseButton'                = "Durchsuchen"
    'ShowDevDirectoryDashboard.ScanButton'                  = "Scannen"
    'ShowDevDirectoryDashboard.ExportTabHeader'             = "Exportieren"
    'ShowDevDirectoryDashboard.ExportFormatLabel'           = "Format:"
    'ShowDevDirectoryDashboard.ExportPathLabel'             = "Ausgabedatei:"
    'ShowDevDirectoryDashboard.ExportRunButton'             = "Exportieren"
    'ShowDevDirectoryDashboard.ImportTabHeader'             = "Importieren & Wiederherstellen"
    'ShowDevDirectoryDashboard.ImportPathLabel'             = "Datendatei:"
    'ShowDevDirectoryDashboard.ImportLoadButton'            = "Laden"
    'ShowDevDirectoryDashboard.RestoreTabHeader'            = "Wiederherstellen"
    'ShowDevDirectoryDashboard.RestoreListPathLabel'        = "Datendatei:"
    'ShowDevDirectoryDashboard.RestoreDestinationLabel'     = "Zielstammverzeichnis:"
    'ShowDevDirectoryDashboard.RestoreRunButton'            = "Wiederherstellen"
    'ShowDevDirectoryDashboard.RestoreForce'                = "Ersetzen erzwingen"
    'ShowDevDirectoryDashboard.RestoreSkipExisting'         = "Vorhandene überspringen"
    'ShowDevDirectoryDashboard.RestoreShowGitOutput'        = "Git-Ausgabe anzeigen"
    'ShowDevDirectoryDashboard.RestoreWhatIf'               = "Was-wäre-wenn"
    'ShowDevDirectoryDashboard.RestoreSummaryTemplate'      = "Repositories bereit zur Wiederherstellung: {0}"
    'ShowDevDirectoryDashboard.SyncTabHeader'               = "Sync"
    'ShowDevDirectoryDashboard.SyncDirectoryLabel'          = "Arbeitsbereich:"
    'ShowDevDirectoryDashboard.SyncListPathLabel'           = "Datendatei:"
    'ShowDevDirectoryDashboard.SyncRunButton'               = "Synchronisieren"
    'ShowDevDirectoryDashboard.SyncForce'                   = "Ersetzen erzwingen"
    'ShowDevDirectoryDashboard.SyncSkipExisting'            = "Vorhandene überspringen"
    'ShowDevDirectoryDashboard.SyncShowGitOutput'           = "Git-Ausgabe anzeigen"
    'ShowDevDirectoryDashboard.SyncWhatIf'                  = "Was-wäre-wenn"
    'ShowDevDirectoryDashboard.SyncSummaryTemplate'         = "Repositories verfügbar für Synchronisierung: {0}"
    'ShowDevDirectoryDashboard.Format.JSON'                 = "JSON (empfohlen)"
    'ShowDevDirectoryDashboard.Format.CSV'                  = "CSV"
    'ShowDevDirectoryDashboard.Format.XML'                  = "XML"
    'ShowDevDirectoryDashboard.DiscoverSummaryTemplate'     = "Repositories gefunden: {0}"
    'ShowDevDirectoryDashboard.ExportSummaryTemplate'       = "Repositories bereit zum Exportieren: {0}"
    'ShowDevDirectoryDashboard.ImportSummaryTemplate'       = "Repositories importiert: {0}"
    'ShowDevDirectoryDashboard.Column.RelativePath'         = "Relativer Pfad"
    'ShowDevDirectoryDashboard.Column.RemoteName'           = "Remote-Name"
    'ShowDevDirectoryDashboard.Column.RemoteUrl'            = "Remote-URL"
    'ShowDevDirectoryDashboard.Column.IsRemoteAccessible'   = "Remote erreichbar"
    'ShowDevDirectoryDashboard.Column.UserName'             = "Benutzername"
    'ShowDevDirectoryDashboard.Column.UserEmail'            = "Benutzer-E-Mail"
    'ShowDevDirectoryDashboard.Column.StatusDate'           = "Statusdatum"
    'ShowDevDirectoryDashboard.Status.Ready'                = "Bereit."
    'ShowDevDirectoryDashboard.Status.ScanStarted'          = "Scanne {0} ..."
    'ShowDevDirectoryDashboard.Status.ScanComplete'         = "Scan abgeschlossen. Repositories gefunden: {0}"
    'ShowDevDirectoryDashboard.Status.ExportStarted'        = "Exportiere zu {0} ..."
    'ShowDevDirectoryDashboard.Status.ExportComplete'       = "Export abgeschlossen: {0}"
    'ShowDevDirectoryDashboard.Status.ImportStarted'        = "Importiere von {0} ..."
    'ShowDevDirectoryDashboard.Status.ImportComplete'       = "Import abgeschlossen. Repositories geladen: {0}"
    'ShowDevDirectoryDashboard.Status.RestoreStarted'       = "Stelle Repositories wieder her zu {0} ..."
    'ShowDevDirectoryDashboard.Status.RestoreComplete'      = "Wiederherstellung abgeschlossen zu {0}"
    'ShowDevDirectoryDashboard.Status.SyncStarted'          = "Synchronisiere {0} mit {1} ..."
    'ShowDevDirectoryDashboard.Status.SyncComplete'         = "Synchronisierung abgeschlossen. Repositories verarbeitet: {0}"
    'ShowDevDirectoryDashboard.Status.OperationFailed'      = "Vorgang fehlgeschlagen: {0}"
    'ShowDevDirectoryDashboard.Message.NoRepositories'      = "Es sind noch keine Repositories zum Verarbeiten vorhanden. Entdecken oder importieren Sie zuerst Daten."
    'ShowDevDirectoryDashboard.Message.ExportPathMissing'   = "Wählen Sie eine Ausgabedatei vor dem Exportieren."
    'ShowDevDirectoryDashboard.Message.ImportPathMissing'   = "Wählen Sie eine Datendatei zum Importieren."
    'ShowDevDirectoryDashboard.Message.RestorePathsMissing' = "Wählen Sie einen Zielpfad vor dem Wiederherstellen."
    'ShowDevDirectoryDashboard.Message.SyncPathsMissing'    = "Geben Sie sowohl Arbeitsbereich als auch Datendatei an, bevor Sie die Synchronisierung ausführen."
    'ShowDevDirectoryDashboard.Message.ExportSuccess'       = "Repository-Liste exportiert zu {0}."
    'ShowDevDirectoryDashboard.InfoTitle'                   = "DevDirManager"
    'ShowDevDirectoryDashboard.ErrorTitle'                  = "DevDirManager Fehler"
    'ShowDevDirectoryDashboard.ScanCompleted'               = "Scan abgeschlossen für '{0}' mit {1} Repositories."
    'ShowDevDirectoryDashboard.ExportCompleted'             = "Export abgeschlossen zu '{0}' im Format {1} mit {2} Repositories."
    'ShowDevDirectoryDashboard.ImportCompleted'             = "Import abgeschlossen von '{0}' mit {1} Repositories."
    'ShowDevDirectoryDashboard.RestoreCompleted'            = "Wiederherstellung abgeschlossen zu '{0}' mit {1} Repositories."
    'ShowDevDirectoryDashboard.SyncCompleted'               = "Synchronisierung abgeschlossen für Verzeichnis '{0}' und Liste '{1}' mit {2} Repositories."
    'ShowDevDirectoryDashboard.CopyLogo'                    = "Kopiere Logo von '{0}' zu '{1}'"

    # Generic / Shared
    'RepositoryList.UsingDefaultFormat'                     = "Verwende konfiguriertes Standardformat '{0}' für Datei '{1}'."
    'GetDevDirectoryStatusDate.GitFolderMissing'            = 'Kein .git-Ordner gefunden bei {0}.'
}
