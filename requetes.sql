------------------------------------------------ TRIGGERS ------------------------------------------------

CREATE OR REPLACE FUNCTION trigger_document_log() RETURNS TRIGGER
AS $$
DECLARE
BEGIN

  RAISE NOTICE 'Le nouveau document à pour id: %, sa représentation est %, il a été analysé le %', NEW.id_document, NEW.representation, NEW.date_analyse;
  RETURN NEW;
END;
  $$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_document_log BEFORE INSERT OR UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE trigger_document_log();

/*
Vérification de format valide de langue et supression de caractères invalides
 */
DROP FUNCTION IF EXISTS trigger_langue_validate() CASCADE;
CREATE OR REPLACE FUNCTION trigger_langue_validate() RETURNS TRIGGER
AS $$
DECLARE
  code langue.code%TYPE;
BEGIN
  code := trim_blank(UPPER(NEW.code));
  IF NOT regexp_matches(code, '\w{3}') THEN
    RAISE EXCEPTION 'Format de code ISO 3166-1 invalide : %', code;
  END IF;
  NEW.code = code;
  RETURN NEW;
END;
  $$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_langue_validate BEFORE INSERT OR UPDATE ON langue FOR EACH ROW EXECUTE PROCEDURE trigger_langue_validate();


/*
Quand un utilisateur insère ou modifie le support d'un document, on met le nom en majuscule pour que cela corresponde au format.
 */
DROP FUNCTION IF EXISTS trigger_support_validate() CASCADE;
CREATE OR REPLACE FUNCTION trigger_support_validate() RETURNS TRIGGER
AS $$
BEGIN
  NEW.nom = trim_blank(UPPER(NEW.nom));
  RETURN NEW;
END;
  $$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_support_validate BEFORE INSERT OR UPDATE ON support FOR EACH ROW EXECUTE PROCEDURE trigger_support_validate();


/*
trigger_document_revision insère une nouvelle entrée dans la table document_revision correspondant à la modification d'un document
ou d'une table associée à document.

La date est mise à la date actuelle.
 */
CREATE OR REPLACE FUNCTION trigger_document_revision() RETURNS TRIGGER
AS $$
BEGIN
    INSERT INTO document_revision VALUES (NEW.id_document, NOW());
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_droits FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_contexte_geo FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON localisation FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_datatype FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_etat_general FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON autres_relations FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON etat_genetique FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON notes FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON resume FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON publication FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON titre FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_type FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document_support FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();
CREATE TRIGGER trigger_document_revision AFTER UPDATE ON document FOR EACH ROW EXECUTE PROCEDURE trigger_document_revision();


/*
Si l'utilisateur insère une révision manuelle du document, on doit s'assurer que la date entrée n'est pas dans le passé.

Cela ne s'applique que pour les insertions.
 */
DROP FUNCTION IF EXISTS trigger_manual_document_revision() CASCADE;
CREATE OR REPLACE FUNCTION trigger_manual_document_revision() RETURNS TRIGGER
AS $$
BEGIN
    IF NOW()::timestamp - NEW.date_revision_notice  < interval '0s'
    THEN
      RAISE EXCEPTION 'Vous ne pouvez pas insérer une date dans le passé !';
      RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';
CREATE TRIGGER trigger_manual_document_revision BEFORE INSERT ON document_revision FOR EACH ROW EXECUTE PROCEDURE trigger_manual_document_revision();



/*
Quand un utilisateur insère ou modifie l'état général d'un document, on met le nom en minuscule pour que cela corresponde au format.
 */
DROP FUNCTION IF EXISTS trigger_etat_general_validate() CASCADE;
CREATE OR REPLACE FUNCTION trigger_etat_general_validate() RETURNS TRIGGER
AS $$
BEGIN
    NEW.nom = trim_blank(LOWER(NEW.nom));
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_etat_general_validate BEFORE INSERT OR UPDATE ON etat_general FOR EACH ROW EXECUTE PROCEDURE trigger_etat_general_validate();

/*
Quand un utilisateur insère ou modifie la nature d'un document, on met le nom en majuscule pour que cela corresponde au format.
 */
DROP FUNCTION IF EXISTS trigger_nature_document_validate() CASCADE;
CREATE OR REPLACE FUNCTION trigger_nature_document_validate() RETURNS TRIGGER
AS $$
BEGIN
    NEW.nom = trim_blank(UPPER(NEW.nom));
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_nature_document_validate BEFORE INSERT OR UPDATE ON nature_document FOR EACH ROW EXECUTE PROCEDURE trigger_nature_document_validate();					


------------------------------------------------ REQUÊTES ------------------------------------------------

--- 1 : On récupère l'état en anglais des documents par ordre croissant d'état.
SELECT A.id_document, C.nom
FROM document A
JOIN document_etat_general B ON B.id_document = A.id_document
JOIN etat_general C ON C.id_etat_general=B.id_etat_general
WHERE C.code='ENG'
ORDER BY C.nom;

