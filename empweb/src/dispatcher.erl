%% Feel free to use, reuse and abuse the code in this file.

-module(dispatcher).
-export([dispatch/0]).

dispatch()->
    [
        {'_', [
            {[<<"jsonapi">>],    handler_jsonapi,    []},
            {[<<"static">>, '...'],    handler_static, [{path, <<"priv/static">>}]},
            {'_', handler_default, []}
        ]}
    ].




%% dispatch()->
%%     [
%%         {[<<"static">> , '_'], [
%% 
%%             {['...'], handler_static, [{path, <<"priv/static">>}]},
%%             {'_', handler_default, []}
%%         ]},
%%         
%%         {'_', [
%% %%             {[<<"websocket">>], handler_websocket, []},
%% %%             {[<<"eventsource">>], handler_eventsource, []},
%% %%             {[<<"eventsource">>, <<"live">>], handler_eventsource_emitter, []},
%% 
%%             {[<<"api">>, '...'],    handler_api,    []},
%%             {[<<"static">>, '...'], handler_static, [{path, <<"priv/static">>}]},
%%             {'_', handler_default, []}
%%         ]}
%%     ].
%% 
