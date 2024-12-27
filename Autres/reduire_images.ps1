try {
	# Charger la librairie System.Drawing
	[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null;

	#Lister les images
	$liste = dir -file -recurse "C:\Exploi_TEMP\APPLI\trains-de-collection\Image à réduire";
	#$liste = dir -file -recurse "$PSScriptRoot/Image à réduire";
	# Demander à l'utilisateur d'entrer le pourcentage de réduction
	$pourcentage = read-host "Entrez le pourcentage de réduction (ex. 50 pour 50%)"; 
	$pourcentage = [int] $pourcentage / 100;

	foreach($image in $liste) {
		# Charger l'image
		$cheminImage = $image.FullName;
		$nomImage = $image.Name;
		$image = [Drawing.Image]::FromFile($cheminImage);

		# Calculer les nouvelles dimensions
		$nouvelleLargeur = [int]($image.Width * $pourcentage);
		$nouvelleHauteur = [int]($image.Height * $pourcentage);

		# Créer une nouvelle image redimensionnée
		$nouvelleImage = [Drawing.Bitmap]::new($nouvelleLargeur, $nouvelleHauteur);
		$graphique = [Drawing.Graphics]::FromImage($nouvelleImage);
		$graphique.DrawImage($image, 0, 0, $nouvelleLargeur, $nouvelleHauteur);

		# Sauvegarder la nouvelle image
		$image.Dispose();
		if([IO.File]::Exists($cheminImage)) {
			[IO.File]::Delete($cheminImage);
		}		

		$nouvelleImage.Save($cheminImage, [Drawing.Imaging.ImageFormat]::Jpeg);

		# Libérer les ressources
		$nouvelleImage.Dispose();
		$graphique.Dispose();
	}
} catch {
	write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red ;
	write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red ;
	write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red ; 
}

read-host "Presser <Entrée> pour terminer";