--- 2 : On récupère la date des documents ainsi que le lieu où la photo a été prise par ordre croissant de date.
SELECT A.id_document, A.dates, C.nom, C.lat, C.lon
FROM document A
JOIN document_contexte_geo B ON B.id_document = A.id_document
JOIN contexte_geo C ON C.id_contexte_geo = B.id_contexte_geo
WHERE C.code='SPA' and A.dates IS NOT null
ORDER BY A.dates;

-- 3 : On récupère les documents analysés par Mme. Chantraine Braillon, Cécile ainsi que la date d'analyse de ces documents
SELECT A.id_document, B.nom, A.date_analyse
FROM document A
JOIN personne B ON B.id_personne = A.id_auteur_analyse
WHERE B.nom = 'Chantraine Braillon, Cécile';

-- 4 : On récupère le nombre de datatype (espagnol) qui ont été utilisé dans notre BDD 
SELECT A.nom, count(*)
FROM datatype A
JOIN document_datatype B ON B.id_datatype = A.id_datatype
WHERE A.code = 'SPA' and B.code='SPA'
GROUP BY A.nom;

-- 5 : On récupère le nombre de type (espagnol) qui ont été utilisé dans notre BDD 
SELECT A.nom, count(*)
FROM type A
JOIN document_type B ON B.id_type = A.id_type
WHERE A.code = 'SPA' and B.code='SPA'
GROUP BY A.nom;

-- 6 : On récupère le nombre de datatype (anglais) qui ont été utilisé dans notre BDD 
SELECT A.nom, count(*)
FROM datatype A
JOIN document_datatype B ON B.id_datatype = A.id_datatype
WHERE A.code = 'ENG' and B.code='ENG'
GROUP BY A.nom;

-- 7 : On récupère le nombre de type (anglais) qui ont été utilisé dans notre BDD 
SELECT A.nom, count(*)
FROM type A
JOIN document_type B ON B.id_type = A.id_type
WHERE A.code = 'ENG'
GROUP BY A.nom;

-- 8 : On récupère le titre, l'auteur et les notes associées aux documents 
SELECT A.id_document, C.nom as titre, A.nom as auteur, A.texte as notes
FROM notes A
JOIN titre C ON C.id_document = A.id_document and C.code = 'SPA'
ORDER BY A.id_document;


-- 9 : Nombre d'oeuvres analysées par année
SELECT date_part('year', A.date_analyse), COUNT(*)
FROM document A
GROUP BY date_part('year', A.date_analyse);

-- 10 : Nombre d'oeuvres par localisation
SELECT A.nom, count(*)
FROM localisation A
WHERE A.code = 'ENG'
GROUP BY A.nom
ORDER BY count(*) DESC;

-- 11 : Les oeuvres qui n'ont pas de localisation connue
SELECT A.id_document, A.date_analyse
FROM document A
WHERE A.id_document NOT IN
(
	SELECT B.id_document
	FROM localisation B 
)
ORDER BY A.id_document;

-- 12 : Nombre de descriptions écrites par chaque auteur
SELECT B.nom, count(*)
FROM description A
JOIN auteur_description B ON B.id_auteur_description = A.id_auteur_description
WHERE A.code='ENG'
GROUP BY B.nom
ORDER BY count(*) DESC;
			       
-- 13 : Nombre de titres non traduits dans une autre langue qu'espagnol
SELECT COUNT(t1.id_document) FROM titre t1 WHERE t1.code='SPA' AND NOT EXISTS (SELECT 1 FROM titre t2 WHERE t2.id_document=t1.id_document AND t2.code != 'SPA');

-- 14 : Editeur les plus actifs (du plus actif au moins actif)
SELECT E.id_editeur, EN.nom_editeur, COUNT(D.id_document) AS nb_documents FROM editeur E INNER JOIN editeur_nom EN on E.id_editeur = EN.id_editeur INNER JOIN document D on E.id_editeur = D.id_editeur WHERE EN.code='SPA' GROUP BY E.id_editeur, EN.nom_editeur ORDER BY nb_documents DESC;

-- 15 : Id et noms (en espagnol) des contextes géographiques les mieux couverts
SELECT C.id_contexte_geo, C.nom, COUNT(DCG.id_document) AS nb_documents FROM document_contexte_geo DCG LEFT JOIN contexte_geo C ON DCG.id_contexte_geo = C.id_contexte_geo WHERE C.code='SPA' GROUP BY C.id_contexte_geo, C.nom ORDER BY nb_documents DESC;

-- 16 : Nombre de révisions moyen par document. Attention : pour l'instant document_revision est vide, il n'y a donc pas de résultats
SELECT AVG(sub.nb_revisions) FROM (SELECT COUNT(R.id_document) AS nb_revisions FROM document_revision R GROUP BY R.id_document) AS sub;

-- 17 : Les mois (avec l'année) les plus productions par ordre décroissants par rapport à la date d'analyse
SELECT date_trunc('month', A.date_analyse) AS month, COUNT(A.id_document) AS nb_documents FROM document A GROUP BY month ORDER BY nb_documents DESC;
					 
