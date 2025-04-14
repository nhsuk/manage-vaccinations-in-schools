# Performance Tests

There are 3 current performance test scripts that are built using the tool jMeter, this is an opensource load testing tool and is a part of the Apache suite. For the Mavis programme, the three scripts that are currently part of the regression pack is Nurse, Reporting and Parental Consent.

## Pre-requisites
For these tests to run, sessions for the Nurse journey will need to be set for the day its run on. The parental consent journeys will need to have the schools to be scheduled for a week in the future. 

## User Journeys

### Nurse

The Nurse journey entails - 
1. Logging in
2. Selecting Organisation Unit
3. Open Session Page
4. (Loop starts) Search for random non-registered patient and sets as attending
5. Completes a consent
6. Triages the patient
7. Vaccinates the patient using HPV/MenACWY/IPV (Loop ends)
8. Logout

### Reporting
The reporting journey entails - 
1. Logging in
2. Selecting Organisation Unit
3. Opens Programmes page
4. Opens each of the vaccines
5. Generates a vaccination report using random dates in the CarePlus format
6. Logout

### Parental Consent
The reporting journey entails - 
1. Opens the Session Consent Page
2. If the child is old enough for the HPV vaccination, completes the user journey with an approval 
4. If the child is old enough for the MenACWY/IPV vaccination, completes the user journey with an approval

## Execution

Whilst jMeter tests are scripted in the UI tests should be conducted in CLI Mode. To do this use the following commands to execute the standard regression tests.

### Nurse
```
jmeter -n -t Mavis_Nurse.jmx -l <logFileName> -JSessionSlug=<sessionSlug>  -JAuthToken=<basicAuthToken> -JDuration=3600 -JThreads=70 -JLoops=-1 -JRampUp=900 -JVaccinationLoop=10
``` 

These are the run-time parameters for the Nurse journey this denotes - 
1. SessionSlug that is used for which vaccination session is being used
2. The AuthToken is the Basic Authentication method when logging into the QA/Test Environment, this encoded in Base64
3. Threads is the number of Virtual Users that are being executed in the usere journey
4. Duration is the amount of time the test runs for in seconds (i.e. 3600 = 1h, 1800 = 30 mins etc.)
5. RampUp is like Duration, it is the amount of time it takes to ramp up (or the arrival rate) the entire thread group, i.e. 70 users in 900 seconds.
6. Loops is the number of loops each Virtual User will execute before shutting down (-1 denotes infinite, 1 is 1 loop etc.)
7. VaccinationLoop is the number of vaccinations each nurse will do before logging out, this is currently defaulted at 20, however in an hour long test, do not expect the nurse to logout at all.

### Parental Consent

```
jmeter -n -t Mavis_Nurse.jmx -l <logFileName>  -JAuthToken=<basicAuthToken> -JDuration=3600 -JThreads=20 -JLoops=-1 -JRampUp=300 -JInputFile=<feederFileName> -JUrnMapping=<urnMappingFileName>
```

These are the run-time parameters for the Nurse journey this denotes - 
1. The AuthToken is the Basic Authentication method when logging into the QA/Test Environment, this encoded in Base64
2. Threads is the number of Virtual Users that are being executed in the usere journey
3. Duration is the amount of time the test runs for in seconds (i.e. 3600 = 1h, 1800 = 30 mins etc.)
4. RampUp is like Duration, it is the amount of time it takes to ramp up (or the arrival rate) the entire thread group, i.e. 70 users in 900 seconds.
5. Loops is the number of loops each Virtual User will execute before shutting down (-1 denotes infinite, 1 is 1 loop etc.)
6. InputFile is the feeder file of a large number of patients that will be used for the parental consent. This is a large CSV file with multiple patients in, this is thread-safe so multiple threads will not access the same rows.
7. UrnMapping is a URN -> Session Slug mapping, this allows random patients to be in whatever schools, giving more randomness to occur.

### Reporting

```
jmeter -n -t Mavis_Nurse.jmx -l <logFileName> -JAuthToken=<basicAuthToken> -JDuration=3600 -JThreads=1 -JLoops=-1 -JRampUp=1 -JHourlyRate=2
```

These are the run-time parameters for the Nurse journey this denotes - 
1. The AuthToken is the Basic Authentication method when logging into the QA/Test Environment, this encoded in Base64
2. Threads is the number of Virtual Users that are being executed in the usere journey
3. Duration is the amount of time the test runs for in seconds (i.e. 3600 = 1h, 1800 = 30 mins etc.)
4. RampUp is like Duration, it is the amount of time it takes to ramp up (or the arrival rate) the entire thread group, i.e. 70 users in 900 seconds.
5. Loops is the number of loops each Virtual User will execute before shutting down (-1 denotes infinite, 1 is 1 loop etc.)
6. HourlyRate is the number of iterations it executes in an hour, i.e. 2 will be once every 30 minutess

## Future Plans
TBC