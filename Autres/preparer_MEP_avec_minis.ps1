try {
	#Lister les images
	$liste = dir -File -Recurse "$PSScriptRoot/images" | where-object { $_.FullName -notmatch "/mini/" };
	$listeImages = $liste.Name;
	
	$repertoireMini = "$PSScriptRoot/images/mini";

	# Obtenir le nom du système d'exploitation
	$os = $PSVersionTable.OS

	# Vérifier si le système d'exploitation est Windows ou Ubuntu
	if ($os -match "Windows") {
		$os = "windows";
		# Charger la librairie System.Drawing
		[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null;
	} elseif ($os -match "Ubuntu") {
		$os = "ubuntu";
	} else {
		$os = "autre";
	}

	# Chemin du fichier CSV
	$cheminCSV = "$PSScriptRoot/tableau_trains.csv";
	
	#Dictionnaire des références existantes
	$lecteur = $null;
	try {
		$lecteur = [IO.File]::ReadAllText($cheminCSV, [Text.Encoding]::UTF8);
		$lecteur = $lecteur -split "`r`n";
	} catch {}
	
	write-host "Nombre : $($lecteur.count)";
	$dictionnaireImages = @{};
	$premier = $true;
	foreach($ligne in $lecteur) {
		if([string]::IsNullOrEmpty($ligne)) { continue; }
		if($premier) { #Sauter l'en-tête du CSV
			$premier = $false;
			continue;
		}		
		
		$l = $ligne.Split(";");
		$identifiant = $l[0].trim('"');
		$dictionnaireImages[$identifiant] = $ligne;
	}
	
	#Pour chaque image, vérifier s'il y a un ID pour trouver le maximum
	$ID_maximum = 0;
	
	foreach($image in $liste) {
	  $id = $image.Name;
	  $id = $id.substring(2, 6);
	  if($id -as [int]) {
		$id = [int] $id;
		if($id -gt $ID_maximum) {
		  $ID_maximum = [int] $id;
		}
	  }  
	}

	$lien_dernier_ID = "$PSScriptRoot/ressources/dernier_ID_utilise.txt";
	$dernier_id = [IO.File]::ReadAllText($lien_dernier_ID);
	$dernier_id = [int] $dernier_id;
	if($dernier_id -gt $ID_maximum) {
	  $ID_maximum = $dernier_id;
	}

	write-host "ID maximum : $ID_maximum";
	write-host "  ";
	#Générer le CSV
	$ecrire = [IO.StreamWriter]::new($cheminCSV , $false, [Text.Encoding]::UTF8);

	#Ajouter l'en-tête du CV
	$entete  = "ID;Nom;Marque et numéro;État;Description;Fichier;Chemin`r`n";
	$ecrire.Write($entete);

	write-host -ForegroundColor DarkYellow "Écrire le CSV à jour";
	write-host "  ";

	#Pour chaque image, inscrire un ID à partir de l'ID maximum + 1
	#Ajouter une ligne dans le CSV
	foreach($image in $liste) {
		$ligne = "";
		$dossier = [IO.Path]::GetDirectoryName($image.FullName)
		$fichier = $image.Name;
		
		$ligne = "";
		$nomFichier = $null;
		$nouveauNom = "";
		if($image.Name -notlike "ID[0-9][0-9][0-9][0-9][0-9][0-9]*") {
			$ID_maximum++;
			$idAffichage = "$ID_maximum".PadLeft(6, "0");
			$fichier = "$($idAffichage)_$fichier";
			$nouveauNom = "$dossier/ID$fichier";
			[IO.File]::Move($image.FullName, $nouveauNom);
			write-host "Renommer : $nouveauNom";
			write-host " ";

			$ligne = "ID$idAffichage;;;;;";
			$ligne += "ID$fichier;";
			$ligne += "$dossier`r`n";
			$nomFichier = "ID$fichier";
		} elseif ([string]::IsNullOrEmpty($dictionnaireImages["$($fichier.substring(0, 8))"])) {
			$nouveauNom = "$dossier/ID$fichier";
			$ligne = "$($fichier.substring(0, 8));;;;;";
			$ligne += "$fichier;";
			$ligne += "$dossier`r`n";
			$nomFichier = $fichier;
		} else {
			$idAffichage = $fichier.substring(0, 8);
			$ligne = $dictionnaireImages["$idAffichage"];
			$ligne += "`r`n";
			$nomFichier = $fichier;
		}
		
		$ecrire.Write($ligne);

		#Créer l'image miniature si elle n'existe pas
		if(-not [IO.File]::Exists("$repertoireMini/$nomFichier")) {
			$largeurFixe = 374;
			$nouveauChemin = "$repertoireMini/$nomFichier";
			$cheminImage = "";
			if(-not [string]::IsNullOrEmpty($nouveauNom)) {
				$cheminImage = $nouveauNom;
			} else {
				$cheminImage = $image.FullName;
			}

			switch($os) {
				"windows" {
					# Charger l'image
					$imageOrigine = [Drawing.Image]::FromFile($cheminImage);

					# Calculer les nouvelles dimensions en gardant le ratio d'aspect
					$ratio = $imageOrigine.Height / $imageOrigine.Width;
					$nouvelleHauteur = [int] ($largeurFixe * $ratio);

					# Créer une nouvelle image redimensionnée
					$nouvelleImage = [Drawing.Bitmap]::new($largeurFixe, $nouvelleHauteur);
					$graphique = [Drawing.Graphics]::FromImage($nouvelleImage);
					$graphique.DrawImage($imageOrigine, 0, 0, $largeurFixe, $nouvelleHauteur);

					# Sauvegarder la nouvelle image
					$nouvelleImage.Save($nouveauChemin, [Imaging.ImageFormat]::Jpeg);

					# Libérer les ressources
					$imageOrigine.Dispose();
					$nouvelleImage.Dispose();
					$graphique.Dispose();
				}
				
				"ubuntu" {
					$cheminConvert = "/usr/bin/convert";
					
					# Redimensionner l'image à une largeur de 374 pixels tout en gardant le ratio d'aspect
					& $cheminConvert $cheminImage -resize 374x $nouveauChemin | out-null;
				}
			}
		}
	}

	$ecrire.Dispose();

	#Mettre à jour le dernier ID utilisé
	$ecrire = [IO.StreamWriter]::new($lien_dernier_ID, $false, [Text.Encoding]::UTF8);
	$ecrire.Write($ID_maximum);
	$ecrire.Dispose();

	write-host -ForegroundColor DarkYellow "Génération de index.html";
	write-host " ";

	#Pour chaque ligne du CSV construire l'occurrence de train en HTML
	$lecteur = [IO.StreamReader]::new($cheminCSV, [Text.Encoding]::UTF8) ;
	$occurrences_HTML = "";
	try {
		$premier = $true;
		while (($ligne = $lecteur.ReadLine()) -ne $null) {
			if($premier -or [string]::IsNullOrEmpty($ligne)) { #Sauter l'en-tête du CSV ou les lignes vides
				$premier = $false;
				continue;
			}
			
			$ligne = $ligne.Split(";");
			$identifiant = $ligne[0].Replace("ID", "").trim('"');
			$Nom = $ligne[1].trim('"');
			$Marque = $ligne[2].trim('"');
			$Etat = $ligne[3].trim('"');
			$Description = $ligne[4].trim('"');
			$Chemin = $ligne[6].trim('"');
			$Chemin = $Chemin.Replace("$PSScriptRoot", "");
			$Chemin = "./$Chemin/$($ligne[5].trim('`"'))";
			$CheminMini = "./images/mini/$($ligne[5].trim('`"'))";
			
			$idHTML = $identifiant.Replace("ID", "");
			$idHTML = $idHTML.trim("0");
			$occurrences_HTML += "
		<div class=`"conteneur-train`" id=`"$idHTML`">
			<a href=`"$Chemin`" target=`"_blank`">
				<img class=`"image-train`" src=`"$CheminMini`">
			</a>
			<table>
				<tr>
					<td class=`"libelle`"><u>ID:</u></td>
					<td>$identifiant</td>
				</tr>
				<tr>
					<td class=`"libelle`"><u>Nom:</u></td>
					<td>$Nom</td>
				</tr>
				<tr>
					<td class=`"libelle`"><u>Marque et numéro:</u></td>
					<td>$Marque</td>
				</tr>
				<tr>
					<td class=`"libelle`"><u>État:</u></td>
					<td>$Etat</td>
				</tr>				
				<tr>
					<td class=`"libelle`"><u>Description:</u></td>
					<td>$Description</td>
				</tr>
			</table>
		</div>`r`n`r`n";
		}
	}

	catch {
		$PSCmdlet = $Error[0].InvocationInfo;
		write-host "Erreur sur la ligne: $($PSCmdlet.ScriptLineNumber)" -ForegroundColor Red ;
		write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red ;
		write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red ; 
	}

	finally {
		$lecteur.Close() ;
	}

	#Lire le modele.html
	#Remplacer ?occurrences_de_train dans le modèle par les occurrences constuites
	$modele = [IO.File]::ReadAllText("$PSScriptRoot/modele.html");
	$modele = $modele.Replace("?occurrences_de_train", "$occurrences_HTML");

	#Écrire le résultat dans index.html
	$ecrire = [IO.StreamWriter]::new("$PSScriptRoot/index.html" , $false, [Text.Encoding]::Unicode);
	$ecrire.Write($modele);
	$ecrire.Dispose();
	
} catch {
	write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red ;
	write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red ;
	write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red ; 
}

read-host "Presser <Entrée> pour terminer";