#using namespace System.Drawing;

try {
	# Définir le chemin complet vers convert si nécessaire
	$cheminConvert = "/usr/bin/convert";

	# Lister les images
	$liste = Get-ChildItem -Path "$PSScriptRoot/Image à réduire" -File -Recurse;

	# Chemin vers le répertoire de sortie
	$repertoireSortie = "$PSScriptRoot/images/mini";

	# Vérifier si le répertoire de sortie existe, sinon le créer
	if (-not [IO.Directory]::Exists($repertoireSortie)) {
		[IO.Directory]::CreateDirectory($repertoireSortie) | out-null;
	}

	foreach ($image in $liste) {
		# Charger le chemin de l'image
		$cheminImage = $image.FullName;
		
		# Redimensionner l'image à une largeur de 374 pixels tout en gardant le ratio d'aspect
		$nouveauChemin = "$repertoireSortie/$($image.Name)";
		& $cheminConvert $cheminImage -resize 374x $nouveauChemin | out-null;
	}


} catch {
	write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red ;
	write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red ;
	write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red ; 
}

read-host "Presser <Entrée> pour terminer";
