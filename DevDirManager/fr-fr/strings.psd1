# Fichier de chaînes de caractères en français pour DevDirManager
# Ces chaînes sont utilisées par Write-PSFMessage, Stop-PSFFunction et les blocs de script de validation PSFramework
@{
    # Import-DevDirectoryList
    'ImportDevDirectoryList.Start'                          = "Démarrage d'Import-DevDirectoryList à partir du chemin : '{0}', Format : '{1}'"
    'ImportDevDirectoryList.ConfigurationFormatExplicit'    = "Utilisation du format explicitement spécifié : '{0}'"
    'ImportDevDirectoryList.ConfigurationFormatDefault'     = "Utilisation du format par défaut depuis la configuration : '{0}'"
    'ImportDevDirectoryList.FileNotFound'                   = "Le fichier de liste de référentiels spécifié '{0}' n'existe pas."
    'ImportDevDirectoryList.FileNotFoundWarning'            = "Fichier d'importation introuvable : '{0}'"
    'ImportDevDirectoryList.Import'                         = "Lecture de la liste de référentiels depuis : '{0}'"
    'ImportDevDirectoryList.InferFormatFailed'              = "Impossible de déduire le format d'importation du chemin '{0}'. Spécifiez le paramètre Format."
    'ImportDevDirectoryList.FormatResolved'                 = "Format d'importation résolu : '{0}'"
    'ImportDevDirectoryList.DeserializationStart'           = "Démarrage de la désérialisation au format {0}"
    'ImportDevDirectoryList.DeserializationCSV'             = "Utilisation d'Import-Csv pour la désérialisation CSV"
    'ImportDevDirectoryList.TypeConversionCSV'              = "{0} objets importés depuis CSV, conversion de types en cours"
    'ImportDevDirectoryList.StatusDateParsed'               = "StatusDate analysé avec succès : '{0}'"
    'ImportDevDirectoryList.StatusDateParseError'           = "Impossible d'analyser StatusDate '{0}' en DateTime : {1}"
    'ImportDevDirectoryList.CompleteCSV'                    = "{0} référentiels importés avec succès depuis le fichier CSV"
    'ImportDevDirectoryList.DeserializationJSON'            = "Utilisation de ConvertFrom-Json pour la désérialisation JSON"
    'ImportDevDirectoryList.EmptyJSON'                      = "Le fichier JSON est vide ou ne contient que des espaces"
    'ImportDevDirectoryList.TypeConversionJSON'             = "{0} objets importés depuis JSON, ajout des informations de type"
    'ImportDevDirectoryList.CompleteJSON'                   = "{0} référentiels importés avec succès depuis le fichier JSON"
    'ImportDevDirectoryList.DeserializationXML'             = "Utilisation d'Import-Clixml pour la désérialisation XML"
    'ImportDevDirectoryList.TypeConversionXML'              = "{0} objets importés depuis XML, ajout des informations de type"
    'ImportDevDirectoryList.CompleteXML'                    = "{0} référentiels importés avec succès depuis le fichier XML"

    # Export-DevDirectoryList
    'ExportDevDirectoryList.Start'                          = "Démarrage d'Export-DevDirectoryList vers le chemin : '{0}', Format : '{1}'"
    'ExportDevDirectoryList.ConfigurationFormatExplicit'    = "Utilisation du format explicitement spécifié : '{0}'"
    'ExportDevDirectoryList.ConfigurationFormatDefault'     = "Utilisation du format par défaut depuis la configuration : '{0}'"
    'ExportDevDirectoryList.CollectObject'                  = "Collecte d'objet référentiel dans la liste d'exportation"
    'ExportDevDirectoryList.ProcessExport'                  = "Traitement de l'exportation de {0} objets référentiels"
    'ExportDevDirectoryList.NoRepositoryEntries'            = 'Aucune entrée de référentiel reçue pour l''exportation.'
    'ExportDevDirectoryList.InferFormatFailed'              = "Impossible de déduire le format d'exportation du chemin '{0}'. Spécifiez le paramètre Format."
    'ExportDevDirectoryList.FormatResolved'                 = "Format d'exportation résolu : '{0}'"
    'ExportDevDirectoryList.CreateOutputDirectory'          = "Création du répertoire de sortie : '{0}'"
    'ExportDevDirectoryList.ActionExport'                   = 'Exporter la liste de référentiels au format {0}'
    'ExportDevDirectoryList.ExportCanceled'                 = "Exportation annulée par l'utilisateur (WhatIf/Confirm)"
    'ExportDevDirectoryList.SerializationStart'             = "Sérialisation de {0} référentiels vers '{1}' au format {2}"
    'ExportDevDirectoryList.SerializationCSV'               = "Utilisation d'Export-Csv pour la sérialisation CSV"
    'ExportDevDirectoryList.SerializationJSON'              = "Utilisation de ConvertTo-Json avec profondeur 5 pour la sérialisation JSON"
    'ExportDevDirectoryList.SerializationXML'               = "Utilisation d'Export-Clixml pour la sérialisation XML"
    'ExportDevDirectoryList.Complete'                       = "{0} référentiels exportés avec succès vers '{1}' au format {2}"

    # Get-DevDirectory
    'GetDevDirectory.Start'                                 = "Démarrage de Get-DevDirectory avec RootPath : '{0}', SkipRemoteCheck : {1}"
    'GetDevDirectory.ConfigurationRemoteName'               = "Utilisation du nom distant '{0}' depuis la configuration"
    'GetDevDirectory.ScanStart'                             = "Analyse de l'arborescence de répertoires à partir de : '{0}'"
    'GetDevDirectory.RepositoryFound'                       = "Référentiel trouvé à : '{0}'"
    'GetDevDirectory.RemoteCheckStart'                      = "Vérification de l'accessibilité du distant : '{0}'"
    'GetDevDirectory.RemoteCheckResult'                     = "Accessibilité du distant pour '{0}' : {1}"
    'GetDevDirectory.RemoteCheckNoUrl'                      = "Aucune URL distante trouvée pour '{0}', marquage comme inaccessible"
    'GetDevDirectory.DirectoryEnumerationFailed'            = 'Répertoire {0} ignoré en raison de {1}.'
    'GetDevDirectory.ScanComplete'                          = "Analyse des référentiels terminée. {0} référentiels trouvés"

    # Restore-DevDirectory
    'RestoreDevDirectory.Start'                             = "Démarrage de Restore-DevDirectory vers la destination : '{0}', Force : {1}, SkipExisting : {2}, ShowGitOutput : {3}"
    'RestoreDevDirectory.ConfigurationGitExe'               = "Utilisation de l'exécutable git : '{0}'"
    'RestoreDevDirectory.GitExeResolved'                    = "Exécutable git résolu vers : '{0}'"
    'RestoreDevDirectory.GitExeNotFound'                    = "Exécutable git introuvable : '{0}'"
    'RestoreDevDirectory.GitExecutableMissing'              = "Impossible de localiser l'exécutable git '{0}'. Assurez-vous que Git est installé et disponible dans PATH."
    'RestoreDevDirectory.DestinationNormalized'             = "Chemin de destination normalisé : '{0}'"
    'RestoreDevDirectory.ProcessingRepositories'            = "Traitement de {0} référentiels pour la restauration"
    'RestoreDevDirectory.MissingRemoteUrl'                  = 'Référentiel ignoré avec RemoteUrl manquant : {0}.'
    'RestoreDevDirectory.MissingRelativePath'               = 'Référentiel ignoré avec RelativePath manquant pour le distant {0}.'
    'RestoreDevDirectory.UnsafeRelativePath'                = "Référentiel ignoré avec chemin relatif non sécurisé '{0}'."
    'RestoreDevDirectory.OutOfScopePath'                    = "Référentiel ignoré avec chemin hors de portée '{0}'."
    'RestoreDevDirectory.ExistingTargetVerbose'             = 'Cible de référentiel existante {0} ignorée.'
    'RestoreDevDirectory.TargetExistsWarning'               = 'Le répertoire cible {0} existe déjà. Utilisez -Force pour écraser ou -SkipExisting pour ignorer.'
    'RestoreDevDirectory.ActionClone'                       = 'Cloner le référentiel depuis {0}'
    'RestoreDevDirectory.CloningRepository'                 = "Clonage du référentiel {0}/{1} : {2} -> {3}"
    'RestoreDevDirectory.CloneFailed'                       = "git clone pour '{0}' a échoué avec le code de sortie {1}."
    'RestoreDevDirectory.ConfigFailed'                      = "Échec de la définition de git config {0} à '{1}' pour le référentiel à {2}. Code de sortie : {3}"
    'RestoreDevDirectory.InaccessibleRemoteSkipped'         = "Référentiel '{0}' ignoré avec distant inaccessible : {1}"
    'RestoreDevDirectory.Complete'                          = "Opération de restauration terminée. {0} référentiels traités"

    # Sync-DevDirectoryList
    'SyncDevDirectoryList.Start'                            = "Démarrage de Sync-DevDirectoryList avec DirectoryPath : '{0}', RepositoryListPath : '{1}', Force : {2}, SkipExisting : {3}, ShowGitOutput : {4}"
    'SyncDevDirectoryList.ConfigurationRemoteName'          = "Utilisation du nom distant '{0}' depuis la configuration"
    'SyncDevDirectoryList.DirectoryNormalized'              = "Chemin de répertoire normalisé : '{0}'"
    'SyncDevDirectoryList.SyncStart'                        = "Démarrage du processus de synchronisation"
    'SyncDevDirectoryList.ImportingFromFile'                = "Le fichier de liste de référentiels existe, importation des entrées depuis : '{0}'"
    'SyncDevDirectoryList.ActionCreateRootDirectory'        = 'Créer le répertoire racine des référentiels'
    'SyncDevDirectoryList.ActionCloneFromList'              = 'Cloner {0} référentiel(s) depuis la liste'
    'SyncDevDirectoryList.ActionCreateListDirectory'        = 'Créer le répertoire pour le fichier de liste de référentiels'
    'SyncDevDirectoryList.ActionUpdateListFile'             = 'Mettre à jour le fichier de liste de référentiels'
    'SyncDevDirectoryList.ImportFailed'                     = 'Impossible d''importer la liste de référentiels depuis {0} : {1}'
    'SyncDevDirectoryList.UnsafeFileEntry'                  = 'L''entrée de liste de référentiels avec chemin relatif non sécurisé {0} a été ignorée.'
    'SyncDevDirectoryList.UnsafeLocalEntry'                 = 'Référentiel local avec chemin relatif non sécurisé {0} ignoré.'
    'SyncDevDirectoryList.RemoteUrlMismatch'                = 'Discordance d''URL distante pour {0}. Conservation de la valeur locale {1} sur la valeur du fichier {2}.'
    'SyncDevDirectoryList.MissingRemoteUrl'                 = 'L''entrée de liste de référentiels {0} manque de RemoteUrl et ne peut pas être clonée.'
    'SyncDevDirectoryList.MissingRootDirectory'             = 'Le répertoire racine des référentiels {0} n''existe pas ; opérations de clonage ignorées.'
    'SyncDevDirectoryList.InaccessibleRemoteSkipped'        = "Référentiel '{0}' ignoré avec distant inaccessible : {1}"
    'SyncDevDirectoryList.Complete'                         = "Synchronisation terminée. Nombre final de référentiels : {0}"

    # Publish-DevDirectoryList
    'PublishDevDirectoryList.Start'                         = "Démarrage de Publish-DevDirectoryList avec ParameterSet : '{0}', Public : {1}, GistId : '{2}'"
    'PublishDevDirectoryList.AuthenticationDecrypt'         = "Déchiffrement d'AccessToken pour l'authentification API GitHub"
    'PublishDevDirectoryList.TokenEmpty'                    = 'Le jeton d''accès fourni est vide après conversion.'
    'PublishDevDirectoryList.TokenEmptyError'               = "AccessToken est vide ou null"
    'PublishDevDirectoryList.ConfigurationApiUrl'           = "Point de terminaison API configuré : '{0}'"
    'PublishDevDirectoryList.CollectPipelineObject'         = "Collecte d'objet référentiel depuis le pipeline"
    'PublishDevDirectoryList.NoPipelineData'                = 'Aucune métadonnée de référentiel n''a été reçue du pipeline.'
    'PublishDevDirectoryList.ConvertToJson'                 = "Conversion de {0} objets pipeline en JSON"
    'PublishDevDirectoryList.ReadFile'                      = "Lecture de la liste de référentiels depuis le fichier : '{0}'"
    'PublishDevDirectoryList.FormatDetected'                = "Format de fichier détecté : '{0}'"
    'PublishDevDirectoryList.ReadJsonDirect'                = "Le fichier est JSON, lecture directe"
    'PublishDevDirectoryList.ConvertFormat'                 = "Conversion de {0} en JSON"
    'PublishDevDirectoryList.EmptyContent'                  = 'Le contenu de la liste de référentiels est vide. Rien ne sera publié.'
    'PublishDevDirectoryList.SearchGist'                    = "Recherche de gist existant avec description 'GitRepositoryList'"
    'PublishDevDirectoryList.GistFound'                     = "Gist existant trouvé avec ID : '{0}'"
    'PublishDevDirectoryList.GistNotFound'                  = "Aucun gist existant trouvé, création d'un nouveau"
    'PublishDevDirectoryList.QueryGistFailed'               = 'Échec de la requête des gists existants : {0}'
    'PublishDevDirectoryList.UsingProvidedGistId'           = "Utilisation du GistId fourni : '{0}'"
    'PublishDevDirectoryList.PublishCanceled'               = "Publication annulée par l'utilisateur (WhatIf/Confirm)"
    'PublishDevDirectoryList.UpdatingGist'                  = "Mise à jour du gist existant : '{0}'"
    'PublishDevDirectoryList.CreatingGist'                  = "Création d'un nouveau gist"
    'PublishDevDirectoryList.Complete'                      = "Liste de référentiels publiée avec succès sur gist. GistId : '{0}', URL : '{1}'"
    'PublishDevDirectoryList.CleanupTokens'                 = "Nettoyage des jetons d'authentification"
    'PublishDevDirectoryList.ActionPublish'                 = 'Publier la liste de référentiels DevDirManager sur GitHub Gist'
    'PublishDevDirectoryList.TargetLabelCreate'             = 'Créer le gist GitRepositoryList'
    'PublishDevDirectoryList.TargetLabelUpdate'             = 'Mettre à jour le gist {0}'

    # Fonctions internes - Get-DevDirectoryRemoteUrl
    'GetDevDirectoryRemoteUrl.Start'                        = "Extraction de l'URL distante pour '{0}' depuis le référentiel : '{1}'"
    'GetDevDirectoryRemoteUrl.ConfigPath'                   = "Chemin de config git : '{0}'"
    'GetDevDirectoryRemoteUrl.ConfigMissing'                = 'Aucun fichier .git\\config trouvé à {0}.'
    'GetDevDirectoryRemoteUrl.ConfigNotFound'               = "Fichier de config git introuvable, retour de null"
    'GetDevDirectoryRemoteUrl.ReadingConfig'                = "Lecture du fichier de config git"
    'GetDevDirectoryRemoteUrl.SearchingSection'             = "Recherche du motif de section : '{0}'"
    'GetDevDirectoryRemoteUrl.SectionFound'                 = "Section [remote '{0}'] trouvée dans la config git"
    'GetDevDirectoryRemoteUrl.RemoteUrlFound'               = "URL distante pour '{0}' : '{1}'"
    'GetDevDirectoryRemoteUrl.RemoteNotFound'               = "Distant '{0}' introuvable ou sans URL configurée"

    # Fonctions internes - Get-DevDirectoryUserInfo
    'GetDevDirectoryUserInfo.Start'                         = "Extraction des informations utilisateur depuis le référentiel : '{0}'"
    'GetDevDirectoryUserInfo.ConfigPath'                    = "Chemin de config git : '{0}'"
    'GetDevDirectoryUserInfo.ConfigMissing'                 = 'Aucun fichier .git\\config trouvé à {0}.'
    'GetDevDirectoryUserInfo.ConfigNotFound'                = "Fichier de config git introuvable, retour de valeurs nulles"
    'GetDevDirectoryUserInfo.ReadingConfig'                 = "Lecture du fichier de config git"
    'GetDevDirectoryUserInfo.SectionFound'                  = "Section [user] trouvée dans la config git"
    'GetDevDirectoryUserInfo.UserNameFound'                 = "user.name trouvé : '{0}'"
    'GetDevDirectoryUserInfo.UserEmailFound'                = "user.email trouvé : '{0}'"
    'GetDevDirectoryUserInfo.Result'                        = "Informations utilisateur extraites - UserName : '{0}', UserEmail : '{1}'"

    # Fonctions internes - Test-DevDirectoryRemoteAccessible
    'TestDevDirectoryRemoteAccessible.EmptyUrl'             = "L'URL distante est vide, marquage comme inaccessible"
    'TestDevDirectoryRemoteAccessible.CheckingRemote'       = "Vérification de l'accessibilité du distant : {0}"
    'TestDevDirectoryRemoteAccessible.Timeout'              = "Délai d'attente de la vérification du distant dépassé après {0} secondes pour : {1}"
    'TestDevDirectoryRemoteAccessible.Accessible'           = "Le distant est accessible : {0}"
    'TestDevDirectoryRemoteAccessible.NotAccessible'        = "Le distant n'est pas accessible (code de sortie {0}) : {1}"
    'TestDevDirectoryRemoteAccessible.Error'                = "Erreur lors de la vérification de l'accessibilité du distant pour {0} : {1}"

    # Fonctions internes - ConvertTo-NormalizedRelativePath
    'ConvertToNormalizedRelativePath.Start'                 = "Normalisation du chemin relatif : '{0}'"
    'ConvertToNormalizedRelativePath.EmptyPath'             = "Le chemin est vide, espace ou '.', retour de '.'"
    'ConvertToNormalizedRelativePath.AfterTrim'             = "Après trim : '{0}'"
    'ConvertToNormalizedRelativePath.AfterCleanup'          = "Après nettoyage des slashs : '{0}'"
    'ConvertToNormalizedRelativePath.BecameEmpty'           = "Le chemin est devenu vide après normalisation, retour de '.'"
    'ConvertToNormalizedRelativePath.Result'                = "Chemin normalisé : '{0}' -> '{1}'"

    # Fonctions internes - Add-RepositoryTypeName
    'AddRepositoryTypeName.Start'                           = "Ajout du nom de type DevDirManager.Repository à l'objet"
    'AddRepositoryTypeName.Result'                          = "Nom de type ajouté à l'objet"

    # Génériques / Partagés
    'RepositoryList.UsingDefaultFormat'                     = "Utilisation du format par défaut configuré '{0}' pour le fichier '{1}'."
    'GetDevDirectoryStatusDate.GitFolderMissing'            = 'Aucun dossier .git trouvé à {0}.'
}
