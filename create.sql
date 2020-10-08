-- This script provides statements to build the tables required
-- of a contact tracing database.

-- Start by dropping tables
SET foreign_key_checks = 0;
DROP TABLE IF EXISTS `ContactLogs`;
DROP TABLE IF EXISTS `CommunicationLogs`;
DROP TABLE IF EXISTS `ServiceList`;
DROP TABLE IF EXISTS `Services`;
DROP TABLE IF EXISTS `StepList`;
DROP TABLE IF EXISTS `Individuals`;
DROP TABLE IF EXISTS `NextSteps`;
DROP TABLE IF EXISTS `CaseManagers`;
DROP TABLE IF EXISTS `Cases`;
DROP TABLE IF EXISTS `TrackedIndividuals`;
DROP TABLE IF EXISTS `Messages`;
DROP TABLE IF EXISTS `SymptomList`;
DROP TABLE IF EXISTS `Symptoms`;
DROP TABLE IF EXISTS `MonitoringLogs`;
DROP TABLE IF EXISTS `TestResults`;
DROP TABLE IF EXISTS `PossibleTestOutcomes`;
DROP TABLE IF EXISTS `Tests`;
DROP TABLE IF EXISTS `CommunicationMethods`;
DROP TABLE IF EXISTS `RiskLevels`;
SET foreign_key_checks = 1;

-- Recreate the tables
CREATE TABLE `Individuals` (
  `person_id` Int PRIMARY KEY auto_increment,
  `name` Text NOT NULL,
  -- Tracked people demographics are voluntary
  `phone` Text,
  `email` Text,
  `address` Text,
  `city` Text,
  `state` Text,
  `zip` Int
);
-- These lines are included because of how 
-- https://www.generatedata.com/ generates CREATE TABLE statements
-- and test data assumes ids start at 1.
ALTER TABLE `Individuals` AUTO_INCREMENT=1;

CREATE TABLE `TrackedIndividuals` (
  `person_id` Int PRIMARY KEY,
  `dob` Date,
  `race` Text,
  `sex` Text,
  FOREIGN KEY (`person_id`) REFERENCES `Individuals`(`person_id`)
);

CREATE TABLE `CaseManagers` (
  `person_id` Int PRIMARY KEY,
  `basedCity` Text NOT NULL,
  `basedState` Text NOT NULL,
  `startingDate` Date NOT NULL,
  `infected_id` Int UNIQUE,
  FOREIGN KEY (`person_id`) REFERENCES `Individuals`(`person_id`),
  FOREIGN KEY (`infected_id`) REFERENCES `Individuals`(`person_id`)
);

CREATE TABLE `RiskLevels` (
    `risk_id` Int PRIMARY KEY auto_increment,
    `risk` Text UNIQUE NOT NULL
);
ALTER TABLE `RiskLevels` AUTO_INCREMENT=1;

CREATE TABLE `CommunicationMethods` (
    `commMethod_id` Int PRIMARY KEY auto_increment,
    `commMethod` Text UNIQUE NOT NULL
);
ALTER TABLE `CommunicationMethods` AUTO_INCREMENT=1;

CREATE TABLE `Cases` (
  `case_id` Int PRIMARY KEY auto_increment,
  `estimatedExposureDate` Date NOT NULL,
  `totalRiskLevel_id` Int NOT NULL,
  `quarantineStartDate` Date,
  `closureDate` Date,
  `infected` Boolean default False,
  `hospitalized` Boolean default False,
  `covidDeath` Boolean default False,
  `commMethod_id` Int NOT NULL,
  `cm_person_id` Int NOT NULL,
  `tracked_person_id` Int UNIQUE NOT NULL,
  FOREIGN KEY (`totalRiskLevel_id`) REFERENCES `RiskLevels`(`risk_id`),
  FOREIGN KEY (`commMethod_id`) REFERENCES `CommunicationMethods`(`commMethod_id`),
  FOREIGN KEY (`cm_person_id`) REFERENCES `Individuals`(`person_id`),
  FOREIGN KEY (`tracked_person_id`) REFERENCES `Individuals`(`person_id`)
);
ALTER TABLE `Cases` AUTO_INCREMENT=1;

CREATE TABLE `Tests` (
    `test_id` Int PRIMARY KEY auto_increment,
    `name` Text UNIQUE NOT NULL,
    `accuracy` Decimal(2,2) NOT NULL,
    `estimatedResultTimeHrs` Int NOT NULL
);
ALTER TABLE `Tests` AUTO_INCREMENT=1;

CREATE TABLE `PossibleTestOutcomes` (
    `outcome_id` Int PRIMARY KEY auto_increment,
    `outcome` Text NOT NULL
);
ALTER TABLE `PossibleTestOutcomes` AUTO_INCREMENT=1;

