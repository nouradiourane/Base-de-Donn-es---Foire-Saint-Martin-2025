---
--- 1. Création des tables avec contraintes
---

CREATE TABLE FORAIN (
    nom VARCHAR(50),
    prenom VARCHAR(50),
    age INT,
    prempart INT,
    CONSTRAINT pk_forain PRIMARY KEY (nom, prenom)
);

CREATE TABLE ATTRACTION (
    numero SERIAL PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    nbplaces INT NOT NULL,
    categorie VARCHAR(20) CHECK (categorie IN ('manège', 'jeu de hasard', 'gourmandise')),
    nomforain VARCHAR(50),
    prenomforain VARCHAR(50),
    CONSTRAINT fk_attrac_forain FOREIGN KEY (nomforain, prenomforain) 
        REFERENCES FORAIN(nom, prenom) ON UPDATE CASCADE ON DELETE RESTRICT
);

ALTER SEQUENCE attraction_numero_seq RESTART WITH 101;

CREATE TABLE EMPLACEMENT (
    numero SERIAL PRIMARY KEY,
    surface INT,
    secteur VARCHAR(10) CHECK (secteur IN ('sud', 'nord', 'ouest', 'est')),
    nomforain VARCHAR(50),
    prenomforain VARCHAR(50),
    CONSTRAINT fk_empl_forain FOREIGN KEY (nomforain, prenomforain) 
        REFERENCES FORAIN(nom, prenom) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE OCCUPATION (
    numattrac INT,
    numempl INT,
    CONSTRAINT pk_occupation PRIMARY KEY (numattrac, numempl),
    CONSTRAINT fk_occ_attrac FOREIGN KEY (numattrac) REFERENCES ATTRACTION(numero) ON DELETE RESTRICT,
    CONSTRAINT fk_occ_empl FOREIGN KEY (numempl) REFERENCES EMPLACEMENT(numero) ON DELETE RESTRICT
);

---
--- 2. Insertion des données d'exemple
---

INSERT INTO FORAIN VALUES ('DUPONT', 'Antoine', 29, 2017);
INSERT INTO FORAIN VALUES ('RAMOS', 'Thomas', 30, 2019);
INSERT INTO FORAIN VALUES ('BLANCO', 'Serge', 12, 1980);

INSERT INTO ATTRACTION (nom, nbplaces, categorie, nomforain, prenomforain) VALUES 
('Le Looping infernal', 40, 'manège', 'RAMOS', 'Thomas'),
('La Réglisse magique', 10, 'gourmandise', 'DUPONT', 'Antoine'),
('Les Autos-tamponneuses volantes', 20, 'manège', 'DUPONT', 'Antoine');

INSERT INTO EMPLACEMENT (surface, secteur, nomforain, prenomforain) VALUES 
(40, 'sud', 'BLANCO', 'Serge'),
(100, 'ouest', 'DUPONT', 'Antoine');

INSERT INTO OCCUPATION VALUES (101, 2);


-- 3. Modifier l'âge de Serge Blanco
UPDATE FORAIN SET age = 67 WHERE nom = 'BLANCO' AND prenom = 'Serge';

-- 4. Ajouter "jeu manuel" aux catégories
ALTER TABLE ATTRACTION DROP CONSTRAINT attraction_categorie_check;
ALTER TABLE ATTRACTION ADD CONSTRAINT attraction_categorie_check 
    CHECK (categorie IN ('manège', 'jeu de hasard', 'gourmandise', 'jeu manuel'));

-- 5. Insérer l'emplacement pour Pierre BERBIZIER
-- Il faut d'abord créer le forain car il est référencé par la clé étrangère
INSERT INTO FORAIN (nom, prenom) VALUES ('BERBIZIER', 'Pierre');
INSERT INTO EMPLACEMENT (surface, secteur, nomforain, prenomforain) 
    VALUES (NULL, 'ouest', 'BERBIZIER', 'Pierre');

-- 6. Insertion occupation spécifique
INSERT INTO OCCUPATION (numattrac, numempl)
SELECT a.numero, e.numero 
FROM ATTRACTION a, EMPLACEMENT e 
WHERE a.nom = 'La Réglisse magique' 
AND e.surface = 40 AND e.secteur = 'sud' AND e.nomforain = 'BLANCO';

-- 7. Insertion Carabine Tordue
INSERT INTO ATTRACTION (nom, nbplaces, categorie, nomforain, prenomforain)
VALUES ('La carabine tordue', 1, 'jeu manuel', 'BLANCO', 'Serge');
-- Explication : Cela fonctionne car nous avons ajouté 'jeu manuel' à la contrainte CHECK à la question 4.

-- 8. Supprimer Antoine DUPONT
-- DELETE FROM FORAIN WHERE nom = 'DUPONT' AND prenom = 'Antoine';
-- Explication : Erreur  La suppression est interdite (ON DELETE RESTRICT) car il est référencé dans ATTRACTION.

---
--- 9 à 13. Vues (Views)
---

-- 9. Vue MANEGE
CREATE VIEW MANEGE AS 
SELECT nom FROM ATTRACTION WHERE categorie = 'manège';

-- 10. EMPLACEMENT_JEUNE
CREATE VIEW EMPLACEMENT_JEUNE AS
SELECT DISTINCT e.numero, f.nom, f.prenom
FROM EMPLACEMENT e
JOIN OCCUPATION o ON e.numero = o.numempl
JOIN ATTRACTION a ON o.numattrac = a.numero
JOIN FORAIN f ON a.nomforain = f.nom AND a.prenomforain = f.prenom
WHERE f.age < 30;

-- 11. NB_ATTRACTION_FORAIN
CREATE VIEW NB_ATTRACTION_FORAIN AS
SELECT nomforain, prenomforain, COUNT(*) as nb_attractions
FROM ATTRACTION
GROUP BY nomforain, prenomforain;

-- 12. MAX_ATTRACTION_FORAIN
CREATE VIEW MAX_ATTRACTION_FORAIN AS
SELECT nomforain, prenomforain
FROM NB_ATTRACTION_FORAIN
WHERE nb_attractions = (SELECT MAX(nb_attractions) FROM NB_ATTRACTION_FORAIN);

-- 13. ATTRACTION_TOUT_FORAIN (Bonus)
CREATE VIEW ATTRACTION_TOUT_FORAIN AS
SELECT f.nom, f.prenom, a.nom AS nom_attraction
FROM FORAIN f
LEFT JOIN ATTRACTION a ON f.nom = a.nomforain AND f.prenom = a.prenomforain;
