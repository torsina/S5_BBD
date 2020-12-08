set datestyle to 'european';

DROP TABLE IF EXISTS imported_data;

CREATE TABLE imported_data (
	cote text,
	type text,
	datatype text,
	dates text,
	titre text,
	sous_titre text,
	auteur text,
	destinataire text,
	sujet text,
	description text,
	notes text,
	resume text,
	editeur text,
	localisation text,
	droits text,
	ayants_droit text,
	format text,
	langue text,
	etat_genetique text,
	relations_genetiques text,
	autres_ressources_relation text,
	nature_document text,
	support text,
	etat_general text,
	publication text,
	representation text,
	contexte_geographique text,
	lieu_expedition text,
	type_publication text,
	titre_publication text,
	lieu_publication text,
	numero_publication text,
	periodicite text,
	directeur_publication text,
	auteur_analyse text,
	date_analyse text,
	auteur_description text,
	date_creation_notice text,
	auteur_revision text,
	date_revision_notice text,
	auteur_transcription text,
	__dummy text
);

DROP TABLE IF EXISTS imported_en;

CREATE TABLE imported_en (
	cote text,
	type text,
	datatype text,
	dates text,
	titre text,
	sous_titre text,
	auteur text,
	destinataire text,
	sujet text,
	description text,
	notes text,
	resume text,
	editeur text,
	localisation text,
	droits text,
	ayants_droit text,
	format text,
	langue text,
	etat_genetique text,
	relations_genetiques text,
	autres_ressources_relation text,
	nature_document text,
	support text,
	etat_general text,
	publication text,
	representation text,
	contexte_geographique text,
	lieu_expedition text,
	type_publication text,
	titre_publication text,
	lieu_publication text,
	numero_publication text,
	periodicite text,
	directeur_publication text,
	auteur_analyse text,
	date_analyse text,
	auteur_description text,
	date_creation_notice text,
	auteur_revision text,
	date_revision_notice text,
	auteur_transcription text
);
-- Importation du CSV. Pourquoi en 2020, ce logiciel n'accepte pas les chemins relatifs ????
COPY imported_data
FROM 'E:\Esp-fotos.csv'--'D:\Boulot\L3\BASE_DE_DONNEES\PROJET\Esp-fotos.csv'
DELIMITER ';'
CSV HEADER;

COPY imported_en
FROM 'E:\Ang-fotos.csv'--'D:\Boulot\L3\BASE_DE_DONNEES\PROJET\Ang-fotos.csv'
DELIMITER ';'
CSV HEADER;


------------------------------------------------ FONCTIONS ------------------------------------------------
CREATE OR REPLACE FUNCTION parse_format(t text)
RETURNS text[] AS $$
DECLARE
	-- 9 valeurs
	parsed text[];
BEGIN
	IF t IS NULL
	THEN
		RETURN NULL;
	END IF;
	-- Tous les caractères "blancs" sont remplacés par des espaces, on enlève ceux des extrémités
	t := LOWER(TRIM(blank_to_space(t)));
	parsed := regexp_matches(t, '^(((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*((\d{1,3}([\.\,]\d{1,2})?)[[:blank:]]*([kmg]o))?)?([[:blank:]]*\[.*\])?$');
	IF parsed IS NULL -- Si le 1er parsing n'a pas marché
	THEN
		RETURN NULL;
	ELSIF array_length(parsed, 1) != 9 -- Si le parsing a partiellement match. Le 1 représente la dimension (ici 1ère dimension).
	THEN
		RETURN NULL;
	ELSE
		RETURN parsed;
	END IF;
END;
$$ LANGUAGE plpgsql;
				
CREATE OR REPLACE FUNCTION cote_to_id(cote text)
RETURNS int AS $$
BEGIN
	RETURN CAST((regexp_split_to_array(TRIM(cote), 'MX-F-'))[2] AS int);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION parse_editeur()
RETURNS VOID AS $$
DECLARE
	trimmed_text CURSOR FOR SELECT DISTINCT((regexp_split_to_array(editeur, 'Responsable del archivo\s*:{0,1}\s*'))[2]) FROM imported_data;
	editeur_line RECORD;
BEGIN
	OPEN trimmed_text;
	LOOP
	FETCH trimmed_text INTO editeur_line;
		IF NOT FOUND THEN EXIT; END IF;
		
		RAISE NOTICE '%', editeur_line;
	END LOOP;
	CLOSE trimmed_text;
END;
$$ LANGUAGE plpgsql;

/*
Supprime les caractères blancs du début et de la fin d'une chaîne de caractères.

Caractères supprimés :
0xC2
0xAO
0x20 (espace)
0x0A
0xE2
0x2006
0x0D

Ces caractères ont été détectés dans le fichier.
*/
CREATE OR REPLACE FUNCTION trim_blank(t text)
RETURNS text AS $$
DECLARE
	t_returned text;
BEGIN
	-- Remplacement en début de chaîne de caractères
	t_returned := regexp_replace(t, '^[\xC2\xA0\x20\x0A\xE2\x2006\x0D]+', '');
	-- Remplacement en fin de chaîne de caractères
	t_returned := regexp_replace(t_returned, '[\xC2\xA0\x20\x0A\xE2\x2006\x0D]+$', '');
	IF char_length(t_returned)=0
	THEN
		RETURN NULL;
	ELSE
		RETURN t_returned;
	END IF;
END;
$$ LANGUAGE plpgsql;

/*
Remplace les caractères blancs d'une chaîne de caractères part un espace.

Caractères supprimés :
0xC2
0xAO
0x20 (espace)
0x0A
0xE2
0x2006
0x0D

Caractère de remplacement :
0x20 (espace)

Ces caractères ont été détectés dans le fichier.
*/
CREATE OR REPLACE FUNCTION blank_to_space(t text)
RETURNS text AS $$
BEGIN
	RETURN regexp_replace(t, E'[\\xC2\\xA0\\x20\\x0A\\xE2\\x2006\\x0D]+', ' ', 'g');
END;
$$ LANGUAGE plpgsql;


/*CREATE OR REPLACE FUNCTION parse_format(format text, dt text)
RETURNS text[] AS $$
DECLARE
	output text[]
BEGIN
	regexp_split_to_array(editeur, 'Responsable del archivo\s*:{0,1}\s*'))[2])
END;
$$ LANGUAGE plpgsql;*/				       


------------------------------------------------ NETTOYAGE DE LA TABLE ------------------------------------------------
UPDATE imported_data SET __dummy=blank_to_space(__dummy);

------------------------------------------------COTE------------------------------------------------

-- On retire les caractères en trop avant et après la cote.
UPDATE imported_data SET cote=TRIM(cote);
UPDATE imported_en SET cote=TRIM(cote);

-- Test, on vérifie que toutes les cotes sont uniques et qu'elles vérifient bien le bon format.
-- SELECT COUNT(DISTINCT cote)=1122 FROM imported_data WHERE cote ~ '\w{1,3}-\w{1,3}-\w{1,3}';

------------------------------------------------TYPE------------------------------------------------

-- On retire les caractères en trop avant et après le type.
UPDATE imported_data SET type=TRIM(blank_to_space(type));
UPDATE imported_en SET type=TRIM(blank_to_space(type));
/*
Pour les données en espagnol :

On sait, par analyse, que tous les documents commençant par MX-F- sont du type "Fotos".
On peut même partir du principe que
MX = Margarita Xirgu
F = Fotos

Ici, on évite les incohérences/erreurs en forçant Fotos.
*/
UPDATE imported_data SET type='Fotos' WHERE cote LIKE 'MX-F-%';


------------------------------------------------DATATYPE------------------------------------------------

/*
On retire les caractères en trop avant et après le datatype.
On passe datatype en minsucule pour uniformiser la casse, qui était différente.
*/
UPDATE imported_data SET datatype=LOWER(TRIM(blank_to_space(datatype)));
UPDATE imported_en SET datatype=LOWER(TRIM(blank_to_space(datatype)));

