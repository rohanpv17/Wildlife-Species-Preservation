-- 1. Create the database first
CREATE DATABASE IF NOT EXISTS wild_db;

-- 2. IMPORTANT: Select the database to use
USE wild_db;

-- 3. Now, drop tables (if they exist) in the correct order
DROP TABLE IF EXISTS protected_by;
DROP TABLE IF EXISTS observations;
DROP TABLE IF EXISTS conservation_plan;
DROP TABLE IF EXISTS environmental_data;
DROP TABLE IF EXISTS species_preserves;
DROP TABLE IF EXISTS species;

-- 4. Create 'species' table
CREATE TABLE species (
    SP_ID VARCHAR(10) PRIMARY KEY,
    SP_NAME VARCHAR(100),
    CLASSIFICATION VARCHAR(100)
);

-- 5. Create 'species_preserves' table
CREATE TABLE species_preserves (
    P_ID VARCHAR(10) PRIMARY KEY,
    PLOC VARCHAR(255),
    PNAME VARCHAR(100),
    PECOSYSTEM VARCHAR(100),
    SP_ID VARCHAR(10),
    CONSTRAINT species_preserves_ibfk_1 
        FOREIGN KEY (SP_ID) REFERENCES species(SP_ID)
);

-- 6. Create 'environmental_data' table
CREATE TABLE environmental_data (
    DATA_ID VARCHAR(10) PRIMARY KEY,
    WATER_COND VARCHAR(100),
    WEATHERCOND VARCHAR(100),
    SOIL_COMP VARCHAR(100),
    AIRQUAL VARCHAR(100),
    P_ID VARCHAR(10),
    CONSTRAINT environmental_data_ibfk_1 
        FOREIGN KEY (P_ID) REFERENCES species_preserves(P_ID)
);

-- 7. Create 'conservation_plan' table
CREATE TABLE conservation_plan (
    PROJ_ID VARCHAR(10) PRIMARY KEY,
    PROJ_NAME VARCHAR(100),
    STRDATE DATE,
    END_DATE DATE,
    SP_ID VARCHAR(10),
    CONSTRAINT conservation_plan_ibfk_1 
        FOREIGN KEY (SP_ID) REFERENCES species(SP_ID)
);

-- 8. Create 'observations' table
CREATE TABLE observations (
    OBS_ID VARCHAR(10) PRIMARY KEY,
    OBS_DATE DATE,
    OBSTYPE VARCHAR(100),
    OBS_LOC VARCHAR(255),
    SP_ID VARCHAR(10),
    DATAID VARCHAR(10),
    CONSTRAINT observations_ibfk_1 
        FOREIGN KEY (SP_ID) REFERENCES species(SP_ID),
    CONSTRAINT observations_ibfk_2 
        FOREIGN KEY (DATAID) REFERENCES environmental_data(DATA_ID)
);

-- 9. Create 'protected_by' table
CREATE TABLE protected_by (
    SP_ID VARCHAR(10),
    PROJ_ID VARCHAR(10),
    CONSERVATION_STATUS VARCHAR(100),
    PRIMARY KEY (SP_ID, PROJ_ID),
    CONSTRAINT protected_by_ibfk_1 
        FOREIGN KEY (SP_ID) REFERENCES species(SP_ID),
    CONSTRAINT protected_by_ibfk_2 
        FOREIGN KEY (PROJ_ID) REFERENCES conservation_plan(PROJ_ID)
);

-- ---------------------------------
-- DML (Data Manipulation Language)
-- ---------------------------------

-- 1. Insert data into 'species'
INSERT INTO species (SP_ID, SP_NAME, CLASSIFICATION) VALUES
('S001', 'Amur Leopard', 'Mammal'),
('S002', 'Javan Rhino', 'Mammal'),
('S003', 'Hawksbill Sea Turtle', 'Reptile'),
('S004', 'Vaquita', 'Mammal');

-- 2. Insert data into 'species_preserves'
INSERT INTO species_preserves (P_ID, PLOC, PNAME, PECOSYSTEM, SP_ID) VALUES
('P01', 'Russia/China Border', 'Land of the Leopard National Park', 'Temperate Forest', 'S001'),
('P02', 'Java, Indonesia', 'Ujung Kulon National Park', 'Tropical Rainforest', 'S002'),
('P03', 'Global Tropical Oceans', 'Coral Reefs', 'Marine', 'S003'),
('P04', 'Gulf of California', 'Vaquita Refuge', 'Marine', 'S004');

