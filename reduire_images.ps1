using namespace System.Drawing;

try {
	# Charger la librairie System.Drawing
	[Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null;

	#Lister les images
	$liste = dir -file -recurse "$PSScriptRoot/images";
	# Demander à l'utilisateur d'entrer le pourcentage de réduction
	$pourcentage = read-host "Entrez le pourcentage de réduction (ex. 50 pour 50%)"; 
	$pourcentage = [int] $pourcentage / 100;

	foreach($image in $liste) {
		# Charger l'image
		$cheminImage = $image.FullName;
		$image = [System.Drawing.Image]::FromFile($cheminImage);

		# Calculer les nouvelles dimensions
		$nouvelleLargeur = [int]($image.Width * $pourcentage);
		$nouvelleHauteur = [int]($image.Height * $pourcentage);

		# Créer une nouvelle image redimensionnée
		$nouvelleImage = [Bitmap]::new($nouvelleLargeur, $nouvelleHauteur);
		$graphique = [Graphics]::FromImage($nouvelleImage);
		$graphique.DrawImage($image, 0, 0, $nouvelleLargeur, $nouvelleHauteur);

		# Sauvegarder la nouvelle image
		$cheminNouvelleImage = "chemin\\vers\\votre\\nouvelle_image.jpg";
		$nouvelleImage.Save($cheminImage, [Imaging.ImageFormat]::Jpeg);

		# Libérer les ressources
		$image.Dispose();
		$nouvelleImage.Dispose();
		$graphique.Dispose();
	}
} catch {
	write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red ;
	write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red ;
	write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red ; 
}

read-host "Presser <Entrée> pour terminer";