------------------------------------------------DATES------------------------------------------------
/*
Pour les données en espagnol :

On retire les caractères en trop avant et après la date.
Toutes les dates inconnues sont passées à "NULL".
Correction des erreurs pour certaines dates.
Certains enregistrements avaient du texte invalide dans cette colonne.
Ces textes sont des informations redondantes (déjà dans colonne notes).
Décalage de la colonne titre pour "MX-F-20" corrigé.
*/
UPDATE imported_data SET dates=TRIM(blank_to_space(dates));
UPDATE imported_data SET dates=NULL WHERE LOWER(dates)='desconocido' or LOWER(dates)='indeterminado' or LOWER(dates)='gunther gerzso' or LOWER(dates)='victorio macho';
-- Corrections individuelles
UPDATE imported_data SET dates='1906-1920' WHERE cote='MX-F-20';
UPDATE imported_data SET dates='1950-1970' WHERE cote='MX-F-132';
UPDATE imported_data SET dates='1996' WHERE cote='MX-F-33';
UPDATE imported_data SET dates='1980-2000' WHERE cote='MX-F-1042';
UPDATE imported_data SET dates='1910-1940' WHERE cote='MX-F-1063';
UPDATE imported_data SET dates='1910-1925' WHERE cote='MX-F-30';

UPDATE imported_data SET dates='1992-2020' WHERE cote='MX-F-1058'; -- '19920-2020' -> '1992-2020'
UPDATE imported_data SET dates=regexp_replace(dates, '\.$', ''); -- Certains enregistrements ont une date qui finit par ".". On le supprime.

/*
Pour les données en anglais :

Ce sont des doublons (parfois erronnés) de la colonne date des données espagnoles.
*/
UPDATE imported_en SET dates=NULL;

-- Test, vérifie que tous les enregistrements sont au bon format.
SELECT COUNT(*)=0 FROM imported_data WHERE dates !~ '^\d{4}-\d{2}-\d{2}$' AND dates !~ '^\d{4}$' AND dates !~ '^\d{4}-\d{4}$';


------------------------------------------------TITRE------------------------------------------------
/*
Titre pour "MX-F-20" actualisé (NULL -> 'Magarita Xirgu').
On retire les caractères en trop avant et après le titre.
*/
UPDATE imported_data SET titre='Magarita Xirgu' WHERE cote='MX-F-20';
UPDATE imported_data SET titre=TRIM(blank_to_space(titre));
-- Faute : Mragarrita -> Margarita
UPDATE imported_data SET titre='Caricatura Margarita Xirgu' WHERE titre='Caricatura Mragarrita Xirgu';

UPDATE imported_en SET titre=TRIM(blank_to_space(titre));
-- Problème : d au lieu de t dans les données. S majuscule/minuscule à street.
UPDATE imported_en SET titre='Margarita Xirgu Badalona Street' WHERE LOWER(titre)='margarida xirgu de badalona street';
-- Plein de fautes, espace manquant
UPDATE imported_en SET titre='Drawing from a representation' WHERE titre='Draw from a represatation' OR titre='Draw froma represatation';
-- On remplace acting par performing
UPDATE imported_en SET titre=regexp_replace(LOWER(titre), 'acting', 'performing');
-- On remplace mragarita par Margarita
UPDATE imported_en SET titre=regexp_replace(LOWER(titre), 'mragarita', 'Margarita');
UPDATE imported_en SET titre='Brochures and documents' WHERE titre='brochures and document' OR titre='folletos y documentos';
UPDATE imported_en SET titre='sculpture' WHERE titre='escultura';
-- Un texte en espagnol s'est retrouvé dans les titres anglais
UPDATE imported_en SET titre='"only a theater actress" estela medina. national theatre of catalonia' WHERE titre='"solo una actriz de teatro" estela medina. teatre nacional de cataluña';
-- Le titre anglais carmen est le même que le titre espagnol
DELETE FROM imported_en WHERE titre='carmen';
-- Le titre anglais calle xirgu est le même que le titre espagnol
DELETE FROM imported_en WHERE titre='calle xirgu';
------------------------------------------------SOUS-TITRE------------------------------------------------

-- On retire les caractères en trop avant et après le sous-titre.
UPDATE imported_data SET sous_titre=TRIM(blank_to_space(sous_titre));
-- "MX-F-556" a un sous-titre vide mais non NULL.
UPDATE imported_data SET sous_titre=NULL WHERE char_length(sous_titre)=0;

-- Test, on vérifie bien que seuls un enregistrement a un sous-titre.
SELECT COUNT(sous_titre)=1 FROM imported_data;

------------------------------------------------AUTEUR------------------------------------------------

/*
Pour les données en espagnol :

On retire les caractères en trop avant et après l'auteur.
On passe à "NULL" tous les auteurs inconnus
*/
UPDATE imported_data SET auteur=TRIM(blank_to_space(auteur));
-- Un des auteurs a des caractères blancs au début (codes ASCII 0xC2, 0xAO et 0x20), que TRIM n'arrive pas à enlever.
UPDATE imported_data SET auteur=trim_blank(auteur);
-- On fait une comparaison avec le texte en minuscule pour ignorer la casse
UPDATE imported_data SET auteur=NULL WHERE LOWER(auteur)='indeterminado';
-- Correction manuelle de l'enregistrement "MX-F-438"
UPDATE imported_data SET auteur='Antonio Bueno' WHERE auteur='Antoinio Bueno';
-- Nom imcomplet, "MX-F-314"
UPDATE imported_data SET auteur='Amparo Climent Corbín' WHERE auteur LIKE 'Amparo Climent%';
-- Problème de casse
UPDATE imported_data SET auteur='Frederico Garcia Lorca' WHERE LOWER(auteur)='frederico garcia lorca';
-- Certains enregistrements ont un auteur qui finit par ".". On le supprime.
UPDATE imported_data SET auteur=regexp_replace(auteur, '\.$', '');
UPDATE imported_data SET auteur='Revista Mundo Nuevo' WHERE LOWER(auteur)='nuevo mundo' OR LOWER(auteur)='nuevo mundo revista';

/*
Pour les données en anglais :
*/
UPDATE imported_en SET auteur=TRIM(blank_to_space(auteur));
UPDATE imported_en SET auteur=NULL WHERE LOWER(auteur)='undetermined';
-- Il manque une partie du nom de famille
UPDATE imported_en SET auteur='Amparo Climent Corbín.' WHERE auteur='Amparo Climent.';
-- Un nom de famille a été traduit et un autre contient une faute
UPDATE imported_en SET auteur='Antonio Bueno' WHERE auteur='Antonio Good' OR auteur='Antoinio Bueno';
-- On corrige la casse
UPDATE imported_en SET auteur='Frederico Garcia Lorca' WHERE LOWER(auteur)='frederico garcia lorca';
-- On corrige la casse et on traduit revista en magazine
UPDATE imported_en SET auteur='Revista Mundo magazine' WHERE LOWER(auteur) LIKE 'nuevo mundo%';
-- On supprime les points à la fin
UPDATE imported_en SET auteur=regexp_replace(auteur, '\.$', '');
-- On supprime tous les enregistrements qui sont similaires à ceux des données espagnoles
UPDATE imported_en B SET auteur=NULL WHERE B.auteur=(SELECT A.auteur FROM imported_data A WHERE B.cote=A.cote);

------------------------------------------------DESTINATAIRE------------------------------------------------

-- Il n'y a pas de destinataires

------------------------------------------------SUJET------------------------------------------------

