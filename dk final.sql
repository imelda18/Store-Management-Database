--KATEGORIA--
CREATE TABLE Kategoria (
    categoryID NUMBER ,
    categoryName VARCHAR2(20) NOT NULL,
    CONSTRAINT kategoria_id_pk PRIMARY KEY (categoryID),
    CONSTRAINT kategoria_name_uk UNIQUE (categoryName)   
);

----ARTIKUJT ----
CREATE TABLE Artikull (
    articleID NUMBER ,
    articleName VARCHAR2(100) NOT NULL,
    categoryID NUMBER ,
    price NUMBER,
    CONSTRAINT artikull_pk  PRIMARY KEY(articleID),
    CONSTRAINT kategoria_fk FOREIGN KEY (categoryID) REFERENCES Kategoria(categoryID)
    
);


---FURNITOR -----------
CREATE TABLE Furnitor (
    NIPT VARCHAR2(10),
    furnitorName VARCHAR2(100) NOT NULL,
    address VARCHAR2(200),
    contact VARCHAR2(50),
    CONSTRAINT furnitor_pk  PRIMARY KEY(NIPT)
);


---FURNIZIME----------
CREATE TABLE Furnizime (
    furnizimID NUMBER,
    furnizimData DATE NOT NULL,
    furnitorNIPT VARCHAR2(10) NOT NULL,
    CONSTRAINT furnizim_pk  PRIMARY KEY(furnizimID),
    CONSTRAINT furnizime_furnitor_fk FOREIGN KEY (furnitorNIPT) REFERENCES Furnitor(NIPT)

);

-- FURNIZIME ARTIKUJ-----------
CREATE TABLE Furnizime_Artikuj (
    furnizimID NUMBER,
    articleID NUMBER,
    quantity NUMBER,
    price NUMBER,
    CONSTRAINT furnizime_artikuj_pk PRIMARY KEY (furnizimID, articleID),
    CONSTRAINT furnizime_artikuj_furnizim_fk FOREIGN KEY (furnizimID) REFERENCES Furnizime(furnizimID),
    CONSTRAINT furnizime_artikuj_artikull_fk FOREIGN KEY (articleID) REFERENCES Artikull(articleID)
);

-- --MAGAZINA-------
CREATE TABLE Magazina (
    articleID NUMBER,
    quantity NUMBER,
     CONSTRAINT magazina_pk PRIMARY KEY (articleID),
    CONSTRAINT magazina_article_fk FOREIGN KEY (articleID) REFERENCES Artikull(articleID)
);

-- KLIENTI-------
CREATE TABLE Klienti (
    klientID NUMBER,
    fullname VARCHAR2(50) NOT NULL,
    nrTel VARCHAR2(20),
    adresa VARCHAR2(200),
    CONSTRAINT klienti_pk  PRIMARY KEY(klientID)
);
---KARTA E ANTARESISE ----
CREATE TABLE Karta_Anetaresimi (
    kartaID NUMBER ,
    klientID NUMBER,
    points NUMBER DEFAULT 0,
    CONSTRAINT karta_pk  PRIMARY KEY(kartaID),
    CONSTRAINT karta_klient_fk FOREIGN KEY (klientID) REFERENCES Klienti(klientID)
);

--SHITESI----------
CREATE TABLE Shitesi (
    shitesID NUMBER,
    fullName VARCHAR2(100) NOT NULL,
     CONSTRAINT shitesi_pk  PRIMARY KEY(shitesID)
);

----PIKE SHITJE -------
CREATE TABLE Pike_Shitje (
    pike_shitjeID NUMBER,
    name VARCHAR2(100) NOT NULL,
    CONSTRAINT pike_shitje_pk  PRIMARY KEY(pike_shitjeID)
);

--FLETE DALJE ------
CREATE TABLE FleteDalje (
    fleteID NUMBER ,
    klientID NUMBER,
    shitesID NUMBER,
    pike_shitjeID NUMBER,
    shitjeData DATE,
     CONSTRAINT flete_pk  PRIMARY KEY(fleteID),
     CONSTRAINT shitje_klient_fk FOREIGN KEY (klientID) REFERENCES Klienti(klientID),
     CONSTRAINT shitje_shites_fk FOREIGN KEY (shitesID) REFERENCES Shitesi(shitesID),
     CONSTRAINT shitje_pike_fk FOREIGN KEY (pike_shitjeID) REFERENCES Pike_Shitje( pike_shitjeID)
);

--FLETEDALJE DETAJE------------
CREATE TABLE FleteDalje_Detaje (
    fleteID NUMBER,
    articleID NUMBER,
    quantity NUMBER,
    unitPrice NUMBER(10, 2),
    CONSTRAINT fletedalje_detaje_pk PRIMARY KEY (fleteID, articleID),
    CONSTRAINT shitje_fk FOREIGN KEY (fleteID) REFERENCES FleteDalje(fleteID),
    CONSTRAINT artikull_detaje_fk FOREIGN KEY (articleID) REFERENCES Artikull(articleID)
);

