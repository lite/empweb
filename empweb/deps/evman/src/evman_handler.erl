%%%
%%% @file evman_gen_handler.erl
%%%   Абстрактный обработчик событий.
%%%   Можно переобределить его методы с помощью.
%%%
%%%     -behaviour(gen_event).
%%%     -extends(evman_gen_handler).
%%%

-module(evman_handler).

-include("evman.hrl").

-define(HANDLERNAME, ?MODULE).

-export([
  init/1,
  handle_event/2,
  handle_call/2,
  handle_info/2,
  terminate/2,
  code_change/3
]).

-record(state, {}).

init([]) ->
  {ok, #state{}}.

%%%
%%% -----------------------------------------------------------------------
%%%

% handle_event({evman_customer, {change, {perm, {add, {insider, Insider}}}}}, State) ->
%   {ok, State};
% 
% handle_event({evman_customer, {change, {perm, {add, Perm}}}}, State) ->
%   {ok, State};
% 
% 
% handle_event({evman_customer, {change, {perm, {del, {insider, Insider}}}}}, State) ->
%   {ok, State};
% 
% handle_event({evman_customer, {change, {perm, {del, Perm}} }}, State) ->
%   {ok, State};
% 
% handle_event({evman_customer, {change, {perm, Perm} }}, State) ->
% 
%   {ok, State};
% 
% handle_event({evman_customer, {change, Changes }}, State) ->
%   {ok, State};

% handle_event({evman_customer, _event}, State) ->
%   {ok, State};


  
handle_event({_sender, _event}, State) ->
    lists:seq(1, 10000000),
    lists:seq(1, 10000000),
    lists:seq(1, 10000000),
    ?debug("~p ~p has event from ~p, `~p' and state `~p' ~n",
      [?HANDLERNAME, self(), _sender, _event, State]),
  {ok, State};

handle_event(_event, State) ->
  ?debug("~p ~p has event `~p' and state `~p' ~n",
    [?HANDLERNAME, self(), _event, State]),
  {ok, State}.

%%%
%%% -----------------------------------------------------------------------
%%%

handle_call(_request, State) ->
  ?debug("~p ~p has call `~p' and state `~p' ~n",
    [?HANDLERNAME, self(), _request, State]),
  {ok, ok, State}.

handle_info(_info, State) ->
  %   ?debug("~p ~p has info `~p' and state `~p' ~n",
  %     [?HANDLERNAME, self(), _info, State]),
  {ok, State}.

terminate(_reason, _state) ->
  ?debug("~p ~p was terminate with reason `~p' and state `~p' ~n",
    [?HANDLERNAME, self(), _reason, _state]),
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.


%%%
%%% -----------------------------------------------------------------------
%%%

customer_facade(_mod, _fun, _data) ->
  ?debug("abstruct customer_facade ~p", [?HANDLERNAME]),
  ok.

acv_video_facade(_mod, _fun, _data) ->
  ?debug("abstruct acv_video_facade ~p", [?HANDLERNAME]),
  ok.