/*
On retire les caractères en trop avant et après le sujet.
Correction d'une erreur pour "MX-F-185"
*/
UPDATE imported_data SET sujet=TRIM(blank_to_space(sujet));
-- Un des sujets a des caractères blancs au début (codes ASCII 0xC2, 0xAO et 0x20), que TRIM n'arrive pas à enlever.
UPDATE imported_data SET sujet=regexp_replace(sujet, '^[\xC2\xA0\x20]*', '');
UPDATE imported_data SET sujet='Margarita xirgu' WHERE cote='MX-F-185';
-- Tout ce qui est indeterminé devient NULL
UPDATE imported_data SET sujet=NULL WHERE LOWER(sujet)='indeterminado' OR sujet='Indeterminadp';
UPDATE imported_data SET sujet='Cartel exposicion sobre Margarita Xirgu' WHERE sujet='cartel Margarita Xirgu';
UPDATE imported_data SET sujet='Figurina' WHERE sujet='Figurines';
UPDATE imported_data SET sujet='Foto de Margarita Xirgu' WHERE sujet='foto de Margarita xirgu' OR sujet='Foto de Margarita xirgu' 
OR sujet='Foto de Margarita Xirgu' OR sujet='Foto de Margarita Xiru' OR sujet='foto deMargarita Xirgu' OR sujet='Foto Margarita Xirgu'
OR sujet='Fotoe  de Margarita Xirgu';
UPDATE imported_data SET sujet='Foto de Miguel Xirgu' WHERE sujet='foto de Miguel Xirgu' OR sujet='Foto de Miguel xirgu' OR sujet='Foto de Miquel Xirgu' OR sujet='Miguel Xirgu';
UPDATE imported_data SET sujet='Homenaje a Margarita Xirgu' WHERE sujet='Homenaje a Margarita Xirgu' 
OR sujet='homenaje a Margarita Xirgu' OR sujet='Foto de Miquel Xirgu';
UPDATE imported_data SET sujet='Margarita Xirgu' WHERE sujet='Magararita xirgu' OR sujet='Margarita  Xirgu' OR sujet='Margarita Xiirgu'
OR sujet='Margarita xirgu' OR sujet='Magararita xirgu';
UPDATE imported_data SET sujet='Margarita Xirgu Actuando' WHERE sujet='Margarita Xirgu actuando';
UPDATE imported_data SET sujet='Margarita Xirgu de Elektra' WHERE sujet='Margarita Xirgu Elektra';
UPDATE imported_data SET sujet='Medea Cartel' WHERE sujet='Medea';
UPDATE imported_data SET sujet='Teatro Solis' WHERE sujet='Teatro Solís';
					     
					     
------------------------------------------------DESCRIPTION------------------------------------------------


-- Caractères blancs au début (codes ASCII 0xC2, 0xAO, 0x20 et 0x0A), que TRIM n'arrive pas à enlever.
UPDATE imported_data SET description=trim_blank(blank_to_space(description));
-- On retire les caractères en trop avant et après la description.
UPDATE imported_data SET description=TRIM(description);
-- Maintenant qu'on a supprimé des caractères blancs, on met à NULL les descriptions vides;
UPDATE imported_data SET description=NULL WHERE char_length(description)=0;
-- Certains descriptions commencent par des tirets (suivis de caractères blancs), on les supprime
UPDATE imported_data SET description=regexp_replace(description, '^-[[:blank:]]*', '');

-- TODO : remove
-- SELECT description, COUNT(auteur_description) FROM imported_data GROUP BY description HAVING COUNT(DISTINCT auteur_description) != 1;
-- SELECT * FROM imported_data WHERE description='Foto de Margarita Xirgu sacada en el "peristilo" del teatro romano de Mérida, caracterizada de Elektra';

------------------------------------------------NOTES------------------------------------------------

/*
On retire les caractères en trop avant et après les notes.
*/
UPDATE imported_data SET notes=TRIM(blank_to_space(notes));

------------------------------------------------RESUME------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET resume=TRIM(blank_to_space(resume));

-- Aucune donnée

------------------------------------------------EDITEUR------------------------------------------------

/*
On retire les caractères en trop avant et après l'éditeur.
Correction des erreurs pour certains éditeurs.
*/
UPDATE imported_data SET editeur=REPLACE(editeur, ':', '');
UPDATE imported_data SET editeur=REPLACE(editeur, '|', '');
UPDATE imported_data SET editeur=REPLACE(editeur, ',', '');
UPDATE imported_data SET editeur=REPLACE(editeur, '  ', '');
UPDATE imported_data SET editeur=REPLACE(editeur, 'fonfo', 'fondo');
UPDATE imported_data SET editeur=REPLACE(editeur, 'espectateur', 'spectateur');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Jose', 'José');
UPDATE imported_data SET editeur=REPLACE(editeur, '. ', '.');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela) Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela)Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo Indeterminadospectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo IndeterminadoEditor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo  Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=TRIM(blank_to_space(editeur));

