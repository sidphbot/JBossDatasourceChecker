# JBossDatasourceChecker
List and check datasource connectivity for all JBoss servers running for a user

Datasources(JBoss) test Util :

Utility : testdb.sh

Features : 
•	Lists datasource and related info
•	Lists associated driver module jar
•	Tests connection and reports with the error faced if failed to connect
•	Shows datasource Pool Usage (if statistics is enabled in cli)

User : JBoss instance user

Conditions : the cli ports should not be manually changed, however port-offsets will be automatically recognised

Usage :
$ ./testdb.sh

e.g.
$ ./testdb.sh

