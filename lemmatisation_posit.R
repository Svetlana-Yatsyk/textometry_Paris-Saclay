# Installation des bibliothèques nécessaires pour le traitement de texte et l'analyse de données
install.packages("udpipe")
install.packages("tidyverse")
install.packages("DT")

# Chargement des bibliothèques installées
library(udpipe)    # pour la lemmatisation et le traitement linguistique
library(tidyverse) # pour la manipulation des données
library(stringr)   # pour les opérations sur les chaînes de caractères
library(readr)     # pour lire les données
library(DT)        # pour afficher des tables interactives


# Ici, nous lisons le contenu du fichier texte spécifié
# N'oubliez pas d'attribuer un nom unique à chaque variable et 
# de remplacer le chemin vers le texte source
chroniques <- readLines(con = "Delarue/chroniques-du-pays-des-meres_240228_081757_traité.txt")
# Si vous voyez une erreur "incomplete final line", ce n'est pas grave, vous pouvez l'ignorer

# Remplacement des apostrophes courbes par des apostrophes droites pour éviter des erreurs de traitement de texte
chroniques <- gsub("’", "'", chroniques)

# Téléchargement du modèle udpipe pour le français
udpipe_download_model(language = "french-gsd")
# Définissez le chemin vers le modèle téléchargé
fr_model_path <- "/cloud/project/french-gsd-ud-2.5-191206.udpipe"
# Chargement du modèle français
fr_model <- udpipe_load_model(fr_model_path)

# Téléchargement du modèle udpipe pour l'anglais
# udpipe_download_model(language = "english-ewt")
# Définissez le chemin vers ce modèle anglais
# en_model_path <- "/cloud/project/english-ewt-ud-2.5-191206.udpipe"
# Chargement du modèle anglais
# en_model <- udpipe_load_model(en_model_path)

# Annotation du premier document avec le modèle français, cela peut prendre 5-7 minutes
chroniques_ann <- udpipe_annotate(fr_model, chroniques)

# Pour annoter un texte en anglais, remplacez "fr_model" par "en_model"

# Transformation des résultats d'annotation en "tibble" pour une manipulation plus facile avec dplyr
chroniques_df <- as_tibble(chroniques_ann) %>% 
  select(-sentence, -paragraph_id)

# Affichage d'une partie du dataframe pour s'assurer que la lemmatisation a été effectuée avec succès
chroniques_df %>% 
  filter(doc_id == "doc100") %>% # vous pouvez changer le numéro de doc_id
  select(-sentence_id, -head_token_id, -deps, -dep_rel, -misc) %>% 
  DT::datatable()

# Exemple: extraction des noms propres -----
# Extraction des noms propres du dataframe
noms_propres <- chroniques_df %>% 
  filter(upos == "PROPN") 

# Affichage des noms propres
noms_propres[,2:6] # visualisation que des colonnes 2 à 6

# Comptage du nombre d'occurrences de chaque lemme unique dans les noms propres
lemma_counts <- noms_propres %>%
  count(lemma, sort = TRUE)  # sort=TRUE trie les résultats par ordre décroissant


# Exemple: extraction des verbes au temps de l'imparfait -----
# Filtrage des verbes au temps de l'imparfait
verbes_impf <- chroniques_df %>%  # filtrage pour ne sélectionner que les verbes à l'imparfait
  filter(str_detect(feats, "Tense=Imp")) # filtrage pour ne sélectionner que les verbes à l'imparfait

# Comptage du nombre d'occurrences des lemmes des verbes à l'imparfait
lemma_counts_impf <- verbes_impf %>%
  count(lemma, sort = TRUE) 

# Exemple: extraction des articles définis féminins -----
# Filtrage des articles définis féminins
chroniques_df %>%  # filtrage pour sélectionner uniquement les articles définis de genre féminin
  filter(str_detect(feats, "Gender=Fem") & str_detect(feats, "PronType=Art"))

# Exportation des données -----
# Extraction du contenu de la colonne 'lemma' du dataframe 'chroniques_df'
lemmas <- chroniques_df$lemma
# On supprime des NA
lemmas <- na.omit(chroniques_df$lemma)

# Sauvegarde du contenu dans un fichier texte
writeLines(lemmas, "lemmas.txt")