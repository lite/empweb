%% Author: w-495
%% Created: 25.07.2012
%% Description: TODO: Add description to biz_user
-module(empdb_biz_roomlot).

%% ===========================================================================
%% Заголовочные файлы
%% ===========================================================================

%%
%% Структры для работы с запросами к базе данных
%%
-include("empdb.hrl").


%% ==========================================================================
%% Экспортируемые функции
%% ==========================================================================

%%
%% Блоги
%%
-export([
    get/1,
    get/2,
    create/1,
    update/1,
    timeout/0
]).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%                          ЗНАЧИМЫЕ ОБЪЕКТЫ
%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Блоги
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create(Params)->
    empdb_dao:with_connection(fun(Con)->
        empdb_dao_roomlot:create(Con, Params)
    end).

update(Params)->
    empdb_dao:with_connection(fun(Con)->
        empdb_dao_roomlot:update(Con, Params)
    end).

get(Params)->
    empdb_dao:with_connection(fun(Con)->
        empdb_dao_roomlot:get(Con, [{isdeleted, false}|Params])
    end).

get(Params, Fileds)->
    empdb_dao:with_connection(fun(Con)->
        empdb_dao_roomlot:get(Con, [{isdeleted, false}|Params], Fileds)
    end).

is_blog_owner(Uid, Oid)->
    empdb_dao:with_connection(fun(Con)->
        empdb_dao_roomlot:is_owner(Con, Uid, Oid)
    end).


timeout()->
    remove_expired().

remove_expired()->
    empdb_dao:with_transaction(fun(Con)->
        Now = nowsec(),
        {ok, Roomlots} = empdb_dao_roomlot:update(Con,[
            {filter, [
                {isdeleted, false},
                {dtstop, {lt, Now}}
            ]},
            {fields, [
                id,
                room_id,    owner_id,
                dtstart,    dtstop,
                betmin,     betmax
            ]},
            {values, [
                {isdeleted, true}
            ]}
        ]),
        lists:map(
            fun({Roomlotpl}) ->
                Roomlot_owner_id    = proplists:get_value(owner_id, Roomlotpl),
                Roomlot_id          = proplists:get_value(id,       Roomlotpl),
                Room_id             = proplists:get_value(room_id,  Roomlotpl),
                {ok, [{Maxbetpl}]} =
                    empdb_dao_roombet:get(Con, [
                        {isdeleted, false},
                        {roomlot_id, Roomlot_id},
                        {limit, 1},
                        {order, [
                            {desc, price},
                            {asc, created}
                        ]}
                    ]),
                Owner_id    = proplists:get_value(owner_id, Maxbetpl),
                Price       = proplists:get_value(price,    Maxbetpl),
                {ok, _} =
                    empdb_dao_pers:update(Con, [
                        {id,        Roomlot_owner_id},
                        {money,     {incr, Price}}
                    ]),
                {ok, _} =
                    empdb_dao_room:update(Con, [
                        {id,        Room_id},
                        {owner_id,  Owner_id}
                    ])
            end,
            Roomlots
        ),
        {ok, Roomlots}
    end).

nowsec() ->
    {Mgs,Sec, _mis} = erlang:now(),
    Now = Mgs * 1000000 + Sec,
    Now.