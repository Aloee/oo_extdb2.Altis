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
		
		PRIVATE VARIABLE("scalar", "requiredDllVersion");
		PRIVATE VARIABLE("string", "databaseName");
		PRIVATE VARIABLE("string", "defaultProtocolID");
		PRIVATE VARIABLE("array", "protoList");
		PRIVATE VARIABLE("scalar", "version");

		PUBLIC FUNCTION("array", "constructor") {
			
			MEMBER("version", 0.1);
			MEMBER("requiredDllVersion", 62);

			private ["_database", "_protocol", "_protocolOptions", "_varNameDatabase"];

			if!(MEMBER("checkExtDB2isLoaded", nil)) exitwith { MEMBER("sendError", "OO_extDB required extDB2 Dll"); };
			if!(MEMBER("checkDllVersion", nil)) exitwith { MEMBER("sendLog", "Required extDB2 Dll version is " + (str MEMBER("requiredDllVersion", nil)) + " or higher."); };

			// Too much things that made differents tasks :)
			
			_database =        [_this, 0, "", [""]] call BIS_fnc_param;
			_protocol =        [_this, 1, "", [""]] call BIS_fnc_param;
			_protocolOptions = [_this, 2, "", [""]] call BIS_fnc_param;
			_lock =            [_this, 3, true, [true]] call BIS_fnc_param;
			
			_varNameDatabase = format ["OO_EXTDB_%1", toUpper _database];
			MEMBER("databaseName", _varNameDatabase);

			if (isNil {uiNamespace getVariable _varNameDatabase}) then {
				uiNamespace setVariable [_varNameDatabase, []];
				
				//Add Database
				if(MEMBER("connectDatabase", _database)) then {
					MEMBER("sendLog", "Connected to " + _database);
					
					//Load protocol
					private ["_protocolParams"];
					_protocolParams = [_database, _protocol, str(round(random(999999))), _protocolOptions];
						
					if(MEMBER("loadDatabaseProtocol", _protocolParams)) then {				
						MEMBER("defaultProtocolID", _protocolParams select 2);
						uiNamespace setVariable [_varNameDatabase, [["defaultProtocol", _protocolParams select 2]]];
						if(_lock) then { MEMBER("lock", nil) };							
					};
				};
			}else{
				private ["_savedProtocolDefault", "_savedProtocolList"];
				
				_savedProtocolDefault = [uiNamespace getVariable _varNameDatabase, "defaultProtocol"] call BIS_fnc_getFromPairs;
				_savedProtocolList = [uiNamespace getVariable _varNameDatabase, "protoList"] call BIS_fnc_getFromPairs;
				
				MEMBER("defaultProtocolID", _savedProtocolDefault);
				MEMBER("protoList", _savedProtocolList);
				MEMBER("sendLog", "Already connected");
			};
		};

		PUBLIC FUNCTION("", checkDllVersion) {
			private ["_return"];

			_return = false;			

			if((MEMBER("getDllVersion", nil) > MEMBER("requiredDllVersion", nil)) then {
				return true;
			};
		};

		PUBLIC FUNCTION("", checkExtDB2isLoaded) {
			if((MEMBER("getDllVersion", nil) == 0) then { false; } else { true;};
		};

		PUBLIC FUNCTION("", "getVersion") {
			 format["OO_extDB2: %1 Dll: %2", MEMBER("getDllVersion", nil), MEMBER("version", nil)];
		};
		
		PUBLIC FUNCTION("string", "useDatabaseProtocol") {
			private ["_return", "_protoPairs", "_nowUsedId"];
			
			_return = false;
			_protoPairs = MEMBER("protoList", nil);
			
			if([_protoPairs, _this] call BIS_fnc_findInPairs >= 0) then {
				_nowUsedId = [_protoPairs, _this] call BIS_fnc_getFromPairs;
				MEMBER("defaultProtocolID", _nowUsedId);
				_return = true;
			};
		
		_return
		};
		
		PUBLIC FUNCTION("", "lock") {
			private ["_return", "_result"];
			
			_result = call compile ("extDB2" callExtension "9:LOCK");
			_return = false;
			
			if ((_result select 0) isEqualTo 1) then {
				_return = true;
				MEMBER("sendLog", "Locked");
			};
			
		_return
		};
		
		PUBLIC FUNCTION("", "locked") {
			private ["_return", "_result"];
			
			_result = call compile ("extDB2" callExtension "9:LOCK_STATUS");
			_return = false;
			
			if((_result select 0) isEqualTo 1) then {
				_return = true;
			};
			
		_return
		};
		
		PUBLIC FUNCTION("array", "loadDatabaseProtocol") {
			private ["_return", "_result"];
			_this params [["_database", ""], ["_protocol", ""], ["_id", ""], ["_protocolOptions", ""]];
			
			_return = false;
			
			if(MEMBER("findDatabaseProtocol", _id) < 0) then {
				
				_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE_PROTOCOL:%1:%2:%3:%4", 
					_database,
					_protocol,
					_id,
					_protocolOptions
				]);
				
				if ((_result select 0) isEqualTo 1) then {
					MEMBER("sendLog", "Protocol loaded - " + _protocol);
					_return = true;
					
					private ["_protocolPair"];
					_protocolPair = [_protocol, _id];
					MEMBER("updateProtoList", _protocolPair);
				}else{
					MEMBER("sendError", _result select 1);
				};
			}else{
				MEMBER("sendLog", "Protocol load canceled - name '" + _id + "' already taken");
			};
						
		_return
		};
				
		PUBLIC FUNCTION("array", "sendRequest") {
			private["_queryResult", "_key", "_mode", "_loop"];
			
			_queryResult = [0, "Syntax error"];
			
			if (_this params [["_mode", 0, [0]], ["_queryStmt", "", [""]]]) then {
			
				_key = call compile ("extDB2" callExtension format["%1:%2:%3",_mode, MEMBER("defaultProtocolID", nil), _queryStmt]);

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
			
		_queryResult
		};
				
		PRIVATE FUNCTION("string", "connectDatabase") {
			private ["_return", "_result"];
			
			_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE:%1", _this]);
			_return = false;
			
			if !(isNil "_result") then {
				if ((_result select 0) isEqualTo 1) then {
					MEMBER("sendLog", "Database added: " + _this);
					_return = true;
				}else{
					MEMBER("sendError", _result select 1);
				};
			}else{
				MEMBER("sendError", "Unable to add database - extDB2 locked");
			};	
		_return
		};

		PUBLIC FUNCTION("", disconnectDatabase) {

		};

		PUBLIC FUNCTION("", isconnectedDatabase) {

		};		
		
		PRIVATE FUNCTION("string", "findDatabaseProtocol") {
			private ["_return"];
			
			_return = -1;
			{
				if((_x select 1) isEqualTo _this) exitWith {_return=_foreachIndex};
			} foreach (MEMBER("protoList", nil));
			
		_return
		};
		
		PRIVATE FUNCTION("array", "updateProtoList") {
			private ["_loadedProtocols"];
			
			_this params ["_protocol", "_protocolId"];
			
			if (isNil {MEMBER("protoList", nil)}) then {MEMBER("protoList", [])};
			_loadedProtocols = MEMBER("protoList", nil);

			if([_loadedProtocols, _protocol] call BIS_fnc_findInPairs < 0) then {
				[_loadedProtocols, _protocol, _protocolId] call BIS_fnc_addToPairs;
			}else{
				[_loadedProtocols, _protocol, _protocolId] call BIS_fnc_setToPairs;
			};
			
			MEMBER("protoList", _loadedProtocols);
			
			private ["_databaseVar"];
			_databaseVar = uiNamespace getVariable (MEMBER("databaseName", nil));
			[_databaseVar, "protoList", _loadedProtocols] call BIS_fnc_setToPairs;
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
			DELETE_VARIABLE("defaultProtocolID");
			DELETE_VARIABLE("requiredDllVersion");
			DELETE_VARIABLE("databaseName");
			DELETE_VARIABLE("protoList");
		};		
		
	ENDCLASS;