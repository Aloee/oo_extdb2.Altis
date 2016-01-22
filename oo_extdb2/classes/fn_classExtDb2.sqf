	/*
	Authors: 
	Aloe <itfruit@mail.ru>
	Code34 <nicolas_boiteux@yahoo.fr>
	
	Copyright (C) 2016 Aloe/Code34

	CLASS OO_extDB2 -  Class for connect to extDB2, send requests, get responses

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>. 

	0: [DATABASE_NAME] <String>  Database name for connect.
	1: [SQL_CUSTOM_* or SQL_RAW_*] <String> Default protocol (connection and protocol will be saved after changing mission)
	2: [SQL_CUSTOM_FILENAME or ADD_QUOTES] <String> Protocol options: SQL_CUSTOM_FILENAME for SQL_CUSTOM_* protocols or ADD_QUOTES for SQL_RAW_* protocols. Etc.
	3: (Optional) <Bool> Default: True. Lock 'extdb2' extension after connect. False if want to load another protocols (runtime).
	*/
	
	#include "oop.h"

	CLASS("OO_extDB2")
		
		PRIVATE VARIABLE("scalar", "dllversionrequired");
		PRIVATE VARIABLE("string", "databasename");
		PRIVATE VARIABLE("string", "protocol");
		PRIVATE VARIABLE("string", "sessionid");
		PRIVATE STATIC_VARIABLE("array", "sessions");
		PRIVATE VARIABLE("scalar", "version");


		PUBLIC FUNCTION("array", "constructor") {
			
			MEMBER("version", 0.1);
			MEMBER("dllversionrequired", 62);

			private ["_database", "_protocol", "_protocoloptions", "_varNameDatabase", "_sessionid", "_protocolparams"];

			if!(MEMBER("checkExtDB2isLoaded", nil)) exitwith { MEMBER("sendError", "OO_extDB required extDB2 Dll"); };
			if!(MEMBER("checkDllVersion", nil)) exitwith { MEMBER("sendLog", "Required extDB2 Dll version is " + (str MEMBER("dllversionrequired", nil)) + " or higher."); };
			if(isnil MEMBER("sessions", nil)) then { _array = []; MEMBER("sessions", _array;);};
		
			_database =        [_this, 0, "", [""]] call BIS_fnc_param;
			_protocol =        [_this, 1, "", [""]] call BIS_fnc_param;
			_protocoloptions = [_this, 2, "", [""]] call BIS_fnc_param;
			_lock =            [_this, 3, true, [true]] call BIS_fnc_param;
			
			MEMBER("databasename", _database);
			_result = MEMBER("connectDatabase", _database);

			_sessionid =  MEMBER("getSessionId", nil);
			MEMBER("sessions", nil) pushBack _sessionid;
			MEMBER("sessionid", _sessionid);
			
			_protocolparams = [_database, _protocol, _sessionid, _protocoloptions];
			_result = MEMBER("loadDatabaseProtocol", _protocolparams);
			if(_lock) then { MEMBER("lock", nil) };
		};

		PUBLIC FUNCTION("", "getSessionId") {
			private ["_sessionid"];
			_sessionid = str(round(random(999999)));
			while { _sessionid in MEMBER("sessions", nil) } do {
				_sessionid = str(round(random(999999)));
				sleep 0.01;
			};
			_sessionid;
		};

		PUBLIC FUNCTION("string", "existSessionId") {
			if(_this in MEMBER("sessions", nil)) then { true; } else { false; };
		};

		PUBLIC FUNCTION("", "checkDllVersion") {
			if(MEMBER("getDllVersion", nil) > MEMBER("dllversionrequired", nil)) then { true;} else {false;};
		};

		PUBLIC FUNCTION("", "checkExtDB2isLoaded") {
			if(MEMBER("getDllVersion", nil) == 0) then { false; } else { true;};
		};

		PUBLIC FUNCTION("", "getVersion") {
			 format["OO_extDB2: %1 Dll: %2", MEMBER("getDllVersion", nil), MEMBER("version", nil)];
		};
		
		PUBLIC FUNCTION("", "lock") {
			private ["_result"];
			
			_result = call compile ("extDB2" callExtension "9:LOCK");
			if ((_result select 0) isEqualTo 1) then { MEMBER("sendLog", "Locked"); true; } else { false; };
		};
		
		PUBLIC FUNCTION("", "locked") {
			private ["_result"];
			
			_result = call compile ("extDB2" callExtension "9:LOCK_STATUS");		
			if((_result select 0) isEqualTo 1) then { true; } else { false; };
		};
		
		PUBLIC FUNCTION("array", "loadDatabaseProtocol") {
			private ["_return", "_result"];
	
			_database = _this select 0;
			_protocol = _this select 1;
			_id = _this select 2;
			_protocoloptions = _this select 3;		

			_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE_PROTOCOL:%1:%2:%3:%4", _database, _protocol, _id, _protocoloptions]);
						
			if ((_result select 0) isEqualTo 1) then {
				MEMBER("sendLog", "Protocol loaded - " + _protocol);
				_return = true;
			}else{
				MEMBER("sendError", _result select 1);
				_return = false;
			};		
			_return;
		};
				
		PUBLIC FUNCTION("array", "sendRequest") {
			private["_queryResult", "_key", "_mode", "_loop"];
			
			_queryResult = [0, "Syntax error"];
			
			if (_this params [["_mode", 0, [0]], ["_queryStmt", "", [""]]]) then {
			
				_key = call compile ("extDB2" callExtension format["%1:%2:%3",_mode, MEMBER("sessionid", nil), _queryStmt]);

				//0=Sync 1=ASync 2=ASync+Save
				switch(_mode) do {
					case 0 : {
						_queryResult = _key;
					};
					case 1 : {
						_queryResult = [1, true];
					};
					case 2 : {
						uisleep (random .03);
				
						_queryResult = "";
						_loop = true;
						while{_loop} do {
							_queryResult = "extDB2" callExtension format["4:%1", _key select 1];
							if (_queryResult isEqualTo "[5]") then {
								_queryResult = "";
								while{true} do {
									_pipe = "extDB2" callExtension format["5:%1", _key select 1];
									if(_pipe isEqualTo "") exitWith {_loop = false};
									_queryResult = _queryResult + _pipe;
								};
							}else{
								if (_queryResult isEqualTo "[3]") then {
									diag_log format ["extDB2: uisleep [4]: %1", diag_tickTime];
									uisleep 0.1;
								} else {
									_loop = false;
								};
							};
						};
						
						_queryResult = call compile _queryResult;
					};
					default {};
				};
			};
			
			if ((_queryResult select 0) isEqualTo 0) then {
				MEMBER("sendError", (_queryResult select 1) + "-->" + _queryStmt);
			};
			_queryResult;
		};
				
		PRIVATE FUNCTION("string", "connectDatabase") {
			private ["_return", "_result"];

			_return = false;	
			_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE:%1", _this]);
			
			if !(isNil "_result") then {
				if ((_result select 0) isEqualTo 1) then {
					MEMBER("sendLog", "Connected to " + _this);
					_return = true;
				}else{
					if(tolower(_result select 1) isEqualTo "already connected to database") then {
						MEMBER("sendLog", "Connected to " + _this);
						_return = true;
					} else {
						MEMBER("sendError", _result select 1);
					};
				};
			}else{
				MEMBER("sendError", "Unable to connect to database - extDB2 locked");
			};	
			_return;
		};

		PUBLIC FUNCTION("", "disconnectDatabase") {

		};

		PUBLIC FUNCTION("", "isconnectedDatabase") {

		};		
				
		PRIVATE FUNCTION("", "getDllVersion") {
			private ["_version"];
			_version = "extDB2" callExtension "9:VERSION";
			if(_version isequalto "") then {
				_version = 0;
			} else {
				_version = parsenumber _version;
			};
			_version;
		};
				
		PRIVATE FUNCTION("string", "sendLog") {
			diag_log (format ["extDB2 log: %1", _this]);
		};
		
		PRIVATE FUNCTION("string", "sendError") {
			private ["_error"];
			_error = format["extDB2 Error: %1", _this];
			_error call BIS_fnc_error;
			diag_log _error;
		};

		PUBLIC FUNCTION("", "deconstructor") {
			//TODO: ? DATABASE DISCONNECT ?
			DELETE_VARIABLE("sessionid");
			DELETE_VARIABLE("dllversionrequired");
			DELETE_VARIABLE("databasename");
			DELETE_VARIABLE("protolist");
		};		
		
	ENDCLASS;