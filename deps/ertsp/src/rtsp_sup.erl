%% @private
-module(rtsp_sup).
-author(max@maxidoors.ru).

-behaviour(supervisor).

-export ([init/1,start_link/0]).
-export([start_rtsp_connecton/0, start_rtsp_session/2]).
-export([start_rtsp_listener/2]).

%%--------------------------------------------------------------------
%% @spec () -> any()
%% @doc A startup function for whole supervisor. Started by application
%% @end 
%%--------------------------------------------------------------------
-spec(start_link() -> {error,_} | {ok,pid()}).
start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_rtsp_connecton() -> supervisor:start_child(rtsp_connecton_sup, []).
start_rtsp_session(Consumer, Type) -> supervisor:start_child(rtsp_session_sup, [Consumer, Type]).

start_rtsp_listener(Port, Callback) ->
  Listener = {rtsp_listener,
  {rtsp_listener, start_link ,[Port, Callback]},
  permanent,
  10000,
  worker,
  [rtsp_listener]},
  supervisor:start_child(?MODULE, Listener).
  

init([rtsp_connection]) ->
  {ok,
    {{simple_one_for_one, 5, 60},
      [
        {   undefined,                               % Id       = internal id
            {rtsp_connecton,start_link,[]},             % StartFun = {M, F, A}
            temporary,                               % Restart  = permanent | transient | temporary
            2000,                                    % Shutdown = brutal_kill | int() >= 0 | infinity
            worker,                                  % Type     = worker | supervisor
            []                            % Modules  = [Module] | dynamic
        }
      ]
    }
  };

init([rtsp_session]) ->
  {ok,
    {{simple_one_for_one, 5, 60},
      [
        {   undefined,                               % Id       = internal id
            {rtsp,start_link,[]},             % StartFun = {M, F, A}
            temporary,                               % Restart  = permanent | transient | temporary
            2000,                                    % Shutdown = brutal_kill | int() >= 0 | infinity
            worker,                                  % Type     = worker | supervisor
            []                            % Modules  = [Module] | dynamic
        }
      ]
    }
  };


init([]) ->
  Supervisors = [
    {rtsp_sessions_sup,                       % Id       = internal id
      {rtsp_sessions,start_link,[]},          % StartFun = {M, F, A}
      permanent,                               % Restart  = permanent | transient | temporary
      2000,                                    % Shutdown = brutal_kill | int() >= 0 | infinity
      worker,                                  % Type     = worker | supervisor
      [rtsp_sessions]                         % Modules  = [Module] | dynamic
    },
    {rtsp_session_sup,
      {supervisor,start_link,[{local, rtsp_session_sup}, ?MODULE, [rtsp_session]]},
      permanent,                               % Restart  = permanent | transient | temporary
      infinity,                                % Shutdown = brutal_kill | int() >= 0 | infinity
      supervisor,                              % Type     = worker | supervisor
      []                                       % Modules  = [Module] | dynamic
    },
    {rtsp_connection_sup,
      {supervisor,start_link,[{local, rtsp_connection_sup}, ?MODULE, [rtsp_connection]]},
      permanent,                               % Restart  = permanent | transient | temporary
      infinity,                                % Shutdown = brutal_kill | int() >= 0 | infinity
      supervisor,                              % Type     = worker | supervisor
      []                                       % Modules  = [Module] | dynamic
    }
  ],
  
  {ok, {{one_for_one, 3, 10}, Supervisors}}.
