
//["MySQL_test_database_1", "SQL_CUSTOM_V2", "/"] call compile preprocessFileLineNumbers "database\init.sqf";

_databaseConn = ["new", ["MySQL_test_database_1", "SQL_CUSTOM_V2", "/"]] call OO_extDb2;

hint str (["getConnectID" call _databaseConn]);
