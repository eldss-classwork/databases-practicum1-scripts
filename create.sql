-- This script provides statements to build the tables required
-- of a contact tracing database.

DROP TABLE IF EXISTS `Individuals`;
CREATE TABLE `Individuals` (
  `person_id` Int PRIMARY KEY auto_increment,
  `name` Text NOT NULL,
  -- Tracked people demographics are voluntary
  `phone` Text default NULL,
  `email` Text default NULL,
  `address` Text default NULL,
  `city` Text default NULL,
  `state` Text default NULL,
  `zip` Int default NULL,
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `TrackedIndividuals`;
CREATE TABLE `TrackedIndividuals` (
  `person_id` Int PRIMARY KEY,
  `dob` Date default NULL,
  `race` Text default NULL,
  `sex` Text default NULL,
  FOREIGN KEY (`person_id`) REFERENCES `Individuals`(`person_id`)
);

DROP TABLE IF EXISTS `CaseManagers`;
CREATE TABLE `CaseManagers` (
  `person_id` Int PRIMARY KEY,
  `basedCity` Text NOT NULL,
  `basedState` Text NOT NULL,
  `startingDate` Date NOT NULL,
  `infected_id` Int unsigned default NULL,
  FOREIGN KEY (`person_id`) REFERENCES `Individuals`(`person_id`),
  FOREIGN KEY (`infected_id`) REFERENCES `Individuals`(`person_id`)
);

DROP TABLE IF EXISTS `RiskLevels`;
CREATE TABLE `RiskLevels` (
    `risk_id` Int PRIMARY KEY auto_increment,
    `risk` Text UNIQUE NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `CommunicationMethods`;
CREATE TABLE `CommunicationMethods` (
    `commMethod_id` Int PRIMARY KEY auto_increment,
    `commMethod` Text UNIQUE NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `Cases`;
CREATE TABLE `Cases` (
  `case_id` Int PRIMARY KEY auto_increment,
  `estimatedExposureDate` Date NOT NULL,
  `totalRiskLevel_id` Int NOT NULL,
  `quarantineStartDate` Date default NULL,
  `closureDate` Date default NULL,
  `infected` Boolean default False,
  `hospitalized` Boolean default False,
  `covidDeath` Boolean default False,
  `commMethod_id` Int NOT NULL,
  `cm_person_id` Int NOT NULL,
  `tracked_person_id` Int NOT NULL,
  FOREIGN KEY (`cm_person_id`) REFERENCES `Individuals`(`person_id`),
  FOREIGN KEY (`tracked_person_id`) REFERENCES `Individuals`(`person_id`)
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `Tests`;
CREATE TABLE `Tests` (
    `test_id` Int PRIMARY KEY auto_increment,
    `name` Text UNIQUE NOT NULL,
    `accuracy` Decimal(2,2) NOT NULL,
    `estimatedResultTimeHrs` Int NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `PossibleTestOutcomes`;
CREATE TABLE `PossibleTestOutcomes` (
    `outcome_id` Int PRIMARY KEY auto_increment,
    `outcome` Text NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `TestResults`;
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
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `Symptoms`;
CREATE TABLE `Symptoms` (
    `symptom_id` Int PRIMARY KEY auto_increment,
    `name` Text NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `MonitoringLogs`;
CREATE TABLE `MonitoringLogs` (
    `monitor_id` Int PRIMARY KEY auto_increment,
    `timestamp` DateTime NOT NULL,
    `temp` Decimal(3,1) NOT NULL,
    `tempType` Char(1) NOT NULL CHECK (`tempType` == 'F' OR `tempType` == 'C'),
    `additionalInfo` Text default NULL,
    `case_id` Int NOT NULL,
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`)
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `SymptomList`;
CREATE TABLE `SymptomList` (
    `sl_id` Int PRIMARY KEY auto_increment,
    `monitor_id` Int NOT NULL,
    `symptom_id` Int NOT NULL,
    FOREIGN KEY (`monitor_id`) REFERENCES `MonitoringLogs`(`monitor_id`),
    FOREIGN KEY (`symptom_id`) REFERENCES `Symptoms`(`symptom_id`)
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `ContactLogs`;
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
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `Messages`;
CREATE TABLE `Messages` (
    `message_id` Int PRIMARY KEY auto_increment,
    `messageLevel_id` Int NOT NULL,
    `messageInfo` Text NOT NULL,
    FOREIGN KEY (`messageLevel_id`) REFERENCES `RiskLevels`(`risk_id`)
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `NextSteps`;
CREATE TABLE `NextSteps` (
    `step_id` Int PRIMARY Key auto_increment,
    `name` Text NOT NULL,
    `levelNeeded_id` Int NOT NULL,
    `additionalInfo` Text NOT NULL,
    FOREIGN KEY (`levelNeeded_id`) REFERENCES `RiskLevels`(`risk_id`);
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `StepList`;
CREATE TABLE `StepList` (
    `stepList_id` Int PRIMARY KEY auto_increment,
    `message_id` Int NOT NULL,
    `step_id` Int NOT NULL,
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`),
    FOREIGN KEY (`step_id`) REFERENCES `NextSteps`(`step_id`)
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `CommunicationLogs`;
CREATE TABLE `CommunicationLogs` (
    `commLog_id` Int PRIMARY KEY auto_increment,
    `timestamp` DateTime NOT NULL,
    `method_id` Int NOT NULL,
    `case_id` Int NOT NULL,
    `message_id` Int NOT NULL,
    FOREIGN KEY (`method_id`) REFERENCES `CommunicationMethods`(`commMethod_id`),
    FOREIGN KEY (`case_id`) REFERENCES `Cases`(`case_id`),
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`);
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `Services`;
CREATE TABLE `Services` (
    `service_id` Int PRIMARY KEY auto_increment,
    `name` Text NOT NULL,
    `phone` Text NOT NULL,
    `link` Text NOT NULL,
    `description` Text NOT NULL,
    `type` Text NOT NULL 
        CHECK (`type` == "Self" OR `type` == "Support"),
    `city` Text NOT NULL,
    `supports` Text NOT NULL
) AUTO_INCREMENT=1;

DROP TABLE IF EXISTS `ServiceList`;
CREATE TABLE `ServiceList` (
    `serviceList_id` Int PRIMARY KEY auto_increment,
    `message_id` Int NOT NULL,
    `service_id` Int NOT NULL,
    FOREIGN KEY (`message_id`) REFERENCES `Messages`(`message_id`),
    FOREIGN KEY (`service_id`) REFERENCES `Services`(`service_id`);
) AUTO_INCREMENT=1;