-- 3. Insert data into 'environmental_data'
INSERT INTO environmental_data (DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL, P_ID) VALUES
('D01', 'Clean', 'Cold, Snowy Winters', 'Podzolic', 'Good', 'P01'),
('D02', 'Humid', 'Hot, Rainy', 'Volcanic', 'Moderate', 'P02'),
('D03', 'Saline', 'Warm, Tropical', 'N/A', 'Good', 'P03'),
('D04', 'High Salinity', 'Hot, Arid', 'N/A', 'Good', 'P04');

-- 4. Insert data into 'conservation_plan'
INSERT INTO conservation_plan (PROJ_ID, PROJ_NAME, STRDATE, END_DATE, SP_ID) VALUES
('CP01', 'Amur Leopard Conservation', '2010-01-01', '2030-12-31', 'S001'),
('CP02', 'Javan Rhino Protection', '2005-06-01', '2025-12-31', 'S002'),
('CP03', 'Turtle Reef Safeguard', '2015-01-01', '2035-01-01', 'S003'),
('CP04', 'Vaquita Gillnet Ban', '2017-07-01', '2027-07-01', 'S004');

-- 5. Insert data into 'observations'
INSERT INTO observations (OBS_ID, OBS_DATE, OBSTYPE, OBS_LOC, SP_ID, DATAID) VALUES
('O01', '2025-10-20', 'Camera Trap', '43.70° N, 131.50° E', 'S001', 'D01'),
('O02', '2025-10-21', 'Footprint Tracking', '6.75° S, 105.33° E', 'S002', 'D02'),
('O03', '2025-10-22', 'Dive Sighting', '19.69° N, 155.92° W', 'S003', 'D03'),
('O04', '2025-10-23', 'Acoustic Monitoring', '30.80° N, 114.60° W', 'S004', 'D04');

-- 6. Insert data into 'protected_by'
INSERT INTO protected_by (SP_ID, PROJ_ID, CONSERVATION_STATUS) VALUES
('S001', 'CP01', 'Critically Endangered'),
('S002', 'CP02', 'Critically Endangered'),
('S003', 'CP03', 'Critically Endangered'),
('S004', 'CP04', 'Critically Endangered');

-- Select the database to use
USE wild_db;

-- -----------------------------------------------------
-- PART 1: SCHEMA MODIFICATIONS
-- -----------------------------------------------------

-- First, we must drop the foreign keys from 'observations'
-- (We assume default constraint names from your previous screenshots)
ALTER TABLE observations DROP FOREIGN KEY observations_ibfk_1;
ALTER TABLE observations DROP FOREIGN KEY observations_ibfk_2;

-- Now, drop the columns as your new logic implies
ALTER TABLE observations DROP COLUMN SP_ID;
ALTER TABLE observations DROP COLUMN DATAID;


-- Create the new link table (with corrected VARCHAR types)
CREATE TABLE species_observations_link (
    sp_id VARCHAR(10),
    obs_id VARCHAR(10),
    PRIMARY KEY (sp_id, obs_id),
    FOREIGN KEY (sp_id) REFERENCES species(SP_ID),
    FOREIGN KEY (obs_id) REFERENCES observations(OBS_ID)
);

