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
	contexte_egographique text,
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

COPY imported_data
FROM E'E:\\Esp-fotos.csv'
DELIMITER ';'
CSV HEADER;

-- NETTOYAGE DE LA TABLE

UPDATE imported_data SET cote = TRIM(cote);

UPDATE imported_data SET type = TRIM(type);

UPDATE imported_data SET datatype = UPPER(TRIM(datatype));

UPDATE imported_data SET dates = TRIM(dates);
UPDATE imported_data SET dates = null WHERE LOWER(dates)='desconocido' or LOWER(dates)='indeterminado' or LOWER(dates)='gunther gerzso' or LOWER(dates)='victorio macho';
UPDATE imported_data SET dates = '1906-1920' WHERE cote='MX-F-20';
UPDATE imported_data SET dates = '1950-1970' WHERE cote='MX-F-132';
UPDATE imported_data SET dates = '1996' WHERE cote='MX-F-33';
UPDATE imported_data SET dates = '1980-2000' WHERE cote='MX-F-1042';
UPDATE imported_data SET dates = '1910-1940' WHERE cote='MX-F-1063';
UPDATE imported_data SET dates = '1910-1925' WHERE cote='MX-F-30';

UPDATE imported_data SET titre = 'Magarita Xirgu' WHERE cote='MX-F-20';

UPDATE imported_data SET date_analyse = TRIM(BOTH '$' FROM date_analyse);
UPDATE imported_data SET date_creation_notice = TRIM(BOTH '$' FROM date_analyse);

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

-- Certains formats sont indéterminés, on les remplace par NULL
UPDATE imported_data SET format=NULL WHERE format='Indeterminado';
-- On supprime les formats erronnés. La colonne format ne définit pas le format de fichier (doublon avec nature_document).
UPDATE imported_data SET format=NULL WHERE LOWER(format) ~ '(jp[e]{0,1}g|png|pdf)';
-- Format invalide, juste du texte, dupliqué de notes
UPDATE imported_data SET format=NULL WHERE cote='MX-F-247';

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
