#Lister les images
$liste = dir -file -recurse "$PSScriptRoot/images";

#Pour chaque image, vérifier s'il y a un ID pour trouver le maximum
$ID_maximum = 0;
foreach($image in $liste) {
  $id = $image.Name;
  $id = $id.substring(3, 6);
  if($id -as [int]) {
    if($id -gt $ID_maximum) {
      $ID_maximum = $id;
    }
  }  
}

write-host "ID maximum : $ID_maximum";
write-host "  ";

#Si le CSV n'existe pas, le créer.
#Sinon, lire le CSV comme référence.
$ajouter = [IO.File]::Exists("$PSScriptRoot\tableau_trains.csv");
$ecrire = [IO.StreamWriter]::new("$PSScriptRoot/tableau_trains.csv", $ajouter, [Text.Encoding]::Unicode);

#Pour chaque image, inscrire une ID à partir de l'ID maximum + 1
#Ajouter une ligne dans le CSV
foreach($image in $liste) {
  if($image.Name -notlike "ID[0-9][0-9][0-9][0-9][0-9][0-9]*") {
    $ID_maximum++;
    $dossier = [IO.Path]::GetDirectory($image.FullName);
    $fichier = $image.Name;
    $nouveauNom = "$dossier\ID$ID_maximum_$fichier";
    [IO.File]::Move($image.FullName, $nouveauNom);
  }
}

#Lire le modele.html

#Pour chaque ligne du CSV construire l'occurrence de train en HTML

#Remplacer ?occurrences_de_train dans le modèle par les occurrences constuites

#Écrire le résultat dans index.html

read-host "Presser <Entrée> pour teminer"