-- Create the 'Alerts' table (with corrected DataRecordID type)
CREATE TABLE IF NOT EXISTS Alerts (
    AlertID INT AUTO_INCREMENT PRIMARY KEY,
    AlertMessage VARCHAR(500),
    DataRecordID VARCHAR(10), -- Changed from INT to match DATA_ID
    Timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- -----------------------------------------------------
-- PART 2: FUNCTIONS
-- -----------------------------------------------------

-- Function 1: fn_GetSpeciesCountInPreserve
DELIMITER $$
CREATE FUNCTION fn_GetSpeciesCountInPreserve (
    p_PreserveID VARCHAR(10) -- Corrected type
)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_SpeciesCount INT;
    -- Corrected logic to query the correct table
    SELECT COUNT(SP_ID)
    INTO v_SpeciesCount
    FROM species_preserves
    WHERE P_ID = p_PreserveID; 
    RETURN v_SpeciesCount;
END $$
DELIMITER ;

-- Function 2: fn_GetProjectDurationDays
DELIMITER $$
CREATE FUNCTION fn_GetProjectDurationDays (
    p_ProjectID VARCHAR(10) -- Corrected type
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_Duration INT;
    SELECT DATEDIFF(END_DATE, STRDATE) -- Corrected column names
    INTO v_Duration
    FROM conservation_plan
    WHERE PROJ_ID = p_ProjectID; -- Corrected column names
    RETURN v_Duration;
END $$
DELIMITER ;

-- Function 3: fn_GetLastObservationDate
DELIMITER $$
CREATE FUNCTION fn_GetLastObservationDate (
    p_SpeciesID VARCHAR(10) -- Corrected type
)
RETURNS DATE
READS SQL DATA
BEGIN
    DECLARE v_LastDate DATE;
    SELECT MAX(O.OBS_DATE)
    INTO v_LastDate
    FROM observations AS O
    JOIN species_observations_link AS L ON O.OBS_ID = L.obs_id
    WHERE L.sp_id = p_SpeciesID;
    RETURN v_LastDate;
END $$
DELIMITER ;


-- -----------------------------------------------------
-- PART 3: STORED PROCEDURES
-- -----------------------------------------------------

-- Procedure 1: sp_AssignSpeciesToPlan
DELIMITER $$
CREATE PROCEDURE sp_AssignSpeciesToPlan (
    IN p_SpeciesID VARCHAR(10), -- Corrected type
    IN p_ProjectID VARCHAR(10), -- Corrected type
    IN p_InitialStatus VARCHAR(100)
)
BEGIN
    INSERT INTO protected_by (SP_ID, PROJ_ID, CONSERVATION_STATUS)
    VALUES (p_SpeciesID, p_ProjectID, p_InitialStatus);

    SELECT 'Species successfully assigned to plan.' AS message;
END $$
DELIMITER ;

-- Procedure 2: sp_AddNewObservation
DELIMITER $$
CREATE PROCEDURE sp_AddNewObservation (
    IN p_ObsID VARCHAR(10),     -- ADDED: Must provide a VARCHAR ID
    IN p_SpeciesID VARCHAR(10), -- Corrected type
    IN p_ObsDate DATE,
    IN p_ObsType VARCHAR(100),
    IN p_ObsLoc VARCHAR(255)
)
BEGIN
    START TRANSACTION;

    -- Corrected INSERT: Does not use LAST_INSERT_ID()
    INSERT INTO observations (OBS_ID, OBS_DATE, OBSTYPE, OBS_LOC)
    VALUES (p_ObsID, p_ObsDate, p_ObsType, p_ObsLoc);

    -- This part is now correct
    INSERT INTO species_observations_link (sp_id, obs_id)
    VALUES (p_SpeciesID, p_ObsID);

    COMMIT;
    SELECT 'New observation added and linked.' AS message;
END $$
DELIMITER ;


-- Procedure 3: sp_GetPreserveDashboard
DELIMITER $$
CREATE PROCEDURE sp_GetPreserveDashboard (
    IN p_PreserveID VARCHAR(10) -- Corrected type
)
BEGIN
    -- Query 1: Preserve Details
    SELECT P_ID, PLOC, PNAME FROM species_preserves WHERE P_ID = p_PreserveID;

    -- Query 2: List of Species in this preserve (Corrected logic)
    SELECT s.SP_NAME, s.CLASSIFICATION 
    FROM species s
    JOIN species_preserves sp ON s.SP_ID = sp.SP_ID
    WHERE sp.P_ID = p_PreserveID;

    -- Query 3: Most Recent Environmental Data
    SELECT DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL 
    FROM environmental_data 
    WHERE P_ID = p_PreserveID
    ORDER BY DATA_ID DESC -- Note: Ordering by a VARCHAR ID may not be chronological
    LIMIT 10;
END $$
DELIMITER ;


-- -----------------------------------------------------
-- PART 4: TRIGGERS
-- -----------------------------------------------------

-- Trigger 1: trg_ValidateProjectDates_Insert
DELIMITER $$
CREATE TRIGGER trg_ValidateProjectDates_Insert
BEFORE INSERT ON conservation_plan
FOR EACH ROW
BEGIN
    IF NEW.END_DATE <= NEW.STRDATE THEN -- Corrected column names
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project enddate must be after its strdate.';
    END IF;
END $$
DELIMITER ; -- Corrected syntax

-- Trigger 2: trg_ValidateProjectDates_Update
DELIMITER $$
CREATE TRIGGER trg_ValidateProjectDates_Update
BEFORE UPDATE ON conservation_plan
FOR EACH ROW
BEGIN
    IF NEW.END_DATE <= NEW.STRDATE THEN -- Corrected column names
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project enddate must be after its strdate.';
    END IF;
END $$
DELIMITER ; -- Corrected syntax

-- Trigger 3: trg_AlertOnCriticalEnvData
DELIMITER $$
CREATE TRIGGER trg_AlertOnCriticalEnvData
AFTER INSERT ON environmental_data
FOR EACH ROW
BEGIN
    -- WARNING: This logic will fail if WATER_COND is 'Clean' or 'Good'
    -- You must ensure data in this column is numeric for this to work.
    IF NEW.WATER_COND IS NOT NULL AND NEW.WATER_COND < 6.0 THEN
        INSERT INTO Alerts (AlertMessage, DataRecordID)
        VALUES (
            CONCAT('Critical water condition detected: ', NEW.WATER_COND),
            NEW.DATA_ID -- Corrected column name
        );
    END IF;

    -- WARNING: This logic will fail if AIRQUAL is 'Clean' or 'Good'
    IF NEW.AIRQUAL IS NOT NULL AND NEW.AIRQUAL > 150 THEN
        INSERT INTO Alerts (AlertMessage, DataRecordID)
        VALUES (
            CONCAT('Critical air quality detected: ', NEW.AIRQUAL),
            NEW.DATA_ID -- Corrected column name
        );
    END IF;
END $$
DELIMITER ;

-- Make sure you're using the database
USE wild_db;

-- Check if the species data is there
SELECT * FROM species;

-- Check if the observation data is there
SELECT * FROM observations;

-- Test the fn_GetProjectDurationDays function
SELECT fn_GetProjectDurationDays('CP01') AS ProjectDuration;

CALL sp_GetPreserveDashboard('P01');

-- This INSERT should FAIL
-- We are setting the end date (2025) before the start date (2026)
INSERT INTO conservation_plan (PROJ_ID, PROJ_NAME, STRDATE, END_DATE, SP_ID) 
VALUES ('CP99', 'Test Project Fail', '2026-01-01', '2025-01-01', 'S001');

-- 1. This INSERT should SUCCEED
-- We are adding environmental data with a bad air quality (200)
INSERT INTO environmental_data (DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL, P_ID) 
VALUES ('D99', '7.5', 'Clear', 'Loamy', '200', 'P01');

-- 2. Now, check the Alerts table
SELECT * FROM Alerts;

CALL sp_AddNewObservation(
    'O05', 
    'S001', 
    '2025-11-04', 
    'Drone Sighting', 
    '43.72° N, 131.55° E'
);

SELECT * FROM observations WHERE OBS_ID = 'O05';

SELECT * FROM species_observations_link WHERE OBS_ID = 'O05';

-- Use your database
USE wild_db;

-- Drop the old procedure
DROP PROCEDURE IF EXISTS sp_GetPreserveDashboard;

-- Create the new, more powerful procedure
DELIMITER $$
CREATE PROCEDURE sp_GetPreserveDashboard (
    IN p_PreserveID VARCHAR(10)
)
BEGIN
    -- First, get the preserve's location string
    DECLARE v_PreserveLocation VARCHAR(255);
    SELECT PLOC INTO v_PreserveLocation
    FROM species_preserves
    WHERE P_ID = p_PreserveID;
    
    -- Query 1: Preserve Details (Unchanged)
    SELECT P_ID, PLOC, PNAME FROM species_preserves WHERE P_ID = p_PreserveID;

    -- Query 2: All Species Observed at this Location (New Logic)
    SELECT DISTINCT s.SP_NAME, s.CLASSIFICATION
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.OBS_LOC = v_PreserveLocation;

    -- Query 3: Most Recent Environmental Data (Unchanged)
    SELECT DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL 
    FROM environmental_data 
    WHERE P_ID = p_PreserveID
    ORDER BY DATA_ID DESC
    LIMIT 10;
    
    -- Query 4: Top Observed Species (NEW FEATURE)
    SELECT s.SP_NAME, COUNT(o.OBS_ID) AS ObservationCount
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.OBS_LOC = v_PreserveLocation
    GROUP BY s.SP_NAME
    ORDER BY ObservationCount DESC
    LIMIT 1;

END $$
DELIMITER ;

-- Use your database
USE wild_db;

-- Drop the old procedure
DROP PROCEDURE IF EXISTS sp_GetPreserveDashboard;

-- Create the new, smarter procedure
DELIMITER $$
CREATE PROCEDURE sp_GetPreserveDashboard (
    IN p_PreserveID VARCHAR(10)
)
BEGIN
    -- First, get the preserve's NAME (this is the fix)
    DECLARE v_PreserveName VARCHAR(100);
    SELECT PNAME INTO v_PreserveName
    FROM species_preserves
    WHERE P_ID = p_PreserveID;
    
    -- Query 1: Preserve Details (Unchanged)
    SELECT P_ID, PLOC, PNAME FROM species_preserves WHERE P_ID = p_PreserveID;

    -- Query 2: All Species Observed at this Location (New Logic)
    -- We now search for the preserve's NAME inside the observation location
    SELECT DISTINCT s.SP_NAME, s.CLASSIFICATION
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.OBS_LOC LIKE CONCAT('%', v_PreserveName, '%');

    -- Query 3: Most Recent Environmental Data (Unchanged)
    SELECT DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL 
    FROM environmental_data 
    WHERE P_ID = p_PreserveID
    ORDER BY DATA_ID DESC
    LIMIT 10;
    
    -- Query 4: Top Observed Species (New Logic)
    -- We also use the new matching logic here
    SELECT s.SP_NAME, COUNT(o.OBS_ID) AS ObservationCount
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.OBS_LOC LIKE CONCAT('%', v_PreserveName, '%')
    GROUP BY s.SP_NAME
    ORDER BY ObservationCount DESC
    LIMIT 1;

END $$
DELIMITER ;

USE wild_db;
SELECT PNAME 
FROM species_preserves 
WHERE P_ID = 'P01';

SELECT DISTINCT OBS_LOC 
FROM observations;

-- 1. Temporarily disable safe update mode
SET SQL_SAFE_UPDATES = 0;

USE wild_db;

-- 2. (OPTIONAL BUT RECOMMENDED) Update your old data
-- This is the command that was failing, it will work now
UPDATE observations
SET P_ID = 'P01'
WHERE OBS_LOC LIKE '43.70%' OR OBS_LOC LIKE '43.72%';

-- 3. Update 'sp_AddNewObservation' to accept P_ID
DROP PROCEDURE IF EXISTS sp_AddNewObservation;
DELIMITER $$
CREATE PROCEDURE sp_AddNewObservation (
    IN p_ObsID VARCHAR(10),
    IN p_SpeciesID VARCHAR(10),
    IN p_ObsDate DATE,
    IN p_ObsType VARCHAR(100),
    IN p_ObsLoc VARCHAR(255),
    IN p_PreserveID VARCHAR(10) -- This is the new parameter
)
BEGIN
    START TRANSACTION;

    INSERT INTO observations (OBS_ID, OBS_DATE, OBSTYPE, OBS_LOC, P_ID)
    VALUES (p_ObsID, p_ObsDate, p_ObsType, p_ObsLoc, p_PreserveID);

    INSERT INTO species_observations_link (sp_id, obs_id)
    VALUES (p_SpeciesID, p_ObsID);

    COMMIT;
    SELECT 'New observation added and linked.' AS message;
END $$
DELIMITER ;

-- 4. Update 'sp_GetPreserveDashboard' to be 100% accurate
DROP PROCEDURE IF EXISTS sp_GetPreserveDashboard;
DELIMITER $$
CREATE PROCEDURE sp_GetPreserveDashboard (
    IN p_PreserveID VARCHAR(10)
)
BEGIN
    -- Query 1: Preserve Details
    SELECT P_ID, PLOC, PNAME FROM species_preserves WHERE P_ID = p_PreserveID;

    -- Query 2: All Species Observed (PERFECTLY ACCURATE FIX)
    SELECT DISTINCT s.SP_NAME, s.CLASSIFICATION
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.P_ID = p_PreserveID; -- This is the fix

    -- Query 3: Environmental Data
    SELECT DATA_ID, WATER_COND, WEATHERCOND, SOIL_COMP, AIRQUAL 
    FROM environmental_data 
    WHERE P_ID = p_PreserveID
    ORDER BY DATA_ID DESC
    LIMIT 10;
    
    -- Query 4: Top Observed Species (PERFECTLY ACCURATE FIX)
    SELECT s.SP_NAME, COUNT(o.OBS_ID) AS ObservationCount
    FROM species s
    JOIN species_observations_link sol ON s.SP_ID = sol.sp_id
    JOIN observations o ON sol.obs_id = o.OBS_ID
    WHERE o.P_ID = p_PreserveID -- This is the fix
    GROUP BY s.SP_NAME
    ORDER BY ObservationCount DESC
    LIMIT 1;

END $$
DELIMITER ;

-- 5. Turn safe update mode back on (good practice)
SET SQL_SAFE_UPDATES = 1;