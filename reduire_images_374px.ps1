using namespace System.Drawing;

try {
    # Charger la librairie System.Drawing
    [Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null;

    # Lister les images
    $liste = Get-ChildItem -File -Recurse "$PSScriptRoot/Image à réduire";

    # Définir la largeur fixe
    $largeurFixe = 374;

    # Vérifier si le répertoire de sortie existe, sinon le créer
    $repertoireMini = "$PSScriptRoot/images/mini";
    if (-not [IO.Directory]::Exists($repertoireMini)) {
        [IO.Directory]::CreateDirectory($repertoireMini) | Out-Null;
    }

    foreach ($image in $liste) {
        # Charger l'image
        $cheminImage = $image.FullName;
        $imageOrigine = [Image]::FromFile($cheminImage);

        # Calculer les nouvelles dimensions en gardant le ratio d'aspect
        $ratio = $imageOrigine.Height / $imageOrigine.Width;
        $nouvelleHauteur = [int]($largeurFixe * $ratio);

        # Créer une nouvelle image redimensionnée
        $nouvelleImage = New-Object Bitmap $largeurFixe, $nouvelleHauteur;
        $graphique = [Graphics]::FromImage($nouvelleImage);
        $graphique.DrawImage($imageOrigine, 0, 0, $largeurFixe, $nouvelleHauteur);

        # Sauvegarder la nouvelle image
        $cheminNouvelleImage = "$repertoireMini/$($image.Name)";
        $nouvelleImage.Save($cheminNouvelleImage, [Imaging.ImageFormat]::Jpeg);

        # Libérer les ressources
        $imageOrigine.Dispose();
        $nouvelleImage.Dispose();
        $graphique.Dispose();
    }
} catch {
    write-host "Erreur sur la ligne: $($MyInvocation.ScriptLineNumber)" -ForegroundColor Red;
    write-host "Erreur: $($_.Exception.Message)" -ForegroundColor Red;
    write-host "Trace: $($_.Exception.StackTrace)" -ForegroundColor Red;
}

read-host "Presser <Entrée> pour terminer";