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
/*
On retire les caractères en trop avant et après le type.
Lorsque la cote commence par "MX-F" on passe alors le type en "Fotos"
*/
UPDATE imported_data SET type=TRIM(type);
UPDATE imported_data SET type='Fotos' WHERE SUBSTRING(cote,0,5)='MX-F';

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

-- Test, on vérifie bien que seuls un enregistrement a un sous-titre.
SELECT COUNT(sous_titre)=1 FROM imported_data;

------------------------------------------------AUTEUR------------------------------------------------

/*
On retire les caractères en trop avant et après l'auteur.
On passe à "NULL" tous les auteurs inconnus
*/
UPDATE imported_data SET auteur=TRIM(auteur);
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
UPDATE imported_data SET auteur=regexp_replace(auteur, '\.$', ''); -- Certains enregistrements ont un auteur qui finit par ".". On le supprime.
UPDATE imported_data SET auteur='Revista Mundo Nuevo' WHERE LOWER(auteur)='nuevo mundo' OR LOWER(auteur)='nuevo mundo revista';

------------------------------------------------DESTINATAIRE------------------------------------------------

-- Il n'y a pas de destinataires

------------------------------------------------SUJET------------------------------------------------

/*
On retire les caractères en trop avant et après le sujet.
Correction d'une erreur pour "MX-F-185"
*/
UPDATE imported_data SET sujet=TRIM(sujet);
--Caractères blancs au début (codes ASCII 0xC2, 0xAO et 0x20), que TRIM n'arrive pas à enlever.
UPDATE imported_data SET sujet=trim_blank(sujet);
UPDATE imported_data SET sujet='Margarita xirgu' WHERE cote='MX-F-185';

------------------------------------------------DESCRIPTION------------------------------------------------

/*
On retire les caractères en trop avant et après la description.
*/
UPDATE imported_data SET description=TRIM(description);
-- Caractères blancs au début (codes ASCII 0xC2, 0xAO, 0x20 et 0x0A), que TRIM n'arrive pas à enlever.
UPDATE imported_data SET description=trim_blank(description);
UPDATE imported_data SET description=NULL WHERE char_length(description)=0;
UPDATE imported_data SET description=regexp_replace(description, '^-[[:blank:]]*', '');

-- SELECT description, COUNT(auteur_description) FROM imported_data GROUP BY description HAVING COUNT(DISTINCT auteur_description) != 1;
-- SELECT * FROM imported_data WHERE description='Foto de Margarita Xirgu sacada en el "peristilo" del teatro romano de Mérida, caracterizada de Elektra';

------------------------------------------------NOTES------------------------------------------------

/*
On retire les caractères en trop avant et après les notes.
Passe de la valeur "type" de "AS-AA1-01" dans notes
*/
UPDATE imported_data SET notes=TRIM(notes);
UPDATE imported_data SET notes = (SELECT type FROM imported_data WHERE cote ='AS-AA1-01')||' | '||(SELECT notes FROM imported_data WHERE cote ='AS-AA1-01') WHERE cote ='AS-AA1-01';

------------------------------------------------RESUME------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
*/
UPDATE imported_data SET resume=TRIM(resume);

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
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela) Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo  Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela)Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo Indeterminadospectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo IndeterminadoEditor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Indeterminado Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=REPLACE(editeur, 'Responsable del archivo  Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)', 'Responsable del archivo Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona.Editor Proyecto e-spectateur AAP 2020 (Responsable científico Alumno Alan Gil Master LEA Amérique La Rochelle Université)');
UPDATE imported_data SET editeur=TRIM(editeur);

------------------------------------------------LOCALISATION------------------------------------------------

