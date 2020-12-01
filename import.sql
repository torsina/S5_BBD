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
-- Importation du CSV. Pourquoi en 2020, ce logiciel n'accepte pas les chemins relatifs ????
COPY imported_data
FROM 'E:\Esp-fotos.csv'/*'D:\Boulot\L3\BASE_DE_DONNEES\PROJET\Esp-fotos.csv'*/
DELIMITER ';'
CSV HEADER;

-- NETTOYAGE DE LA TABLE

------------------------------------------------COTE------------------------------------------------

-- On retire les caractères en trop avant et après la cote.
UPDATE imported_data SET cote=TRIM(cote);

-- Test, on vérifie que toutes les cotes sont uniques et qu'elles vérifient bien le bon format.
SELECT COUNT(DISTINCT cote)=1122 FROM imported_data WHERE cote ~ '\w{1,3}-\w{1,3}-\w{1,3}';

------------------------------------------------TYPE------------------------------------------------

-- On retire les caractères en trop avant et après le type.
UPDATE imported_data SET type=TRIM(type);

------------------------------------------------DATATYPE------------------------------------------------


/*
On retire les caractères en trop avant et après le mot.
On passe datatype en minsucule pour uniformiser la casse, qui était différente.
*/
UPDATE imported_data SET datatype=LOWER(TRIM(datatype));

------------------------------------------------DATES------------------------------------------------
/*
On retire les caractères en trop avant et après la date.
Toutes les dates inconnues sont passées à "null".
Correction des erreurs pour certaines dates.
Certains enregistrements avaient du texte invalide dans cette colonne.
Ces textes sont des informations redondantes (déjà dans colonne notes).
Décalage de la colonne titre pour "MX-F-20" corrigé.
*/
UPDATE imported_data SET dates=TRIM(dates);
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

-- Test, vérifie que tous les enregistrements sont au bon format.
SELECT COUNT(*)=0 FROM imported_data WHERE dates !~ '^\d{4}-\d{2}-\d{2}$' AND dates !~ '^\d{4}$' AND dates !~ '^\d{4}-\d{4}$';


------------------------------------------------TITRE------------------------------------------------
/*
Titre pour "MX-F-20" actualisé (NULL -> 'Magarita Xirgu').
On retire les caractères en trop avant et après le titre.
*/
UPDATE imported_data SET titre='Magarita Xirgu' WHERE cote='MX-F-20';
UPDATE imported_data SET titre=TRIM(titre);
------------------------------------------------SOUS-TITRE------------------------------------------------

-- On retire les caractères en trop avant et après le sous-titre.
UPDATE imported_data SET sous_titre=TRIM(sous_titre);
-- "MX-F-556" a un sous-titre vide mais non NULL.
UPDATE imported_data SET sous_titre=NULL WHERE char_length(sous_titre)=0;

------------------------------------------------AUTEUR------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
On passe à "null" tous les auteurs inconnus
*/
UPDATE imported_data SET auteur=TRIM(auteur);
-- On fait une comparaison avec le texte en minuscule pour ignorer la casse
UPDATE imported_data SET auteur=NULL WHERE LOWER(auteur)='indeterminado';

------------------------------------------------DESTINATAIRE------------------------------------------------

-- On retire les caractères en trop avant et après le mot.
UPDATE imported_data SET destinataire=TRIM(destinataire);

------------------------------------------------SUJET------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
Correction d'une erreur pour "MX-F-185"
*/
UPDATE imported_data SET sujet=TRIM(sujet);
UPDATE imported_data SET sujet='Margarita xirgu' WHERE cote='MX-F-185';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET description = trim(description);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET notes = trim(notes);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET resume=TRIM(resume);