CREATE TABLE `TestResults` (
    `results_id` Int PRIMARY KEY auto_increment,
    `date` Date NOT NULL,
    `outcome_id` Int NOT NULL,
    `selfReported` Boolean NOT NULL,
    `authenticated` Boolean NOT NULL default False,
    `test_id` Int NOT NULL,
    `case_id` Int NOT NULL,
    FOREIGN KEY (`outcome_id`) REFERENCES `PossibleTestOutcomes`(`outcome_id`),
    FOREIGN KEY (`test_id`) REFERENCES `Tests`(`test_id`),
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`)
);
ALTER TABLE `TestResults` AUTO_INCREMENT=1;

CREATE TABLE `Symptoms` (
    `symptom_id` Int PRIMARY KEY auto_increment,
    `name` Text NOT NULL
);
ALTER TABLE `Symptoms` AUTO_INCREMENT=1;

CREATE TABLE `MonitoringLogs` (
    `monitor_id` Int PRIMARY KEY auto_increment,
    `timestamp` DateTime NOT NULL,
    `temp` Decimal(4,1) NOT NULL,
    `tempType` Text NOT NULL CHECK (`tempType` = "F" OR `tempType` = "C"),
    `additionalInfo` Text,
    `case_id` Int NOT NULL,
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`)
);
ALTER TABLE `MonitoringLogs` AUTO_INCREMENT=1;

CREATE TABLE `SymptomList` (
    `sl_id` Int PRIMARY KEY auto_increment,
    `monitor_id` Int NOT NULL,
    `symptom_id` Int NOT NULL,
    FOREIGN KEY (`monitor_id`) REFERENCES `MonitoringLogs`(`monitor_id`),
    FOREIGN KEY (`symptom_id`) REFERENCES `Symptoms`(`symptom_id`)
);
ALTER TABLE `SymptomList` AUTO_INCREMENT=1;

CREATE TABLE `ContactLogs` (
    `contactLog_id` Int PRIMARY KEY auto_increment,
    `timestamp` DateTime NOT NULL,
    -- Datatypes used for lat/long suggested here:
    -- https://stackoverflow.com/questions/12504208/what-mysql-data-type-should-be-used-for-latitude-longitude-with-8-decimal-places
    `latitude` Decimal(10,8) NOT NULL, 
    `longitude` Decimal(11,8) NOT NULL,
    `contactDurationMin` Int NOT NULL,
    `maskUseInfected` Boolean NOT NULL,
    `maskUseContact` Boolean NOT NULL,
    `distanceFeet` Int NOT NULL,
    `risk_id` Int NOT NULL,
    `contact_person_id` Int NOT NULL,
    `case_id` Int NOT NULL,
    FOREIGN KEY (`risk_id`) REFERENCES `RiskLevels`(`risk_id`),
    FOREIGN KEY (`contact_person_id`) REFERENCES `Individuals`(`person_id`),
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`)
);
ALTER TABLE `ContactLogs` AUTO_INCREMENT=1;

CREATE TABLE `Messages` (
    `message_id` Int PRIMARY KEY auto_increment,
    `messageLevel_id` Int NOT NULL,
    `messageInfo` Text NOT NULL,
    FOREIGN KEY (`messageLevel_id`) REFERENCES `RiskLevels`(`risk_id`)
);
ALTER TABLE `Messages` AUTO_INCREMENT=1;

CREATE TABLE `NextSteps` (
    `step_id` Int PRIMARY Key auto_increment,
    `name` Text NOT NULL,
    `levelNeeded_id` Int NOT NULL,
    `additionalInfo` Text NOT NULL,
    FOREIGN KEY (`levelNeeded_id`) REFERENCES `RiskLevels`(`risk_id`)
);
ALTER TABLE `NextSteps` AUTO_INCREMENT=1;

CREATE TABLE `StepList` (
    `stepList_id` Int PRIMARY KEY auto_increment,
    `message_id` Int NOT NULL,
    `step_id` Int NOT NULL,
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`),
    FOREIGN KEY (`step_id`) REFERENCES `NextSteps`(`step_id`)
);
ALTER TABLE `StepList` AUTO_INCREMENT=1;

CREATE TABLE `CommunicationLogs` (
    `commLog_id` Int PRIMARY KEY auto_increment,
    `timestamp` DateTime NOT NULL,
    `method_id` Int NOT NULL,
    `case_id` Int NOT NULL,
    `message_id` Int NOT NULL,
    FOREIGN KEY (`method_id`) REFERENCES `CommunicationMethods`(`commMethod_id`),
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`),
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`)
);
ALTER TABLE `CommunicationLogs` AUTO_INCREMENT=1;

CREATE TABLE `Services` (
    `service_id` Int PRIMARY KEY auto_increment,
    `name` Text NOT NULL,
    `phone` Text NOT NULL,
    `link` Text NOT NULL,
    `description` Text NOT NULL,
    `type` Text NOT NULL 
        CHECK (`type` = "Self" OR `type` = "Support"),
    `city` Text NOT NULL,
    `supports` Text NOT NULL
);
ALTER TABLE `Services` AUTO_INCREMENT=1;

CREATE TABLE `ServiceList` (
    `serviceList_id` Int PRIMARY KEY auto_increment,
    `message_id` Int NOT NULL,
    `service_id` Int NOT NULL,
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`),
    FOREIGN KEY (`service_id`) REFERENCES `Services`(`service_id`)
);
ALTER TABLE `ServiceList` AUTO_INCREMENT=1;