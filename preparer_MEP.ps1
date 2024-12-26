try {
	#Lister les images
	$liste = dir -file -recurse "$PSScriptRoot/images";

	# Chemin du fichier CSV
	$cheminCSV = "$PSScriptRoot/tableau_trains.csv";

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

	write-host "ID maximum : $ID_maximum";
	write-host "  ";
	#Si le CSV n'existe pas, le créer.
	#Sinon, lire le CSV comme référence.
	$ajouter = [IO.File]::Exists($cheminCSV );
	$ecrire = [IO.StreamWriter]::new($cheminCSV , $ajouter, [Text.Encoding]::UFT8);

	#Ajouter l'en-tête du CV
	if(-not $ajouter) {
		$entete  = "ID;Nom;Marque et numéro;État;Description;Fichier;Chemin`r`n";
		$ecrire.Write($entete);
	}

	write-host -ForegroundColor DarkYellow "Renseigner les images sans identifiant";
	write-host "  ";

	#Pour chaque image, inscrire une ID à partir de l'ID maximum + 1
	#Ajouter une ligne dans le CSV
	foreach($image in $liste) {
		$ligne = "";
		if($image.Name -notlike "ID[0-9][0-9][0-9][0-9][0-9][0-9]*" -or -not $ajouter) {
			$ID_maximum++;
			$dossier = [IO.Path]::GetDirectoryName($image.FullName)
			$fichier = $image.Name;
			
			if($image.Name -notlike "ID[0-9][0-9][0-9][0-9][0-9][0-9]*") {
				$idAffichage = "$ID_maximum".PadLeft(6, "0");
				$idAffichage = "ID$idAffichage";
				$fichier = "$($idAffichage)_$fichier";
			} else {
				$idAffichage = $fichier.substring(0, 8);
				$fichier = "$fichier";
			}

			$nouveauNom = "$dossier/$fichier";
			[IO.File]::Move($image.FullName, $nouveauNom);
			write-host "Renommer : $nouveauNom";
			write-host " ";

			$ligne = "$idAffichage;;;;;";
			$ligne += "$fichier;";
			$ligne += "$dossier`r`n";
			$ecrire.Write($ligne);
	  }
	}

	$ecrire.Dispose();

	write-host -ForegroundColor DarkYellow "Génération de index.html";
	write-host " ";

	#Pour chaque ligne du CSV construire l'occurrence de train en HTML
	$lecteur = [IO.StreamReader]::new($cheminCSV) ;
	$occurrences_HTML = "";
	try {
		$premier = $true;
		while (($ligne = $lecteur.ReadLine()) -ne $null) {
			if($premier) { #Sauter l'en-tête du CSV
				$premier = $false;
				continue;
			}
			
			$ligne = $ligne.Split(";");
			$identifiant = $ligne[0].trim('"');
			$Nom = $ligne[1].trim('"');
			$Marque = $ligne[2].trim('"');
			$Etat = $ligne[3].trim('"');
			$Description = $ligne[4].trim('"');
			$Chemin = "./images/$($ligne[5].trim('`"'))";
			
			$idHTML = $identifiant.Replace("ID", "");
			$idHTML = $idHTML.trim("0");
			$occurrences_HTML += "
		<div class=`"conteneur-train`" id=`"$idHTML`">
			<a href=`"$chemin`" target=`"_blank`">
				<img class=`"image-train`" src=`"$chemin`">
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
		write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red ;
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
