
//---------------Connect examples:

/* Example 1: Connect and load SQL_CUSTOM_V2 protocol as default (recommended) 
	_databaseConn = ["new", ["MySQL_test_database_1", "SQL_CUSTOM_V2", "/"]] call OO_extDB2;
*/
	
/* Example 2: Connect and load SQL_CUSTOM_V2 protocol as default (no lock) */
	_databaseConn = ["new", 
		[
			"MySQL_test_database_1",	//Database name
			"SQL_CUSTOM_V2",			//Default protocol (connect and protocol will be saved after changing mission)
			"/",						//Protocol options: SQL custom filename or folder
			false						//(Optional) Lock 'extDB2' extension after connect.
										//false if want to load runtime another protocols. Default: true
		]
	] call OO_extDB2;


/* Example 3: Connect and load SQL_RAW_v2 protocol as default (no lock)
	_databaseConn = ["new", 
		[
			"MySQL_test_database_1",	//Database name
			"SQL_RAW_v2",				//Default protocol (connect and protocol will be saved after changing mission)
			"ADD_QUOTES",				//Protocol options: 'ADD_QUOTES' OR ''
			false						//(Optional) Lock 'extDB2' extension after connect.
										//false if want to load runtime another protocols. Default: true
		]
	] call OO_extDB2;
 */
	
//---------------Load runtime protocol:	
//Runtime load protocols. Should not use it unless you need to

/* Example 1: Load runtime protocol, SQL_RAW_v2  */
	["loadDatabaseProtocol", ["MySQL_test_database_1", "SQL_RAW_v2", "SQL", "ADD_QUOTES"]] call _databaseConn;


/* Example 2: Load runtime protocol, SQL_RAW_v2 
	["loadDatabaseProtocol", ["MySQL_test_database_1", "SQL_RAW_v2", "SPECIALFORSQLINJECTION"]] call _databaseConn;
*/ 

/* Example 3: Load runtime protocol, SQL_CUSTOM_V2  
	["loadDatabaseProtocol", ["MySQL_test_database_1", "SQL_CUSTOM_V2", str(round(random(999999))), "/"]] call _databaseConn;
*/

//-----------------Requests examples:

// (SQL_CUSTOM_V2):
/* Example 1: */

_result = ["sendRequest", [2, "test_getraw_byid:9"]] call _databaseConn; ////0=Sync 1=ASync 2=ASync+Save (1 always returned true)
hint format ["SQL_CUSTOM_V2: %1", _result];


/* (SQL_RAW_V2) 
Note this is raw SQL basicly + completely unsafe i.e it will let you drop tables from your Database. 
All Security / SQL Escaping must be done via SQF Code */

/* Example 1:  */

sleep 3; //Now probably use another protocol. Just call method for use needed protocol before load

_use = ["useDatabaseProtocol", "SQL_RAW_v2"] call _databaseConn;
if(_use) then {
	_result = ["sendRequest", [2, "SELECT some_integer, some_string, some_not_null_string, some_float FROM test_table_1 WHERE id=9"]] call _databaseConn;
	hint format ["SQL_RAW_V2: %1", _result];
}; 

sleep 3; hint "Okay :?";


//-----------------Other public methods:

//_lock = "lock" call _databaseConn;
//_locked = "locked" call _databaseConn;



