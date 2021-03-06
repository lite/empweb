%% Author: w-495
%% Created: 25.07.2012
%% Description: TODO: Add description to biz_user
-module(empdb_dao_message).
-behaviour(empdb_dao).

%% ===========================================================================
%% Заголовочные файлы
%% ===========================================================================

%% ===========================================================================
%% Экспортируемые функции
%% ===========================================================================

%%
%% Само сообщение непосредственно
%%
-export([
    table/1,
    table/0,
    create/2,
    update/2,
    get/2,
    get/3,
    count/2,
    count/3
]).

%%
%% Типы сообщений
%%
-export([
    update_messagetype/2,
    create_messagetype/2,
    get_messagetype/2,
    get_messagetype/3
]).

%% ===========================================================================
%% Внешние функции
%% ===========================================================================

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Сами сообщения
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% @doc Возвращает список обязательных полей таблицы для создания
%%
table({fields, insert, required})-> [];

%%
%% @doc Возвращает список полей таблицы для выборки
%%
table({fields, select})->
    table({fields, all});

%%
%% @doc Возвращает список полей таблицы для обновления
%%
table({fields, update})->
    table({fields, all}) -- [id];

%%
%% @doc Возвращает список полей таблицы для создания
%%
table({fields, insert})->
    table({fields, all}) -- [id, isdfo, isdfr];

%%
%% @doc Возвращает полный список полей таблицы
%%
table({fields, all})->
    [
        doc_id,
        messagetype_id,
        messagetype_alias,
        reader_id,
        reader_nick,
        isdfo,
        isdfr
    ];

%%
%% @doc Возвращает полный список полей таблицы
%%
table(fields)->
    table({fields, all});

%%
%% @doc Возвращает имя таблицы
%%
table(name)->
    message.

table()->
    table(name).

get(Con, What) ->
    empdb_dao_doc:get(?MODULE, Con, What).

get(Con, What, Fields)->
    empdb_dao_doc:get(?MODULE, Con, What, Fields).


count(Con, What) ->
    empdb_dao_doc:count(?MODULE, Con, What).

count(Con, What, Fields)->
    empdb_dao_doc:count(?MODULE, Con, What, Fields).


create(Con, Proplist)->
    empdb_dao_doc:create(?MODULE, Con, Proplist).

update(Con, Proplist)->
    io:format("~n <<<< Proplist  = ~p >>>> ~n", [Proplist]),
    empdb_dao_doc:update(?MODULE, Con, Proplist).

is_owner(Con, Owner_id, Obj_id) ->
    empdb_dao_doc:is_owner(Con, Owner_id, Obj_id).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Типы сообщений
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_messagetype(Con, What) ->
    empdb_dao:get(messagetype(), Con, What).

get_messagetype(Con, What, Fields)->
    empdb_dao:get(messagetype(), Con, What, Fields).

create_messagetype(Con, Proplist)->
    empdb_dao:get(messagetype(), Con, Proplist).

update_messagetype(Con, Proplist)->
    empdb_dao:get(messagetype(), Con, Proplist).

%% ===========================================================================
%% Внутренние функции
%% ===========================================================================

%%
%% @doc Описывает типы сообщений
%%
messagetype() ->
    [
        %% Имя таблицы.
        {{table, name},                       messagetype},
        %% Список всех полей.
        {{table, fields, all},                [
            id, name_ti, alias, isdeleted
        ]},
        %% Список полей по которым можно проводить выборку.
        {{table, fields, select},             [
            id, name_ti, alias
        ]},
        %% Список полей таблицы для создания.
        {{table, fields, insert},             [
            name_ti, alias
        ]},
        %% Список полей таблицы для обновления.
        {{table, fields, update},             [
            name_ti, alias
        ]},
        %% Cписок обязательных полей таблицы для создания.
        {{table, fields, insert, required},   [
            alias
        ]}
    ].

