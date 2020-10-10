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