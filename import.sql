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

-- Exploration
SELECT cote, __dummy FROM imported_data WHERE __dummy IS NOT NULL;
SELECT * FROM imported_data;
SELECT COUNT(*) FROM imported_data;

-- Fonction utilitaure : extrait l'id de la cote (MX-F-<id>)
CREATE OR REPLACE FUNCTION cote_to_id(cote text)
RETURNS int AS $$
BEGIN
	RETURN CAST((regexp_split_to_array(TRIM(cote), 'MX-F-'))[2] AS int);
END;
$$ LANGUAGE plpgsql;

SELECT COUNT(DISTINCT datatype), COUNT(datatype) FROM imported_data;
SELECT COUNT(datatype) FROM imported_data WHERE datatype IS NULL;