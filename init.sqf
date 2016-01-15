
//["MySQL_test_database_1", "SQL_CUSTOM_V2", "/"] call compile preprocessFileLineNumbers "database\init.sqf";

//call ARMST_fnc_classDatabaseConnect;

_databaseConn = ["new", ["MySQL_test_database_1", "SQL_CUSTOM_V2", "/"]] call ARMST_DatabaseExtDB2;

hint str (["getConnectID" call _databaseConn]);

/*
_currentUnit = "getUnit" call _databaseConn;
["setUnit", player] call _databaseConn;
["delete", _databaseConn, "Player Removed!"] call ARMST_DatabaseExtDB2;
_databaseConn = nil;
*/