	
	#include "oop.h"

	CLASS("OO_extDb2")

		PRIVATE STATIC_VARIABLE("string", "connectID");

		PUBLIC FUNCTION("array", "constructor") {
			
			private ["_version", "_database", "_protocol", "_protocolOptions"];
			
			_database =        [_this, 0, "", [""]] call BIS_fnc_param;
			_protocol =        [_this, 1, "", [""]] call BIS_fnc_param;
			_protocolOptions = [_this, 2, "", [""]] call BIS_fnc_param;

			if (isNil {uiNamespace getVariable "extDB_SQL_CUSTOM_ID"}) then {
				
				_version = MEMBER("getVersion", nil);
				if(_version != "") then {
					MEMBER("sendLog", "Version: " + _version);
					
					//Add Database
					if(MEMBER("addDatabase", _database)) then {
						
						//Load protocol
						private ["_protocolParams"];
						_protocolParams = [_database, _protocol, str(round(random(999999))), _protocolOptions];
						
						if(MEMBER("loadDatabaseProtocol", _protocolParams)) then {
						
							MEMBER("connectID", _protocolParams select 2);
							uiNamespace setVariable ["extDB_SQL_CUSTOM_ID", _protocolParams select 2];
							
							MEMBER("lock", nil);							
						};
					};
				}else{
					MEMBER("sendError", "Failed to Load");
				};
			}else{
				MEMBER("connectID", uiNamespace getVariable "extDB_SQL_CUSTOM_ID");
				MEMBER("sendLog", "Already connected");
			};
		};
		
		PUBLIC FUNCTION("string", "deconstructor") {
			DELETE_VARIABLE("connectID");
		};
		
		PUBLIC FUNCTION("", "getConnectID") FUNC_GETVAR("connectID");
				
		PRIVATE FUNCTION("string", "addDatabase") {
			private ["_return", "_result"];
			
			_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE:%1", _this]);
			_return = false;
			
			if ((_result select 0) isEqualTo 1) then {
				MEMBER("sendLog", "Database added: " + _this);
				_return = true;
			}else{
				MEMBER("sendError", _result select 1);
			};
			
		_return
		};
		
		PRIVATE FUNCTION("array", "loadDatabaseProtocol") {
			_this params ["_database", "_protocol", "_id", "_protocolOptions"];
			private ["_return", "_result"];
			
			_return = false;
			_result = call compile ("extDB2" callExtension format["9:ADD_DATABASE_PROTOCOL:%1:%2:%3:%4", 
				_database,
				_protocol,
				_id,
				_protocolOptions
			]);
			
			if ((_result select 0) isEqualTo 1) then {
				MEMBER("sendLog", "Protocol loaded - " + _protocol);
				_return = true;
			}else{
				MEMBER("sendError", _result select 1);
			};
			
		_return
		};
		
		PRIVATE FUNCTION("", "getVersion") {
			"extDB2" callExtension "9:VERSION";
		};
		
		PRIVATE FUNCTION("", "lock") {
			private ["_return", "_result"];
			
			_result = call compile ("extDB2" callExtension "9:LOCK");
			_return = false;
			
			if ((_result select 0) isEqualTo 1) then {
				_return = true;
				MEMBER("sendLog", "Locked");
			};
			
		_return
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
		
	ENDCLASS;