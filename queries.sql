-- How many communications have been sent to people in each 
-- exposure level group?
SELECT r.risk, COUNT(cl.`timestamp`) AS numCommunications
FROM CommunicationLogs AS cl, Cases AS c, RiskLevels AS r
WHERE cl.case_id=c.case_id AND c.totalRiskLevel_id=r.risk_id
GROUP BY r.risk
ORDER BY r.risk_id;

-- List the number of COVID deaths by state, in descending order of deaths.
SELECT i.state, COUNT(*) AS deaths
FROM Cases AS c, Individuals AS i
WHERE c.tracked_person_id=i.person_id AND c.covidDeath=1
GROUP BY i.state
ORDER BY deaths DESC;

-- List the individual name, type of test, test method, test result, 
-- and date of test for all recorded tests; order by date taken.
SELECT i.`name`, t.`name`, t.method, pto.outcome, tr.`date`
FROM Individuals AS i, Tests AS t, TestResults AS tr, Cases AS c, PossibleTestOutcomes AS pto
WHERE
	tr.test_id=t.test_id
    AND tr.case_id=c.case_id
    AND tr.outcome_id=pto.outcome_id
    AND c.tracked_person_id=i.person_id
ORDER BY tr.`date`;

-- Get the name, phone, and email of individuals who did not provide
-- daily check-ins while in quarantine (14 days).
SELECT i.`name`, i.phone, i.email, COUNT(*) AS `messages sent`
FROM Individuals AS i, Cases AS c, MonitoringLogs AS ml
WHERE
	c.tracked_person_id=i.person_id
    AND ml.case_id=c.case_id
    AND c.closureDate IS NOT NULL
GROUP BY i.`name`
HAVING `messages sent` < 14;

-- Get the id and number of cases assigned to each case manager.
SELECT cm.person_id AS CM_ID, CASE WHEN CaseCount IS NULL THEN 0 ELSE CaseCount END AS CaseCount
FROM casemanagers cm 
LEFT JOIN (SELECT cm_person_id,COUNT(cm_person_id) AS CaseCount FROM cases GROUP BY cm_person_id) counts 
ON cm_person_id = cm.person_id;

-- Get the id, name, phone, and email of individuals who have been
-- in contact with a tracked individual but do not have a case yet.
SELECT person_id, ind.name, ind.phone, ind.email
FROM individuals ind 
JOIN (SELECT DISTINCT(contact_person_id) AS contact, cases.case_id 
	FROM contactlogs 
	LEFT JOIN cases ON contact_person_id = tracked_person_id WHERE cases.case_id IS NULL) logged 
ON person_id = contact;

-- Get the case, name, preferred communication method, contact information, 
-- and case closure date for tracked individuals who have a temperature over
-- 99 degrees F and are experiencing a cough or breathing problems.
SELECT cases.case_id, ind.name, commMethod, 
	CASE WHEN commMethod='Email' THEN email ELSE phone END AS contactInfo, closureDate 
FROM cases 
JOIN (SELECT DISTINCT(case_id) FROM monitoringlogs ml 
	JOIN symptomlist sl ON sl.monitor_id = ml.monitor_id
	WHERE temp > 99 AND tempType = 'F' AND symptom_id IN (3,4,5)) log
ON cases.case_id = log.case_id 
JOIN communicationmethods cm ON cases.commMethod_id = cm.commMethod_id
JOIN individuals ind ON tracked_person_id = person_id;

-- Find the id of individuals that were not infected and have been re-exposed.
-- Include the date the original case was closed, and the new exposure date.
SELECT tracked_person_id, closureDate AS originalClosureDate, timestamp AS exposureDate
FROM cases JOIN contactlogs ON tracked_person_id = contact_person_id 
WHERE infected = 0 AND timestamp > closureDate;