----MBYLLJE AKTIVITETI DITOR ---------------

CREATE TABLE Mbyllje_Ditore (
    mbylljeID NUMBER ,
    pike_shitjeID NUMBER,
    shitesID NUMBER,
    data DATE,
    gjendjaArkesPara NUMBER(10, 2),
    gjendjaArkesPas NUMBER(10, 2),
    xhiro  NUMBER(10, 2),
    CONSTRAINT mbyllje_ditore_pk  PRIMARY KEY(mbylljeID),
    CONSTRAINT mbyllje_shites_fk FOREIGN KEY (shitesID) REFERENCES Shitesi(shitesID),
    CONSTRAINT pike_shitje_fk FOREIGN KEY (pike_shitjeID) REFERENCES Pike_Shitje(pike_shitjeID)
);

--TRIGGERAT---
--1.Trigger-i i cili parandalon shitjen e nje artikulli qe nuk ka sasi te mjaftueshme ne magazine.
    
    CREATE OR REPLACE TRIGGER prevent_zero_quantity_sale
    BEFORE INSERT ON FleteDalje_Detaje
    FOR EACH ROW
    DECLARE
     v_quantity NUMBER;
    BEGIN
     SELECT quantity INTO v_quantity FROM Magazina WHERE articleID = :NEW.articleID;
     IF v_quantity < :NEW.quantity THEN
     RAISE_APPLICATION_ERROR(-20001, 'Sasia e artikullit është 0 ose e pamjaftueshme.');
     END IF;
    END;
    /


--2. Trigger-i i cili update-on magazinen sa here qe ndodh nje furnizim
    
    CREATE OR REPLACE TRIGGER update_stock_on_supply
    AFTER INSERT ON Furnizime_Artikuj
    FOR EACH ROW
    BEGIN
     UPDATE Magazina
     SET quantity = quantity + :NEW.quantity
     WHERE articleID = :NEW.articleID;
    END;
    /


--3. Trigger-i i cili update-on magazinen sa here qe ndodh nje shitje
    
    CREATE OR REPLACE TRIGGER update_stock_on_sale
    AFTER INSERT ON FleteDalje_Detaje
    FOR EACH ROW
    BEGIN
     UPDATE Magazina
     SET quantity = quantity - :NEW.quantity
     WHERE articleID = :NEW.articleID;
    END;
    /
    
--    4. Trigger-i i cili update-on piket ne karten e klientit sa here qe ndodh nje shitje:

    CREATE OR REPLACE TRIGGER update_points_on_sale
    AFTER INSERT ON FleteDalje_Detaje
    FOR EACH ROW
    DECLARE
     v_klientID NUMBER;
     v_points NUMBER;
    BEGIN
     SELECT klientID INTO v_klientID FROM FleteDalje WHERE fleteID = :NEW.fleteID;
    --piket i llogarisin duke supozuar qe fiton aq pike sa leke ka shpenzuar
     v_points := :NEW.quantity * :NEW.unitPrice;
     UPDATE Karta_Anetaresimi
     SET points = points + v_points
     WHERE klientID = v_klientID;
    END;

---PROCEDURAT----
--1.Procedura per anluimin e furnizimit
   
    CREATE OR REPLACE PROCEDURE Anulo_Furnizim ( furnizimID_p IN NUMBER)
    IS
    BEGIN
     FOR supply_record IN (SELECT * FROM Furnizime_Artikuj WHERE furnizimID = 
    furnizimID_p) LOOP
     UPDATE Magazina
     SET quantity = quantity - supply_record.quantity
     WHERE articleID = supply_record.articleID;
     END LOOP;
     DELETE FROM Furnizime_Artikuj WHERE furnizimID = furnizimID_p;
     DELETE FROM Furnizime WHERE furnizimID = furnizimID_p;
     COMMIT;
    END;
    /

--2.Procedura per anluimin e blerjes
    
    CREATE OR REPLACE PROCEDURE Anulo_Blerje ( fleteID_p IN NUMBER)
    AS
     v_klientID NUMBER;
     v_points NUMBER;
    BEGIN
     SELECT klientID INTO v_klientID FROM FleteDalje WHERE fleteID = fleteID_p;
     FOR sale_record IN (SELECT * FROM FleteDalje_Detaje WHERE fleteID = fleteID_p) 
    LOOP
     UPDATE Magazina
     SET quantity = quantity + sale_record.quantity
     WHERE articleID = sale_record.articleID;
     END LOOP;
     SELECT SUM(quantity * unitPrice) INTO v_points FROM FleteDalje_Detaje
     WHERE fleteID = fleteID_p;
     UPDATE Karta_Anetaresimi
     SET points = points - v_points
     WHERE klientID = v_klientID;
     DELETE FROM FleteDalje_Detaje WHERE fleteID = fleteID_p;
     DELETE FROM FleteDalje WHERE fleteID = fleteID_p;
     COMMIT;
    END;
    /