/*
On retire les caractères en trop avant et après le mot.
On passe les localisations inconnues à "NULL".
Correction des erreurs pour certaines localisations.
*/
UPDATE imported_data SET localisation=TRIM(localisation);
UPDATE imported_data SET localisation=NULL WHERE LOWER(localisation)='desconocido' OR LOWER(localisation)='indeterminado';
UPDATE imported_data SET localisation='Punta Ballena' WHERE localisation=' Punta Ballena (Maldonado) Uruguay' OR localisation='Punta Ballena Uruguay';
UPDATE imported_data SET localisation='Teatro Solís, Montevideo' WHERE localisation='Teatro Solís, Montevideo (Uruguay)';
-- Suppression du point à la fin du texte
UPDATE imported_data SET localisation='EMAD: Escuela Municipal de Arte Dramático de Montevideo' WHERE localisation='EMAD: Escuela Municipal de Arte Dramático de Montevideo.';
UPDATE imported_data SET localisation='Madrid' WHERE localisation='Madrid' OR localisation='Madrid España';
UPDATE imported_data SET localisation='Mérida' WHERE localisation='Merida' OR localisation='Mérida' OR localisation='Merida España' OR localisation='Meridaa';
UPDATE imported_data SET localisation=regexp_replace(localisation, '[[:blank:]]+España$', '');
-- "MX-F-449" a une localisation qui est erronnée (c'est la description, dupliquée).
UPDATE imported_data SET localisation=NULL WHERE localisation='figura de cera de Margarita Xirgu';

------------------------------------------------DROITS------------------------------------------------
/*
On retire les caractères en trop avant et après les droits.
Correction des erreurs pour certains droits.
*/
UPDATE imported_data SET droits=TRIM(droits);
UPDATE imported_data SET droits='Archives familiar de Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)' WHERE droits='Archives familiales Margarita Xirgu – Licencia Licencia Creative Commons CC-BY-NC-ND (Attribution-Non Commercial-No Derivatives 4.0 International)';
-- Supprime les éventuels caractères '$' à la fin du texte.
UPDATE imported_data SET droits=regexp_replace('\$+$', '');

------------------------------------------------AYANTS-DROIT------------------------------------------------

/*
On retire les caractères en trop avant et après les ayants-droit.
*/
UPDATE imported_data SET ayants_droit=TRIM(ayants_droit);

-- Aucune donnée

------------------------------------------------FORMAT------------------------------------------------

/*
On retire les caractères en trop avant et après le format.
On passe les formats indéterminés à "NULL".
On supprime les formats erronnés. La colonne format ne définit pas le format de fichier (doublon avec nature_document).
Correction des erreurs sur "MX-F-247", dupliqué de notes
*/
UPDATE imported_data SET format=TRIM(format);
UPDATE imported_data SET format=NULL WHERE format='Indeterminado';
-- On supprime les extensions de fichier (avec ou sans point) dans la colonne format car doublon et non consistent.
UPDATE imported_data SET format=regexp_replace(LOWER(format), '[[:blank:]]*\.{0,1}(j[[:blank:]]{0,1}p[e]{0,1}g|png|pdf)[[:blank:]]*$', '');
-- Si certains formats sont vides, on les met à NULL. Important après l'opération précédente.
UPDATE imported_data SET sous_titre=NULL WHERE char_length(sous_titre)=0;
-- Texte dans le format qui est le même que dans notes.
UPDATE imported_data SET format=NULL WHERE cote='MX-F-247';


SELECT DISTINCT(format) FROM imported_data;
SELECT regexp_matches(LOWER('640 × 454 49,5 ko'), '(\d{2,4}[[:blank:]]*[x×][[:blank:]]*\d{2,4})[[:blank:]]*(\d{1,2}[\.,]{0,1}[kmg]o)$');
SELECT regexp_matches(LOWER('640 × 454 49,5'), '(\d{2,3}[[:blank:]]*[x×][[:blank:]]*\d{2,3})[[:blank:]]*(\d{1,2}([\.\,][[:blank:]]*[kmg]?o)?)$');
/*
On retire les caractères en trop avant et après la langue.
*/
UPDATE imported_data SET langue=TRIM(LOWER(langue));

/*
On retire les caractères en trop avant et après l'état génétique..
*/
UPDATE imported_data SET etat_genetique=TRIM(etat_genetique);

/*
On retire les caractères en trop avant et après le mot ainsi que les "$".
Correction des erreurs pour certaines relations génétiques.
*/
UPDATE imported_data SET relations_genetiques=TRIM(relations_genetiques);
UPDATE imported_data SET relations_genetiques=REPLACE(relations_genetiques, '$', '');
UPDATE imported_data SET relations_genetiques='MX-579/612/827/828/829/83/831/832/833/834/835/836' WHERE relations_genetiques='Mx-579-Mx-612/827/828/829/830/831/832/833/83/835/836';
UPDATE imported_data SET relations_genetiques='Mx-603/651' WHERE relations_genetiques='MX-603/M-651' OR relations_genetiques='Mx-603/Mx651';
UPDATE imported_data SET relations_genetiques='Mx-971/972/73/974/975/976/977/978' WHERE relations_genetiques='Mx-971/972/73/974/975/976/977978';

/*
On retire les caractères en trop avant et après les autres relations.
*/
UPDATE imported_data SET autres_ressources_relation=TRIM(autres_ressources_relation);

/*
On retire les caractères en trop avant et après la nature du document.
Correction des erreurs pour certaines nature de document + simplification du nom.
*/
UPDATE imported_data SET nature_document=UPPER(nature_document);
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
UPDATE imported_data SET support=TRIM(UPPER(support));

/*
On retire les caractères en trop avant et après le mot.
On passe les états indéfinis à "NULL".
Correction des erreurs pour certains états.
*/
UPDATE imported_data SET etat_general=TRIM(LOWER(etat_general));
-- Français -> Espagnol
UPDATE imported_data SET etat_general='mediocre' WHERE LOWER(etat_general)='médiocre';
UPDATE imported_data SET etat_general=NULL WHERE LOWER(etat_general)='indeterminado';


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

CREATE OR REPLACE FUNCTION trim_blank(t text)
RETURNS text AS $$
DECLARE
	t_returned text;
BEGIN
	t_returned := regexp_replace(t, '^[\xC2\xA0\x20\x0A]*', '');
	IF char_length(t_returned)=0
	THEN
		RETURN NULL;
	ELSE
		RETURN t_returned;
	END IF;
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
								       
								       ----------------------- GESTION EDITEUR -----------------------

DROP TABLE IF EXISTS editeur, responsable_archive, responsable_scientifique, personne;
CREATE TABLE editeur (
	id_editeur serial primary key,
	nom_editeur varchar(150)
);

CREATE TABLE responsable_archive (
	id_reponsable_archive serial primary key,
	nom varchar(150)
);

CREATE TABLE personne (
	id_personne serial primary key,
	nom varchar(50),
	prenom varchar(50)
);

CREATE TABLE responsable_scientifique (
	id_reponsable integer,
	localisation varchar(150),
	statut varchar(150),
	poste varchar(150),
	PRIMARY KEY (id_reponsable),
	FOREIGN KEY (id_reponsable) REFERENCES personne(id_personne)
);

INSERT INTO personne(nom,prenom) VALUES ('Gil','Alan');
INSERT INTO personne(nom,prenom) VALUES ('Chantraine Braillon','Cécile');
INSERT INTO personne(nom,prenom) VALUES ('Idmhand','Fatiha');

INSERT INTO responsable_scientifique VALUES (1, 'La Rochelle Université', 'Alumno', 'Master LEA Amérique');
INSERT INTO responsable_scientifique VALUES (2, 'La Rochelle Université', 'Profesor', 'Equipo CRHIA');
INSERT INTO responsable_scientifique VALUES (3, 'La Rochelle Université', 'Profesor', 'CRLA Institut des textes et manuscrits modernes CNRS-UMR8132');

INSERT INTO editeur(nom_editeur) VALUES ('Editor Proyecto e-spectateur AAP 2020 '),('Editor Proyecto CollEx-Persée Archivos 3.0 AAP 2018 ');

INSERT INTO responsable_archive(nom) VALUES
('Familia de Maragrita Xirgu (fondo de los hermanos Xiru)'),('Albert Prats'),('Departamento de Cultura de la Generalidad de Cataluña '),
('Fondo Margarita Xirgu del Instituto del Teatro de la Diputación de Barcelona'),('Foto Escena Catalana'),
('MAE Barcelona'),('Arxiu Marta Prats Xirgu'),('Francesc Foguet i Boreu'),('Dr Sylvie Josserand Colla (Equipo Archivos-CRLA Institut des textes et manuscrits modernes CNRS-UMR8132)'),
('La Vanguardia'), ('Familia Margarita Xirgu (Xavier Rius Xirgu Ester Xirgu Cortacans Natalia Valenzuela)'),
('El Instituto del Teatro de la Diputación de Barcelona'),('Familia Margarita Xirgu (Fondo Jordi Rius Xirgu)'),
('Teatro de Barcelona'),('Amadeu Mariné Vadalaco'), ('Antonina Rodrigo'),('Antonio y Ramon Clapés'),('Biblioteca Sebastiá Juan Arbó'),
('Carmen M.Gual'),('Colección de escenografía del Instituto del Teatro de la Diputación de Barcelona'),
('Festival de Mérida'),('Foto Archivo Xavier Rius Xirgu'),('Fotos de su nieto Jaime Gutiérrez Morcillo'),
('José Antonio'),('Lluis Andú');
								       
								       
								       ----------------------- GESTION DATATYPE et SUPPORT -----------------------
DROP TABLE IF EXISTS support, datatype;
CREATE TABLE support (
	nom_support varchar(10) primary key
);

CREATE TABLE datatype (
	nom_datatype varchar(50),
	nom_support varchar(10),
	PRIMARY KEY (nom_datatype,nom_support),
	FOREIGN KEY (nom_support) REFERENCES support(nom_support)
);

INSERT INTO support VALUES ('DIGITAL'),('PAPEL');
INSERT INTO datatype VALUES ('imagen','DIGITAL'),('text','PAPEL');