------------------------------------------------LOCALISATION------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
On passe les localisations inconnues à "NULL".
Correction des erreurs pour certaines localisations.
*/
UPDATE imported_data SET localisation=TRIM(blank_to_space(localisation));
UPDATE imported_data SET localisation=NULL WHERE LOWER(localisation)='desconocido' OR LOWER(localisation)='indeterminado';
UPDATE imported_data SET localisation='Punta Ballena' WHERE localisation=' Punta Ballena (Maldonado) Uruguay' OR localisation='Punta Ballena Uruguay';
UPDATE imported_data SET localisation='Teatro Solís de Montevideo' WHERE localisation='Teatro Solís, Montevideo (Uruguay)';
-- Suppression du point à la fin du texte
UPDATE imported_data SET localisation='EMAD: Escuela Municipal de Arte Dramático de Montevideo' WHERE localisation='EMAD: Escuela Municipal de Arte Dramático de Montevideo.';
UPDATE imported_data SET localisation='Madrid' WHERE localisation='Madrid' OR localisation='Madrid España';
UPDATE imported_data SET localisation='Mérida' WHERE localisation='Merida' OR localisation='Mérida' OR localisation='Merida España' OR localisation='Meridaa';
UPDATE imported_data SET localisation=regexp_replace(localisation, '[[:blank:]]+España$', '');
-- "MX-F-449" a une localisation qui est erronnée (c'est la description, dupliquée).
UPDATE imported_data SET localisation=NULL WHERE localisation='figura de cera de Margarita Xirgu';
UPDATE imported_data SET localisation='Teatro Solís de Montevideo' WHERE contexte_geographique='Teatro Solís de Montevideo' and localisation=null;
UPDATE imported_data SET localisation='Granada' WHERE contexte_geographique='Granada España' and localisation=null;
UPDATE imported_data SET localisation='Sevilla' WHERE contexte_geographique='Sevilla' and localisation=null;
UPDATE imported_data SET localisation='Molins de Rei' WHERE contexte_geographique='Molins de Rei' and localisation=null;
UPDATE imported_data SET localisation='Punta del Este' WHERE contexte_geographique='Punta del Este' and localisation=null;
UPDATE imported_data SET localisation='intendencia Maldonado' WHERE contexte_geographique='intendencia Maldonado' and localisation=null;
UPDATE imported_data SET localisation='Punta Ballena' WHERE contexte_geographique='Punta ballena Uruguay' and localisation=null;
UPDATE imported_data SET localisation='Plaza Margarida Xirgu Barcelona' WHERE contexte_geographique='Plaza Margarida Xirgu Barcelona' and localisation=null;
UPDATE imported_data SET localisation='Colección de escenografía del Instituto del Teatro de la Diputación de Barcelona.' WHERE contexte_geographique='Colección de escenografía del Instituto del Teatro de la Diputación de Barcelona.' and localisation=null;
UPDATE imported_data SET localisation='Buenos Aires' WHERE contexte_geographique='Buenos Aires Argentina' and localisation=null;
UPDATE imported_data SET localisation='Madrid' WHERE contexte_geographique='Madrid España' and localisation=null;
UPDATE imported_data SET localisation='Girona' WHERE contexte_geographique='Girona' and localisation=null;
UPDATE imported_data SET localisation='Barcelona' WHERE contexte_geographique='Barcelona España' and localisation=null;
UPDATE imported_data SET localisation='Guimera' WHERE contexte_geographique='Guimera' and localisation=null;
UPDATE imported_data SET localisation='Zaragoza' WHERE contexte_geographique='España Zaragoza' and localisation=null;
UPDATE imported_data SET localisation='Sala Margarita Xirgu,Teatro Español, Madrid' WHERE contexte_geographique='Sala Margarita Xirgu,Teatro Español, Madrid, España' and localisation=null;
UPDATE imported_data SET localisation='Teatro Goya de Barcelona' WHERE contexte_geographique='teatro Goya de Barcelona' and localisation=null;
UPDATE imported_data SET localisation='Montevideo' WHERE contexte_geographique='Montevideo' and localisation=null;
UPDATE imported_data SET localisation='Puerto Rico' WHERE contexte_geographique='Puerto Rico' and localisation=null;
UPDATE imported_data SET localisation='Teatro romano de Merida' WHERE contexte_geographique='Teatro romano de Merida' and localisation=null;
UPDATE imported_data SET localisation='Museo de Badalona' WHERE contexte_geographique='Museo de Badalona' and localisation=null;
UPDATE imported_data SET localisation='Badalona' WHERE contexte_geographique='Badalona España' and localisation=null;
UPDATE imported_data SET localisation='Montevideo' WHERE contexte_geographique='Uruguay Montevideo' and localisation=null;
UPDATE imported_data SET localisation='Cataluña' WHERE (contexte_geographique='España Cataluña' or contexte_geographique='Cataluña España') and localisation=null;
UPDATE imported_data SET localisation='Montevideo' WHERE contexte_geographique='Uruguay Montevideo' and localisation=null;
UPDATE imported_data SET localisation='Mérida' WHERE contexte_geographique='Mérida España' and localisation=null;
UPDATE imported_data SET localisation='Valencia' WHERE contexte_geographique='Valencia' and localisation=null;
UPDATE imported_data SET localisation='Montevideo' WHERE contexte_geographique='Uruguay | Montevideo' and localisation=null;


------------------------------------------------DROITS------------------------------------------------
/*
On retire les caractères en trop avant et après les droits.
Correction des erreurs pour certains droits.
*/
UPDATE imported_data SET droits=TRIM(blank_to_space(droits));
UPDATE imported_data SET droits='Archives familiar de Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)' WHERE droits='Archives familiales Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)';
-- Supprime les éventuels caractères '$' à la fin du texte.
UPDATE imported_data SET droits=REPLACE(droits, '$', '');

------------------------------------------------AYANTS-DROIT------------------------------------------------

/*
On retire les caractères en trop avant et après les ayants-droit.
*/
UPDATE imported_data SET ayants_droit=TRIM(blank_to_space(ayants_droit));

-- Aucune donnée

------------------------------------------------FORMAT------------------------------------------------

/*
On retire les caractères en trop avant et après le format.
On passe les formats indéterminés à "NULL".
On supprime les formats erronnés. La colonne format ne définit pas le format de fichier (doublon avec nature_document).
Correction des erreurs sur "MX-F-247", dupliqué de notes
*/
UPDATE imported_data SET format=TRIM(blank_to_space(format));
UPDATE imported_data SET format=NULL WHERE format='Indeterminado';
-- On supprime les extensions de fichier (avec ou sans point) dans la colonne format car doublon et non consistent.
UPDATE imported_data SET format=regexp_replace(LOWER(format), '\.?(j[[:blank:]]?[p]?[e]?g|png|pdf)', '');
-- Si certains formats sont vides, on les met à NULL. Important après l'opération précédente.
UPDATE imported_data SET format=NULL WHERE char_length(format)=0;
-- Les formats de tailles de fichiers sont parfois incohérents : jko, lko, kpo pour ko.
UPDATE imported_data SET format=regexp_replace(LOWER(format), '(([a-z]k)|(k[a-z])|(?![gmk])[a-z])o', 'ko');
-- Un enregistrement a un format différent : "33ko 305 × 500", on réorganise en 305x500|33ko
UPDATE imported_data SET format=regexp_replace(blank_to_space(LOWER(format)), '(\d{1,3}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o)),?[[:blank:]]*((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*$', '\5x\6 \1');
-- Un enregistrement a l'unité de taille de fichier manquante : "411x640 39"
UPDATE imported_data SET format=regexp_replace(blank_to_space(LOWER(format)), '^(\d{2,4}[[:blank:]]*[x×][[:blank:]]*\d{2,4})[[:blank:]]+(\d{1,3}([\.\,]\d{1,2})?)[[:blank:]]*$', '\1 \2ko');
-- Un enregistrement a un format invalide : "320x400 pg", on enlève les lettres à la fin et on garde juste la résolution <largeur>x<longueur>
UPDATE imported_data SET format=regexp_replace(blank_to_space(LOWER(format)), '^((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]+[a-z]*$', '\2x\3');
-- Correction manuelle d'un format invalide
UPDATE imported_data SET format='456x640 28ko' WHERE cote='MX-F-813';
-- Correction manuelle d'un format invalide
UPDATE imported_data SET format='881x5991 1mo [0,5mpx]' WHERE cote='MX-F-622';
-- L'enregistrement "MX-F-557" a pour format 350178 ce qui est erronné
UPDATE imported_data set format='350x178' WHERE cote='MX-F-557';
-- L'enregistrement "MX-F-503" a pour format 350178 ce qui est erronné
UPDATE imported_data set format='350x257' WHERE cote='MX-F-503';
-- Le seul document texte a un format très différent, on le stocke dans les données supplémentaires
UPDATE imported_data SET format='[' || format || ']' WHERE cote='AS-AA1-01';

UPDATE imported_data SET format=regexp_replace(format, '^((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*((\d{1,3}([\.\,]\d{1,2})?)[[:blank:]]*([kmg]o))?([[:blank:]]\[.*\])?$', '\2x\3 \5\7\8');
-- Texte dans le format qui est le même que dans notes.
-- TODO : remove UPDATE imported_data SET format=NULL WHERE cote='MX-F-247';



-- TODO : remove
/*SELECT DISTINCT(format) FROM imported_data;
SELECT regexp_matches(LOWER('640 × 454 49,5 ko'), '(\d{2,3}[[:blank:]]*[x×][[:blank:]]*\d{2,3})[[:blank:]]*(\d{1,2}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o))?$');--'(\d{2,4}[[:blank:]]*[x×][[:blank:]]*\d{2,4})[[:blank:]]*(\d{1,2}[\.,]{0,1}[kmg]o)$');
SELECT format FROM imported_data WHERE regexp_replace(blank_to_space(format), '^[\xC2\xA0\x20\x0A]*', ' ') !~ '(\d{2,4}[[:blank:]]*[x×][[:blank:]]*\d{2,4})[[:blank:]]*(\d{1,3}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o))?$';
SELECT regexp_replace('277×582 414,7ko', E'[\\xC2\\xA0\\x20\\x0A]', ' ', 'g') ~ '(\d{2,4}[[:blank:]]*[x×][[:blank:]]*\d{2,4})[[:blank:]]*(\d{1,3}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o))?$';
SELECT parse_format('277 × 582 414,7 ko');
SELECT regexp_replace('277 × 582 414,7 ko', E'[\\xC2\\xA0\\x20\\x0A]', 'a', 'g');
SELECT regexp_matches(blank_to_space('277x55 3,5ko'), '(\d{2,3}[[:blank:]]*[x×][[:blank:]]*\d{2,3})[[:blank:]]*(\d{1,2}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o))?$');*/
SELECT cote, format FROM imported_data WHERE parse_format(format) IS NULL AND format IS NOT NULL;
SELECT regexp_replace('476 × 464231,5 ko [sjask56]', '^((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*((\d{1,3}([\.\,]\d{1,2})?)[[:blank:]]*([kmg]o))?([[:blank:]]\[.*\])?$', '\2x\3 \5\7\8');
/*SELECT regexp_replace('go', '(([a-z]k)|(k[a-z])|(?![gmk])[a-z])o', 'ko');
SELECT regexp_replace(blank_to_space('33ko, 305 × 500'), '(\d{1,3}([\.\,]\d{1,2})?[[:blank:]]*([kmg]o)),?[[:blank:]]*((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*$', '\5x\6 \1');
SELECT regexp_matches('411x640 jdz', '^((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]+[a-z]*$');*/
SELECT regexp_matches('[131 f., 139 p. numeradas 1-6, 5-6, 7-57, 2 pág. s.n., 58-116, 107, 117-137, 220 x 350 mm]', '^(((\d{2,4})[[:blank:]]*[x×][[:blank:]]*(\d{2,4}))[[:blank:]]*((\d{1,3}([\.\,]\d{1,2})?)[[:blank:]]*([kmg]o))?)?([[:blank:]]*\[.*\])?$');

------------------------------------------------LANGUE------------------------------------------------

-- La langue est inutile, voir justification.


-- TODO : remove
-- On retire les caractères en trop avant et après la langue.
-- UPDATE imported_data SET langue=TRIM(LOWER(langue));
-- SELECT langue FROM imported_data WHERE langue IS NOT NULL;

------------------------------------------------ETAT GENETIQUE------------------------------------------------

-- L'état génétique est inutile, voir justification.

-- TODO : remove
-- On retire les caractères en trop avant et après l'état génétique.
-- UPDATE imported_data SET etat_genetique=TRIM(etat_genetique);
-- SELECT etat_genetique FROM imported_data WHERE etat_genetique IS NOT NULL;

------------------------------------------------RELATIONS GENETIQUES------------------------------------------------

/*
On retire les caractères en trop avant et après les relations génétiques ainsi que les "$".
Correction des erreurs pour certaines relations génétiques.

UPPER met en majuscule les lettres. Cela est primordial car certaines relations génétiques sont écrites : mx-f-XXXX
au lieu de MX-F-XXXX.
*/
UPDATE imported_data SET relations_genetiques=UPPER(TRIM(blank_to_space(relations_genetiques)));
UPDATE imported_data SET relations_genetiques=REPLACE(relations_genetiques, '$', '');
UPDATE imported_data SET relations_genetiques=regexp_replace(LOWER(relations_genetiques), 'mx-(\d{3,4})/?', 'MX-F-\1', 'g');
UPDATE imported_data SET relations_genetiques='221/222/223' WHERE relations_genetiques='221/222/222';
UPDATE imported_data SET relations_genetiques='MX-F-221/MX-F-222/MX-F-223' WHERE relations_genetiques='221/222/223';
UPDATE imported_data SET relations_genetiques='MX-F-579/MX-F-612/MX-F-827/MX-F-828/MX-F-829/MX-F-830/MX-F-831/MX-F-832/MX-F-833/MX-F-834/MX-F-835/MX-F-836' WHERE relations_genetiques='Mx-579-Mx-612/827/828/829/830/831/832/833/83/835/836';
UPDATE imported_data SET relations_genetiques='MX-F-603/MX-F-651' WHERE relations_genetiques='MX-603/M-651' OR relations_genetiques='Mx-603/Mx651';
UPDATE imported_data SET relations_genetiques='MX-F-971/MX-F-972/MX-F-973/MX-F-974/MX-F-975/MX-F-976/MX-F-977/MX-F-978' WHERE relations_genetiques='Mx-971/972/73/974/975/976/977978';
-- UPDATE imported_data SET relations_genetiques='MX-F-579/MX-F-612/MX-F-827/MX-F-828/MX-F-829/MX-F-830/MX-F-831/MX-F-832/MX-F-833/MX-F-834/MX-F-835/MX-F-836' WHERE relations_genetiques='MX-579/612/827/828/829/83/831/832/833/834/835/836';
UPDATE imported_data SET relations_genetiques='MX-F-133/MX-F-135/MX-F-136/MX-F-137/MX-F-138/MX-F-139MX-F-/140/MX-F-154/MX-F-426' WHERE relations_genetiques='Mx-133/Mx-135/Mx-136/-Mx-137/Mx-138/Mx-139/Mx-140/Mx-154/Mx-426';
UPDATE imported_data SET relations_genetiques='MX-F-1000' WHERE relations_genetiques='Mx-1000';
UPDATE imported_data SET relations_genetiques='MX-F-1082/MX-F-1083/MX-F-1084/MX-F-1085/MX-F-1086/MX-F-1087' WHERE relations_genetiques='Mx-1082/1083/1084/1085/1086/1087';
UPDATE imported_data SET relations_genetiques='MX-F-164/MX-F-165/MX-F-168/MX-F-169/MX-F-170/MX-F-187/MX-F-188' WHERE relations_genetiques='Mx164/165/168/169/170/187/188';
UPDATE imported_data SET relations_genetiques='MX-F-884/MX-F-885/MX-F-1004' WHERE relations_genetiques='MX-884/Mx-885/Mx-1004';
UPDATE imported_data SET relations_genetiques='MX-F-1080/MX-F-1081/MX-F-1093/MX-F-1095/MX-F-1096' WHERE relations_genetiques='Mx-1080-81-93-95-96';
UPDATE imported_data SET relations_genetiques='MX-F-164/MX-F-165/MX-F-168/MX-F-169/MX-F-170/MX-F-187/MX-F-188' WHERE relations_genetiques='mx164/165/168/169/170/187/188';
UPDATE imported_data SET relations_genetiques='MX-F-950/MX-F-953' WHERE relations_genetiques='MX950/953';

-- TODO : remove
-- SELECT DISTINCT relations_genetiques FROM imported_data WHERE relations_genetiques !~ '(MX-F-\d{3,4}/?)+';
-- SELECT regexp_matches('Mx-412/Mx-602-Mx-625/Mx-637/Mx-642', '(Mx-\d{1,4}/?)+');

/*
On retire les caractères en trop avant et après les autres relations.
*/
UPDATE imported_data SET autres_ressources_relation=TRIM(blank_to_space(autres_ressources_relation));

/*
On retire les caractères en trop avant et après la nature du document.
Correction des erreurs pour certaines nature de document + simplification du nom.
*/
UPDATE imported_data SET nature_document=UPPER(TRIM(blank_to_space(nature_document)));
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPE', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPEG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'PNE', 'PNG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'PNGG', 'PNG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'ARCHIVOS', '');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'ARCHIVO', '');
UPDATE imported_data SET nature_document=regexp_replace(nature_document, '^.*PDF.*$', 'PDF');
UPDATE imported_data SET nature_document = TRIM(nature_document);
/*
On retire les caractères en trop avant et après le support.
*/
UPDATE imported_data SET support=TRIM(UPPER(blank_to_space(support)));

/*
On retire les caractères en trop avant et après le mot.
On passe les états indéfinis à "NULL".
Correction des erreurs pour certains états.
*/
UPDATE imported_data SET etat_general=TRIM(LOWER(blank_to_space(etat_general)));
-- Français -> Espagnol
UPDATE imported_data SET etat_general='mediocre' WHERE LOWER(etat_general)='médiocre';
UPDATE imported_data SET etat_general=NULL WHERE LOWER(etat_general)='indeterminado';
UPDATE imported_en SET etat_general=trim_blank(LOWER(blank_to_space(etat_general)));
UPDATE imported_en SET etat_general='very poor' WHERE LOWER(etat_general)='muy poor';
UPDATE imported_en SET etat_general='good' WHERE LOWER(etat_general)='bueno';
UPDATE imported_en SET etat_general='poor' WHERE LOWER(etat_general)='mediocre' or LOWER(etat_general)='médiocre';
UPDATE imported_en SET etat_general=null WHERE LOWER(etat_general)='unspecified';							


-- On retire les caractères en trop avant et après la publication.
UPDATE imported_data SET publication = TRIM(blank_to_space(publication));
UPDATE imported_en SET publication = TRIM(blank_to_space(publication));
SELECT publication FROM imported_data WHERE cote='MX-F-306';

-- TODO : remove
-- SELECT regexp_replace(blank_to_space('http://margaritaxirgu.es/002.jpg   Link'), '(https?://.+?)[[:blank:]]*+', 'a', 'ng'); -- : https://photooos.google.com/share/a3ln  https://photos.google.com/share/Aln'),

SELECT regexp_replace(blank_to_space('https://margaritaxirgu.es/002.jpg Link :  http://margaritaxirgu.es/002.jpg'), '(https?://[^[:blank:]]+)[[:blank:]]*([^(http)]*)', '[\1] (\2) ', 'g'); -- : https://photooos.google.com/share/a3ln  https://photos.google.com/share/Aln'),
SELECT 'http://margaritaxirgu.es/002.jpg' ~ '(http://[^[:blank:]])';
/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET representation = TRIM(blank_to_space(representation));

/*
On retire les caractères en trop avant et après le mot.
On passe les zones géographiques indéfinies à "NULL".
Correction des erreurs pour certaines zones géographiques.
*/
UPDATE imported_data SET contexte_geographique = trim_blank((contexte_geographique));
UPDATE imported_data SET contexte_geographique = NULL WHERE LOWER(contexte_geographique)='desconocido' or LOWER(contexte_geographique)='indeterminado' or contexte_geographique='#VALUE!';
UPDATE imported_data SET contexte_geographique = 'Uruguay' WHERE contexte_geographique='uruguay' 
or contexte_geographique='Punta del este' or contexte_geographique='Teatro Solís de Montevideo' or contexte_geographique='intendencia Maldonado' or contexte_geographique='Punta ballena Uruguay'
or contexte_geographique='Montevideo' or contexte_geographique='Uruguay.' or contexte_geographique='Uruguay Montevideo' or contexte_geographique='Punta del Este'
or contexte_geographique='Uruguay | Montevideo';
UPDATE imported_data SET contexte_geographique = 'España' WHERE contexte_geographique='Merida España' OR contexte_geographique='Merida' 
OR contexte_geographique='Merdia España' OR contexte_geographique='Medirda' or contexte_geographique='España Madrid' or contexte_geographique='Espagne'
or contexte_geographique='Barcelona' or contexte_geographique='Badalona' OR contexte_geographique='España Badalona'
OR contexte_geographique='Granada España' OR contexte_geographique='Sevilla' OR contexte_geographique='Molins de Rei' OR contexte_geographique='Plaza Margarida Xirgu Barcelona'
OR contexte_geographique='Colección de escenografía del Instituto del Teatro de la Diputación de Barcelona.' OR contexte_geographique='Madrid España'
or contexte_geographique='Girona' or contexte_geographique='Barcelona España' or contexte_geographique='Guimera'
or contexte_geographique='España Zaragoza' or contexte_geographique='Sala Margarita Xirgu,Teatro Español, Madrid, España' or contexte_geographique='Teatro romano de Merida' or contexte_geographique='teatro Goya de Barcelona'
or contexte_geographique='Teatro romano de Merida' or contexte_geographique='Museo de Badalona' or contexte_geographique='Badalona España' or contexte_geographique='España Cataluña'
or contexte_geographique='Cataluña España' or contexte_geographique='Valencia' or contexte_geographique='Plaza Margarida Xirgu Barcelona';
UPDATE imported_data SET contexte_geographique = 'Argentina' WHERE contexte_geographique='Buenos Aires' or contexte_geographique='Buenos Aires Argentina';
UPDATE imported_data SET contexte_geographique = 'Chile' WHERE contexte_geographique='chile';
UPDATE imported_data SET contexte_geographique = 'Hispanoamerica' WHERE contexte_geographique='Hispanoameirca' or contexte_geographique='America Latina' or contexte_geographique='Uruguay Argentina o Chile';
UPDATE imported_data SET contexte_geographique = 'Estados Unidos' WHERE contexte_geographique='Puerto Rico';


UPDATE imported_en SET contexte_geographique = trim_blank((contexte_geographique));
UPDATE imported_en SET contexte_geographique = NULL WHERE LOWER(contexte_geographique)='desconocido' 
or LOWER(contexte_geographique)='indeterminado' or contexte_geographique='#VALUE!' or LOWER(contexte_geographique)='undetermined';
UPDATE imported_en SET contexte_geographique = 'Spain' WHERE contexte_geographique='Barcelona'
or contexte_geographique='Merdida' or contexte_geographique='Granada Spain' or contexte_geographique='Colección de escenografía del Instituto del theatrede la Diputación de Barcelona.'
or contexte_geographique='Badalona' or contexte_geographique='Molins de Rei' or contexte_geographique='Sevilla' or contexte_geographique='Plaza Margarida Xirgu Barcelona'
or contexte_geographique='Merdia Spain' or contexte_geographique='Cataluña Spain' or contexte_geographique='Merida Spain' or contexte_geographique='Guimera'
or contexte_geographique='Girona' or contexte_geographique='Spain Badalona' or contexte_geographique='Barcelona Spain' or contexte_geographique='Barcelona'
or contexte_geographique='Museo de Badalona' or contexte_geographique='Spain Madrid' or contexte_geographique='Spain Cataluña' or contexte_geographique='Spain Zaragoza'
or contexte_geographique='Madrid Spain' or contexte_geographique='Valencia' or contexte_geographique='theatreGoya de Barcelona' or contexte_geographique='Badalona Spain'
or contexte_geographique='Margarita Xirgu Room,,theatreEspañol, Madrid, Spain' or contexte_geographique='Medirda'
or contexte_geographique='Roman theater of Merida' or contexte_geographique='Merida';
UPDATE imported_en SET contexte_geographique = 'Uruguay' WHERE contexte_geographique='Uruguay.' or contexte_geographique='Punta del Este'
or contexte_geographique='intendencia Maldonado' or contexte_geographique='Punta ballena Uruguay' or contexte_geographique='theatreSolís de Montevideo'
or contexte_geographique='uruguay' or contexte_geographique='Montevideo' or contexte_geographique='Punta del este'
or contexte_geographique='Uruguay Montevideo' or contexte_geographique='' or contexte_geographique='Uruguay | Montevideo';
UPDATE imported_en SET contexte_geographique = 'Chile' WHERE contexte_geographique='chile';
UPDATE imported_en SET contexte_geographique = 'Argentina' WHERE contexte_geographique='Buenos Aires Argentina' or contexte_geographique='Buenos Aires';
UPDATE imported_en SET contexte_geographique = 'USA' WHERE contexte_geographique='Puerto Rico';
UPDATE imported_en SET contexte_geographique = 'Latin America' WHERE contexte_geographique='Uruguay Argentina or Chile';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET lieu_expedition = TRIM(blank_to_space(lieu_expedition));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET type_publication = TRIM(blank_to_space(type_publication));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET titre_publication = TRIM(blank_to_space(titre_publication));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET lieu_publication = TRIM(blank_to_space(lieu_publication));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET numero_publication = TRIM(blank_to_space(numero_publication));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET periodicite = TRIM(blank_to_space(periodicite));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET directeur_publication = TRIM(blank_to_space(directeur_publication));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_analyse = TRIM(blank_to_space(auteur_analyse));
UPDATE imported_en SET auteur_analyse = TRIM(blank_to_space(auteur_analyse));

/*
On retire les caractères en trop avant et après le mot ainsi que le "$".
Correction d'une date pour une future utilisation
*/
UPDATE imported_data SET date_analyse = TRIM(blank_to_space(date_analyse));
UPDATE imported_data SET date_analyse = TRIM(BOTH '$' FROM date_analyse);
UPDATE imported_data SET date_analyse = '2015-01-01/2019-01-01' WHERE date_analyse = '2015/2019';
UPDATE imported_en SET date_analyse = TRIM(blank_to_space(date_analyse));
UPDATE imported_en SET date_analyse = TRIM(BOTH '$' FROM date_analyse);
UPDATE imported_en SET date_analyse = '2015-01-01/2019-01-01' WHERE date_analyse = '2015/2019';
							  
/*
On retire les caractères en trop avant et après le mot.
Correction des erreurs pour certains noms (convention: nom puis prénom).
*/
UPDATE imported_data SET auteur_description = TRIM(blank_to_space(auteur_description));
UPDATE imported_data SET auteur_description = 'Gil Alan' WHERE auteur_description = 'Alan Gil';
UPDATE imported_en SET auteur_description = TRIM(blank_to_space(auteur_description));
UPDATE imported_en SET auteur_description = 'Gil Alan' WHERE auteur_description = 'Alan Gil';
/*
On retire les caractères en trop avant et après le mot ainsi que le "$".
Correction d'une date pour une future utilisation
*/
UPDATE imported_data SET date_creation_notice = TRIM(blank_to_space(date_creation_notice));
UPDATE imported_data SET date_creation_notice = TRIM(BOTH '$' FROM date_creation_notice);
UPDATE imported_data SET date_creation_notice = '2015-01-01/2019-01-01' WHERE date_creation_notice = '2015/2019';
UPDATE imported_en SET date_creation_notice = TRIM(blank_to_space(date_creation_notice));
UPDATE imported_en SET date_creation_notice = TRIM(BOTH '$' FROM date_creation_notice);
UPDATE imported_en SET date_creation_notice = '2015-01-01/2019-01-01' WHERE date_creation_notice = '2015/2019';
								  
/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_revision = TRIM(blank_to_space(auteur_revision));

/*
On retire les caractères en trop avant et après le mot.
On passe la table en type "timestamp" pour une future utilisation.
*/
UPDATE imported_data SET date_revision_notice = TRIM(blank_to_space(date_revision_notice));
ALTER TABLE imported_data 
	ALTER date_revision_notice DROP DEFAULT,
	ALTER date_revision_notice TYPE timestamp USING date_revision_notice::timestamp;
ALTER TABLE imported_en 
	ALTER date_revision_notice DROP DEFAULT,
	ALTER date_revision_notice TYPE timestamp USING date_revision_notice::timestamp;
								    
/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_transcription = TRIM(blank_to_space(auteur_transcription));

/*
Correction des erreurs concernant le décalage de la colonne duplication.
*/
UPDATE imported_data SET publication=(SELECT __dummy FROM imported_data WHERE cote='MX-F-93') WHERE cote='MX-F-92';
UPDATE imported_data SET publication=(SELECT __dummy FROM imported_data WHERE cote='MX-F-94') WHERE cote='MX-F-93';
UPDATE imported_data SET publication=(SELECT __dummy FROM imported_data WHERE cote='MX-F-95') WHERE cote='MX-F-94';

-- Désormais cette colonne n'est plus d'aucune utilité
-- TODO : ALTER TABLE imported_data DROP COLUMN __dummy;


-- Exploration
SELECT cote, __dummy FROM imported_data WHERE __dummy IS NOT NULL;
SELECT * FROM imported_data;
SELECT COUNT(*) FROM imported_data;

-- Supprime le début de la ligne
SELECT parse_editeur();

SELECT DISTINCT(notes) FROM imported_data;
SELECT cote, notes FROM imported_data WHERE notes='El archivo original se llama:5.jpg';
SELECT format FROM imported_data WHERE format ~ '(.*)(\d+\s*[x×X]\s*\d+)(.*)'; --regexp_matches(format, '.*(\d+\s*[x×]\s*\d+).*')
						 
						 
						 
						 
						 
						 
						 
						 
						 
						 
						 
------------------------------------------------ CRÉATION DES TABLES ------------------------------------------------
DROP TABLE IF EXISTS personne CASCADE;
CREATE TABLE personne(
	id_personne serial primary key,
	nom varchar(25),
	prenom varchar(25)
);

DROP TABLE IF EXISTS type_es,type_en CASCADE;
CREATE TABLE type_es(
	id_type serial primary key,
	nom varchar(10)
);

CREATE TABLE type_en(
	id_type serial primary key,
	nom varchar(10)
);

DROP TABLE IF EXISTS datatype_es,datatype_en CASCADE;
CREATE TABLE datatype_es(
	id_datatype serial primary key,
	nom varchar(10)
);

CREATE TABLE datatype_en(
	id_datatype serial primary key,
	nom varchar(10)
);

DROP TABLE IF EXISTS titre_es,titre_en CASCADE;
CREATE TABLE titre_es(
	id_titre serial primary key,
	nom varchar(50)
);

CREATE TABLE titre_en(
	id_titre serial primary key,
	nom varchar(50)
);

DROP TABLE IF EXISTS sous_titre_es,sous_titre_en CASCADE;
CREATE TABLE sous_titre_es(
	id_sous_titre serial primary key,
	nom text
);

CREATE TABLE sous_titre_en(
	id_sous_titre serial primary key,
	nom text
);

DROP TABLE IF EXISTS auteur_es,auteur_en CASCADE;
CREATE TABLE auteur_es(
	id_auteur serial primary key,
	nom varchar(50)
);

CREATE TABLE auteur_en(
	id_auteur serial primary key,
	nom varchar(50)
);

DROP TABLE IF EXISTS destinataire_es,destinataire_en CASCADE;
CREATE TABLE destinataire_es(
	id_destinataire serial primary key,
	nom text
);

CREATE TABLE destinataire_en(
	id_destinataire serial primary key,
	nom text
);

DROP TABLE IF EXISTS sujet_es,sujet_en CASCADE;
CREATE TABLE sujet_es(
	id_sujet serial primary key,
	nom text
);

CREATE TABLE sujet_en(
	id_sujet serial primary key,
	nom text
);

DROP TABLE IF EXISTS description_es,description_en CASCADE;
CREATE TABLE description_es(
	id_description serial primary key,
	texte text
);

CREATE TABLE description_en(
	id_description serial primary key,
	texte text
);

DROP TABLE IF EXISTS auteur_description CASCADE;
CREATE TABLE auteur_description(
	id_description integer,
	id_personne integer,
	FOREIGN KEY (id_description) REFERENCES description(id_description),
	FOREIGN KEY (id_personne) REFERENCES personne(id_personne)
);

DROP TABLE IF EXISTS document;
CREATE TABLE document(
	id_document varchar(15) primary key,
	dates_debut timestamp,
	dates_fin timestamp,
	relations_genetiques text,
	format varchar(15),
	id_auteur_analyse integer,
	data_analyse timestamp NOT NULL DEFAULT NOW(),
	data_creation_notice timestamp DEFAULT NULL,
	FOREIGN KEY (id_auteur_analyse) REFERENCES personne(id_personne)
);

DROP TABLE IF EXISTS notes CASCADE;
CREATE TABLE notes(
	id_document varchar(15),
	texte text,
	id_auteur integer,
	FOREIGN KEY (id_auteur) REFERENCES personne(id_personne),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS resume_es,resume_en CASCADE;
CREATE TABLE resume_es(
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

CREATE TABLE resume_en(
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS responsable_archive_es,responsable_archive_en CASCADE;
CREATE TABLE responsable_archive_es (
	id_reponsable_archive serial primary key,
	nom varchar(150)
);

CREATE TABLE responsable_archive_en (
	id_reponsable_archive serial primary key,
	nom varchar(150)
);

DROP TABLE IF EXISTS responsable_scientifique_es,responsable_scientifique_en CASCADE;
CREATE TABLE responsable_scientifique_es (
	id_reponsable integer,
	localisation varchar(150),
	statut varchar(150),
	poste varchar(150),
	PRIMARY KEY (id_reponsable),
	FOREIGN KEY (id_reponsable) REFERENCES personne(id_personne)
);

CREATE TABLE responsable_scientifique_en (
	id_reponsable integer,
	localisation varchar(150),
	statut varchar(150),
	poste varchar(150),
	PRIMARY KEY (id_reponsable),
	FOREIGN KEY (id_reponsable) REFERENCES personne(id_personne)
);

DROP TABLE IF EXISTS editeur_es,editeur_en CASCADE;
CREATE TABLE editeur_es (
	id_editeur serial primary key,
	nom_editeur varchar(150)
);	

CREATE TABLE editeur_en (
	id_editeur serial primary key,
	nom_editeur varchar(150)
);

DROP TABLE IF EXISTS contexte_geo_es,contexte_geo_en CASCADE;
CREATE TABLE contexte_geo_es(
	id_contexte_geo serial primary key,
	nom varchar(30),
	lat float,
	lon float
);

CREATE TABLE contexte_geo_en(
	id_contexte_geo serial primary key,
	nom varchar(30),
	lat float,
	lon float
);

DROP TABLE IF EXISTS localisation_es,localisation_en CASCADE;
CREATE TABLE localisation_es (
	id_localisation serial primary key,
	nom varchar(20),
	id_contexte_geo integer NOT NULL,
	FOREIGN KEY (id_contexte_geo) REFERENCES contexte_geo_es(id_contexte_geo)
);

CREATE TABLE localisation_en (
	id_localisation serial primary key,
	nom varchar(20),
	id_contexte_geo integer NOT NULL,
	FOREIGN KEY (id_contexte_geo) REFERENCES contexte_geo_en(id_contexte_geo)
);

DROP TABLE IF EXISTS licence_es,licence_en CASCADE;
CREATE TABLE licence_es (
	id_licence serial primary key,
	texte text
);

CREATE TABLE licence_en (
	id_licence serial primary key,
	texte text
);

DROP TABLE IF EXISTS droits_es,droits_en CASCADE;
CREATE TABLE droits_es (
	id_droit serial primary key,
	texte text,
	id_licence integer,
	FOREIGN KEY (id_licence) REFERENCES licence_es(id_licence)
);

CREATE TABLE droits_en (
	id_droit serial primary key,
	texte text,
	id_licence integer,
	FOREIGN KEY (id_licence) REFERENCES licence_en(id_licence)
);

DROP TABLE IF EXISTS etat_genetique CASCADE;
CREATE TABLE etat_genetique(
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS autres_relations CASCADE;
CREATE TABLE autres_relations(
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS nature_document CASCADE;
CREATE TABLE nature_document(
	id_document varchar(15),
	nom varchar(10),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS support_es,support_en CASCADE;
CREATE TABLE support_es (
	id_document varchar(15),
	nom varchar(7) NOT NULL,
	CHECK (nom='digital' or nom='papel'),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

CREATE TABLE support_en (
	id_document varchar(15),
	nom varchar(7) NOT NULL
	CHECK (nom='digital' or nom='paper'),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS etat_general_es,etat_general_en CASCADE;
CREATE TABLE etat_general_es (
	id_document varchar(15),
	nom varchar(7) NOT NULL,
	CHECK (nom='muy dañado' or nom='dañado' or nom='muy mediocre' or nom='mediocre' or nom='bueno'),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

CREATE TABLE etat_general_en (
	id_document varchar(15),
	nom varchar(7) NOT NULL,
	CHECK (nom='very damaged' or nom='damaged' or nom='very poor' or nom='poor' or nom='good'),
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS publication_es,publication_en CASCADE;
CREATE TABLE publication_es (
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

CREATE TABLE publication_en (
	id_document varchar(15),
	texte text,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS representation CASCADE;
CREATE TABLE representation(
	id_document varchar(15) primary key,
	representation boolean NOT NULL DEFAULT false,
	FOREIGN KEY (id_document) REFERENCES document(id_document)
);

DROP TABLE IF EXISTS revision CASCADE;
CREATE TABLE revision (
	id_document varchar(15),
	date_revision_notice timestamp,
	id_personne integer,
	FOREIGN KEY (id_document) REFERENCES document(id_document),
	FOREIGN KEY (id_personne) REFERENCES personne(id_personne)
);					
						 
						 
------------------------------------------------ MISE EN PLACE DES INSERTIONS ------------------------------------------------		
							   
						 
INSERT INTO personne(nom,prenom) VALUES ('Gil','Alan');
INSERT INTO personne(nom,prenom) VALUES ('Chantraine Braillon','Cécile');
INSERT INTO personne(nom,prenom) VALUES ('Idmhand','Fatiha');

INSERT INTO responsable_scientifique VALUES (1, 'La Rochelle Université', 'Alumno', 'Master LEA Amérique');
INSERT INTO responsable_scientifique VALUES (2, 'La Rochelle Université', 'Profesor', 'Equipo CRHIA');
INSERT INTO responsable_scientifique VALUES (3, 'La Rochelle Université', 'Profesor', 'CRLA Institut des textes et manuscrits modernes CNRS-UMR8132');

INSERT INTO editeur(nom_editeur) VALUES ('Editor Proyecto e-spectateur AAP 2020 '),('Editor Proyecto CollEx-Persée Archivos 3.0 AAP 2018 ');

INSERT INTO responsable_archive(nom) VALUES
('Familia de Maragrita Xirgu (fondo de los hermanos Xiru)'),('Albert Prats Prat'),('Departamento de Cultura de la Generalidad de Cataluña '),
('Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona'),('Foto Escena Catalana'),
('MAE Barcelona'),('Arxiu Marta Prats Xirgu'),('Francesc Foguet i Boreu'),
('Dr Sylvie Josserand Colla (Equipo Archivos-CRLA Institut des textes et manuscrits modernes CNRS-UMR8132)'),
('La Vanguardia'), ('El Instituto del Teatro de la Diputación de Barcelona'),
('Teatro de Barcelona'),('Amadeu Mariné Vadalaco'), ('Antonina Rodrigo'),('Antonio y Ramon Clapés'),('Biblioteca Sebastiá Juan Arbó'),
('Carmen M.Gual'),('Colección de escenografía del Instituto del Teatro de la Diputación de Barcelona'),
('Festival de Mérida'),('Foto Archivo Xavier Rius Xirgu'),('Fotos de su nieto Jaime Gutiérrez Morcillo'),
('José Antonio'),('Lluis Andú');
		
INSERT INTO support VALUES ('DIGITAL'),('PAPEL');
INSERT INTO datatype VALUES ('imagen','DIGITAL'),('text','PAPEL');


INSERT INTO pays(nom,lat,lon) VALUES 
('España',40.463667, -3.749220),
('Estados Unidos',37.090240,-95.712891),
('Uruguay',-32.522779,-55.765835),
('Argentina',-38.4212955,-63.587402499999996),
('Chile',-31.7613365,-71.3187697),
('Peru',-6.8699697,-75.0458515);

INSERT INTO localisation(texte,id_pays) VALUES 
('Teatro Solís de Montevideo',3),
('Mérida',1),
('Badalona',1),
('EMAD: Escuela Municipal de Arte Dramático de Montevideo',3),
('Plaza Margarida Xirgu Barcelona',1),
('Granada',1),
('Girona',1),
('MAE Barcelona',1),
('Punta Ballena',3),
('Molins de Rei Cataluña',1),
('Salamanca',1),
('Instituto de Teatro de Barcelona',1),
('Barcelona',1),
('Montevideo',3),
('Calle Margarida Xirgu de Badalona',1),
('Teatro romano de Merida',1),
('Sala Margarita Xirgu,Teatro Español, Madrid,',1),
('Barcelona instituto del teatro',1),
('Cataluña',1),
('Fresno USA',2),
('Madrid',1),
('Barcelona MAE',1),
('Valencia',1),
('Teatro de la Diputación de Barcelona.',1),
('Ciudad Real Museo Nacional Del teatro',1);

INSERT INTO etat(nom) VALUES
('muy dañado'),('dañado'),('muy mediocre'),('mediocre'),('bueno');