/*
On retire les caractères en trop avant et après le mot.
Correction des erreurs pour certains éditeurs.
*/
UPDATE imported_data SET editeur = REPLACE(editeur, ':', '');
UPDATE imported_data SET editeur = REPLACE(editeur, '|', '');
UPDATE imported_data SET editeur = REPLACE(editeur, ',', '');
UPDATE imported_data SET editeur = REPLACE(editeur, '  ', '');
UPDATE imported_data SET editeur = REPLACE(editeur, 'fonfo', 'fondo');
UPDATE imported_data SET editeur = REPLACE(editeur, 'espectateur', 'spectateur');
UPDATE imported_data SET editeur = REPLACE(editeur, 'Jose', 'José');
UPDATE imported_data SET editeur = REPLACE(editeur, '. ', '.');
UPDATE imported_data SET editeur = REPLACE(editeur, 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela) Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela)Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur = REPLACE(editeur, 'Responsable del archivo Indeterminadospectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur = REPLACE(editeur, 'Responsable del archivo IndeterminadoEditor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur = REPLACE(editeur, 'Responsable del archivo  Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur = TRIM(editeur);

/*
On retire les caractères en trop avant et après le mot.
On passe les localisations inconnues à "null".
Correction des erreurs pour certaines localisations.
*/
UPDATE imported_data SET localisation = TRIM(localisation);
UPDATE imported_data SET localisation = null WHERE LOWER(localisation)='desconocido' or LOWER(localisation)='indeterminado';
UPDATE imported_data SET localisation = 'Punta Ballena Uruguay' WHERE localisation=' Punta Ballena (Maldonado) Uruguay' or localisation='Punta Ballena';
UPDATE imported_data SET localisation = 'Teatro Solís, Montevideo (Uruguay)' WHERE localisation='Teatro Solís de Montevideo';
UPDATE imported_data SET localisation = 'EMAD: Escuela Municipal de Arte Dramático de Montevideo' WHERE localisation='EMAD: Escuela Municipal de Arte Dramático de Montevideo.';
UPDATE imported_data SET localisation = 'Madrid España' WHERE localisation='Madrid' or localisation='Madrid España';
UPDATE imported_data SET localisation = 'Mérida España' WHERE localisation='Merida' or localisation='Mérida' or localisation='Merida España' or localisation='Meridaa';

/*
On retire les caractères en trop avant et après le mot.
Correction des erreurs pour certains droits.
*/
UPDATE imported_data SET droits = TRIM(droits);
UPDATE imported_data SET droits = 'Archives familiar de Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)' WHERE droits='Archives familiales Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)';
UPDATE imported_data SET droits = 'Mx-4/413/650' WHERE droits='Mx-4/413/650$';
UPDATE imported_data SET droits = 'Mx-950/953' WHERE droits='Mx950/953$';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET ayants_droit = trim(ayants_droit);

/*
On retire les caractères en trop avant et après le mot.
On passe les formats indéterminés à "null".
On supprime les formats erronnés. La colonne format ne définit pas le format de fichier (doublon avec nature_document).
Correction des erreurs sur "MX-F-247", dupliqué de notes
*/
UPDATE imported_data SET format = trim(format);
UPDATE imported_data SET format=NULL WHERE format='Indeterminado';
UPDATE imported_data SET format=NULL WHERE LOWER(format) ~ '(jp[e]{0,1}g|png|pdf)'; 
UPDATE imported_data SET format=NULL WHERE cote='MX-F-247';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET langue = trim(UPPER(langue));

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET etat_genetique = trim(etat_genetique);

/*
On retire les caractères en trop avant et après le mot ainsi que les "$".
Correction des erreurs pour certaines relations génétiques.
*/
UPDATE imported_data SET relations_genetiques = trim(relations_genetiques);
UPDATE imported_data SET relations_genetiques = REPLACE(relations_genetiques, '$', '');
UPDATE imported_data SET relations_genetiques = 'MX-579/612/827/828/829/83/831/832/833/834/835/836' WHERE relations_genetiques='Mx-579-Mx-612/827/828/829/830/831/832/833/83/835/836';
UPDATE imported_data SET relations_genetiques = 'Mx-603/651' WHERE relations_genetiques='MX-603/M-651' or relations_genetiques='Mx-603/Mx651';
UPDATE imported_data SET relations_genetiques = 'Mx-971/972/73/974/975/976/977/978' WHERE relations_genetiques='Mx-971/972/73/974/975/976/977978';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET autres_ressources_relation = trim(autres_ressources_relation);

/*
On retire les caractères en trop avant et après le mot.
Correction des erreurs pour certaines nature de document + simplification du nom.
*/
UPDATE imported_data SET nature_document = UPPER(nature_document);
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPE', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPEG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'JPGGG', 'JPG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'PNE', 'PNG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'PNGG', 'PNG');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'ARCHIVOS', '');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'ARCHIVO', '');
UPDATE imported_data SET nature_document = REPLACE(nature_document, 'EN PDF', 'PDF');
UPDATE imported_data SET nature_document = TRIM(nature_document);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET support = trim(upper(support));

/*
On retire les caractères en trop avant et après le mot.
On passe les états indéfinis à "null".
Correction des erreurs pour certains états.
*/
UPDATE imported_data SET etat_general = TRIM(lower(etat_general));
UPDATE imported_data SET etat_general = 'médiocre' WHERE etat_general = 'mediocre';
UPDATE imported_data SET etat_general = null WHERE etat_general = 'indeterminado';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET publication = TRIM(publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET representation = TRIM(representation);

/*
On retire les caractères en trop avant et après le mot.
On passe les zones géographiques indéfinies à "null".
Correction des erreurs pour certaines zones géographiques.
*/
UPDATE imported_data SET contexte_geographique = TRIM(contexte_geographique);
UPDATE imported_data SET contexte_geographique = null WHERE LOWER(contexte_geographique)='desconocido' or LOWER(contexte_geographique)='indeterminado' or contexte_geographique='#VALUE!';
UPDATE imported_data SET contexte_geographique = 'Uruguay' WHERE contexte_geographique='uruguay';
UPDATE imported_data SET contexte_geographique = 'Punta del Este' WHERE contexte_geographique='Punta del este';
UPDATE imported_data SET contexte_geographique = 'Mérida España' WHERE contexte_geographique='Merida España' or contexte_geographique='Merida' or contexte_geographique='Merdia España' or contexte_geographique='Medirda';
UPDATE imported_data SET contexte_geographique = 'Madrid España' WHERE contexte_geographique='España Madrid';
UPDATE imported_data SET contexte_geographique = 'España' WHERE contexte_geographique='Espagne';
UPDATE imported_data SET contexte_geographique = 'Buenos Aires Argentina' WHERE contexte_geographique='Buenos Aires';
UPDATE imported_data SET contexte_geographique = 'Barcelona España' WHERE contexte_geographique='Barcelona';
UPDATE imported_data SET contexte_geographique = 'Badalona España' WHERE contexte_geographique='Badalona' or contexte_geographique='España Badalona';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET lieu_expedition = TRIM(lieu_expedition);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET type_publication = TRIM(type_publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET titre_publication = TRIM(titre_publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET lieu_publication = TRIM(lieu_publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET numero_publication = TRIM(numero_publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET periodicite = TRIM(periodicite);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET directeur_publication = TRIM(directeur_publication);

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_analyse = TRIM(auteur_analyse);

/*
On retire les caractères en trop avant et après le mot ainsi que le "$".
Correction d'une date pour une future utilisation
*/
UPDATE imported_data SET date_analyse = TRIM(date_analyse);
UPDATE imported_data SET date_analyse = TRIM(BOTH '$' FROM date_analyse);
UPDATE imported_data SET date_analyse = '2015-01-01/2019-01-01' WHERE date_analyse = '2015/2019';

/*
On retire les caractères en trop avant et après le mot.
Correction des erreurs pour certains noms (convention: nom puis prénom).
*/
UPDATE imported_data SET auteur_description = TRIM(auteur_description);
UPDATE imported_data SET auteur_description = 'Gil Alan' WHERE auteur_description = 'Alan Gil';

/*
On retire les caractères en trop avant et après le mot ainsi que le "$".
Correction d'une date pour une future utilisation
*/
UPDATE imported_data SET date_creation_notice = TRIM(date_creation_notice);
UPDATE imported_data SET date_creation_notice = TRIM(BOTH '$' FROM date_analyse);
UPDATE imported_data SET date_creation_notice = '2015-01-01/2019-01-01' WHERE date_creation_notice = '2015/2019';

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_revision = TRIM(auteur_revision);

/*
On retire les caractères en trop avant et après le mot.
On passe la table en type "timestamp" pour une future utilisation.
*/
UPDATE imported_data SET date_revision_notice = TRIM(date_revision_notice);
ALTER TABLE imported_data 
	ALTER date_revision_notice DROP DEFAULT,
	ALTER date_revision_notice TYPE timestamp USING date_revision_notice::timestamp;

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET auteur_transcription = TRIM(auteur_transcription);

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

-- Fonction utilitaire : extrait l'id de la cote (MX-F-<id>)
CREATE OR REPLACE FUNCTION cote_to_id(cote text)
RETURNS int AS $$
BEGIN
	RETURN CAST((regexp_split_to_array(TRIM(cote), 'MX-F-'))[2] AS int);
END;
$$ LANGUAGE plpgsql;

SELECT localisation, editeur FROM imported_data;
SELECT editeur FROM imported_data;

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

/*CREATE OR REPLACE FUNCTION parse_format(format text, dt text)
RETURNS text[] AS $$
DECLARE
	output text[]
BEGIN
	regexp_split_to_array(editeur, 'Responsable del archivo\s*:{0,1}\s*'))[2])
END;
$$ LANGUAGE plpgsql;*/

-- Supprime le début de la ligne
SELECT parse_editeur();

SELECT DISTINCT(notes) FROM imported_data;
SELECT cote, notes FROM imported_data WHERE notes='El archivo original se llama:5.jpg';
SELECT format FROM imported_data WHERE format ~ '(.*)(\d+\s*[x×X]\s*\d+)(.*)'; --regexp_matches(format, '.*(\d+\s*[x×]\s*\d+).*')
