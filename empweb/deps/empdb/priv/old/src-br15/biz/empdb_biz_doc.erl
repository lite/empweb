%% Author: w-495
%% Created: 25.07.2012
%% Description: TODO: Add description to biz_user
-module(empdb_biz_doc).

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

%% --------------------------------------------------------------------------
%% УТИЛИТАРНЫЕ ОБЪЕКТЫ
%% --------------------------------------------------------------------------

%%
%% Тип разрешения: не рассмотрен, запрещена, разрешена
%%
-export([
    get_oktype/1,
    get_oktype/2,
    create_oktype/1,
    update_oktype/1
]).

%%
%% Тип документа: Блог, коммент к блогу, галерея,
%%      фото, коммент к фото, attach descr.
%%
-export([
    update_doctype/1,
    create_doctype/1,
    get_doctype/1,
    get_doctype/2
]).

%%
%% Типы контента: обычный, эротический
%%
-export([
    update_contype/1,
    create_contype/1,
    get_contype/1,
    get_contype/2
]).


%%
%% Тип доступа к контенту контента (блога и галереи):
%%  приватный, дружеский, открытый.
%%
-export([
    update_acctype/1,
    create_acctype/1,
    get_acctype/1,
    get_acctype/2
]).

%%
%% Типы чат-комнат. (страна, тюрьма, ад, рай).
%%
-export([
    get_roomtype/1,
    get_roomtype/2,
    create_roomtype/1,
    update_roomtype/1
]).

%%
%% Список языков чата.
%%
-export([
    get_chatlang/1,
    get_chatlang/2,
    create_chatlang/1,
    update_chatlang/1
]).

%%
%% Список режимов комнаты: дектатура, демократия и пр.
%%
-export([
    get_regimen/1,
    get_regimen/2,
    create_regimen/1,
    update_regimen/1
]).

%%
%% Дерево тем комнаты.
%% -------------------------------------------------
%%  [Все темы]
%%      |-[Автомобили]
%%          |-[Хорошие]
%%              |-[Чайка]
%%              |-[Уазик]
%%          |-[Плохие]
%%              |-[Калина]
%%              |-[Запорожец]
%%      ...
%% -------------------------------------------------
%%
-export([
    get_topic/1,
    get_topic/2,
    create_topic/1,
    update_topic/1
]).


%%
%% Типы сообществ (обычные, тайные)
%%
-export([
    get_communitytype/1,
    get_communitytype/2,
    create_communitytype/1,
    update_communitytype/1
]).

%%
%% Типы сообщений
%%
-export([
    get_messagetype/1,
    get_messagetype/2,
    create_messagetype/1,
    update_messagetype/1
]).


%% --------------------------------------------------------------------------
%% ЗНАЧИМЫЕ ОБЪЕКТЫ
%% --------------------------------------------------------------------------

%%
%% Блоги
%%
-export([
    get_blog/1,
    get_blog/2,
    create_blog/1,
    update_blog/1,
    delete_blog/1
]).

%%
%% Посты
%%
-export([
    get_post/1,
    get_post/2,
    get_post_top/1,
    create_post/1,
    repost_post/1,
    update_post/1,
    delete_post/1
]).


%%
%% Коменты
%%
-export([
    get_comment/1,
    get_comment/2,
    repost_comment/1,
    create_comment/1,
    update_comment/1,
    delete_comment/1
]).


%%
%% Сообщения
%%
-export([
    get_message/1,
    get_message/2,
    get_message_for_me/1,
    get_message_for_me/2,
    get_message_from_me/1,
    get_message_from_me/2,
    readall_message_for_me/1,

    count_message/1,
    count_message_types/1,
    count_message_for_me/1,
    count_message_from_me/1,

    create_message/1,
    update_message/1,

    delete_message_for_me/1,
    delete_message_from_me/1,
    delete_message/1
]).


%%
%% API Functions
%%

%%
%% Репост
%%
-export([
    repost/3,
    repost/4
]).


repost(Module, Con, Params)->
    repost({Module, get}, {Module, create}, Con, Params).

repost({Getmodule, Get}, {Createmodule, Create}, Con, Params)->
    Doc_id      = proplists:get_value(id, Params,
        proplists:get_value(doc_id, Params)
    ),
    Owner_id    = proplists:get_value(owner_id,     Params, null),
    Owner_nick  = proplists:get_value(owner_nick,   Params, null),
    Parent_id   = proplists:get_value(parent_id,    Params, null),
    Fields      = proplists:get_value(fields,       Params, [id]),


    Mbrepostlist =
        Getmodule:Get(Con, [
            {orig_id, Doc_id},
            {'or', [
                {owner_id, Owner_id},
                {owner_nick, Owner_nick}
            ]},
            {limit, 1}
        ]),


    {ok, [{Instpl}]} = Getmodule:Get(Con, [{id, Doc_id}]),

    %%
    %% Репосты конкретного документа,
    %% конкретным пользователя
    %% должны быть уникальны
    %%
    case {proplists:get_value(isrepostable, Instpl), Mbrepostlist} of
        {false, _} ->
            {error, forbiden};
        {true, {ok, [{Repostpl}]}} ->
            {error, {not_uniq_repost, {Repostpl}}};
        {true, {ok, []}} ->
            Orig_id          = repost_orig(id, orig_id, Instpl),
            Orig_owner_id    = repost_orig(owner_id, orig_owner_id, Instpl),
            Orig_owner_nick  = repost_orig(owner_nick, orig_owner_nick, Instpl),
            Preinstpl =
                proplists:delete(id,
                    proplists:delete(owner_id,
                        proplists:delete(owner_nick,
                            proplists:delete(orig_id,
                                proplists:delete(orig_owner_id,
                                    proplists:delete(orig_owner_nick,
                                        proplists:delete(parent_id,
                                            proplists:delete(created,
                                                Instpl
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                ),
            case Createmodule:Create(Con, [
                {parent_id,         Parent_id},
                {owner_id,          Owner_id},
                {owner_nick,        Owner_nick},
                {orig_id,           Orig_id},
                {orig_owner_id,     Orig_owner_id},
                {orig_owner_nick,   Orig_owner_nick},
                {isrepost,          true},
                {fields,            Fields}
                |Preinstpl
            ]) of
                {ok, [{Newinstpl}]} ->
%                     {ok, _} =
%                         empdb_dao_event:create(Con, [
%                             {owner_id, Orig_owner_id},
%                             {pers_id,  Owner_id},
%                             {friendtype_id, proplists:get_value(friendtype_id, Friendpl)},
%                             {eventtype_alias, new_friend}
%                         ]),
                    {ok, _} = empdb_dao_repost:create(Con, [
                        {doc_id,            proplists:get_value(id, Newinstpl)},
                        {owner_id,          Owner_id},
                        {owner_nick,        Owner_nick},
                        {orig_doc_id,       Orig_id},
                        {orig_owner_id,     Orig_owner_id},
                        {orig_owner_nick,   Orig_owner_nick}
                    ]),
                    {ok, [{Newinstpl}]};
                Else ->
                    Else
            end
    end.

repost_orig(Field, Orig_field, Instpl)->
    case
        proplists:get_value(Orig_field, Instpl,
            proplists:get_value(Field, Instpl)
        )
    of
        null ->
            proplists:get_value(Field, Instpl);
        Else ->
            Else
    end.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%                          УТИЛИТАРНЫЕ ОБЪЕКТЫ
%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Тип разрешения: не рассмотрен, запрещена, разрешена
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_oktype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:create_oktype(Con, Params)
    end).

update_oktype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:update_oktype(Con, Params)
    end).

get_oktype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_oktype(Con, [{isdeleted, false}|Params])
    end).

get_oktype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_oktype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Тип документа: Блог, коммент к блогу, галерея,
%%      фото, коммент к фото, attach descr.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_doctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:create_doctype(Con, Params)
    end).

update_doctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:update_doctype(Con, Params)
    end).

get_doctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_doctype(Con, [{isdeleted, false}|Params])
    end).

get_doctype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_doctype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Типы контента: обычный, эротический
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_contype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:create_contype(Con, Params)
    end).

update_contype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:update_contype(Con, Params)
    end).

get_contype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_contype(Con, [{isdeleted, false}|Params])
    end).

get_contype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_contype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Тип доступа к контенту контента (блога и галереи):
%%  приватный, дружеский, открытый.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_acctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:create_acctype(Con, Params)
    end).

update_acctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:update_acctype(Con, Params)
    end).

get_acctype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_acctype(Con, [{isdeleted, false}|Params])
    end).

get_acctype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_doc:get_acctype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Типы чат-комнат. (страна, тюрьма, ад, рай)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_roomtype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:create_roomtype(Con, Params)
    end).

update_roomtype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:update_roomtype(Con, Params)
    end).

get_roomtype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_roomtype(Con, [{isdeleted, false}|Params])
    end).

get_roomtype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_roomtype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Список языков чата.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_chatlang(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:create_chatlang(Con, Params)
    end).

update_chatlang(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:update_chatlang(Con, Params)
    end).

get_chatlang(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_chatlang(Con, [{isdeleted, false}|Params])
    end).

get_chatlang(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_chatlang(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Список режимов комнаты: дектатура, демократия и пр.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_regimen(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:create_regimen(Con, Params)
    end).

update_regimen(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:update_regimen(Con, Params)
    end).

get_regimen(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_regimen(Con, [{isdeleted, false}|Params])
    end).

get_regimen(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_regimen(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Дерево тем комнаты
%% -------------------------------------------------
%%   Все темы
%%      └──Автомобили
%%          ├─Хорошие
%%          │   ├─Чайка
%%          │   └─Уазик
%%          └─Плохие
%%              ├─Калина
%%              └─Запорожец
%%      ...
%% -------------------------------------------------
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_topic(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:create_topic(Con, Params)
    end).

update_topic(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:update_topic(Con, Params)
    end).

get_topic(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_topic(Con, [
            {isdeleted, false}
            | lists:reverse([
                {order, [
                    {desc, nnodes},
                    {desc, nchildtargets}
                ]}
                |Params
            ])
        ])
    end).

get_topic(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_room:get_topic(Con, [
            {isdeleted, false}
            | lists:reverse([
                {order, [
                    {desc, nnodes},
                    {desc, nchildtargets}
                ]}
                |Params
            ])
        ], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Типы сообществ (обычные, тайные)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_communitytype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_community:create_communitytype(Con, Params)
    end).

update_communitytype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_community:update_communitytype(Con, Params)
    end).

get_communitytype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_community:get_communitytype(Con, [{isdeleted, false}|Params])
    end).

get_communitytype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_community:get_communitytype(Con, [{isdeleted, false}|Params], Fileds)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Типы сообщений
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_messagetype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:create_messagetype(Con, Params)
    end).

update_messagetype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:update_messagetype(Con, Params)
    end).

get_messagetype(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:get_messagetype(Con, [{isdeleted, false}|Params])
    end).

get_messagetype(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:get_messagetype(Con, [{isdeleted, false}|Params], Fileds)
    end).


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%                          ЗНАЧИМЫЕ ОБЪЕКТЫ
%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Блоги
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_blog(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_blog:create(Con, Params)
    end).

update_blog(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_blog:update(Con, Params)
    end).

get_blog(Params)->
    empdb_dao:with_transaction(fun(Con)->
        get_blog_adds(
            Con,
            empdb_dao_blog:get(
                Con,
                [
                    {order, {desc, created}},
                    {isdeleted, false}
                    |Params
                ]
            )
        )
    end).

get_blog(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        get_blog_adds(Con,
            empdb_dao_blog:get(
                Con,
                [
                    {order, {desc, created}},
                    {isdeleted, false}
                    |Params
                ],
                Fileds
            )
        )
    end).

get_blog_adds(Con, Getresult) ->
    case Getresult of
        {ok, List} ->
            {ok, lists:map(fun({Itempl})->
                case proplists:get_value(id, Itempl) of
                    undefined ->
                        {Itempl};
                    Id ->
                        {ok, Postcnts}     = empdb_dao_blog:count_posts(Con, [{id, Id}]),
                        {ok, Comments}     = empdb_dao_blog:count_comments(Con, [{id, Id}]),
                        Npostspl = lists:foldl(fun({Postpl}, Acc)->
                            case proplists:get_value(read_acctype_alias, Postpl) of
                                all ->
                                    [{nposts, proplists:get_value(count, Postpl)}|Acc];
                                public ->
                                    [{npublicposts, proplists:get_value(count, Postpl)}|Acc];
                                private ->
                                    [{nprivateposts, proplists:get_value(count, Postpl)}|Acc];
                                protected ->
                                    [{nprotectedposts, proplists:get_value(count, Postpl)}|Acc];
                                _ ->
                                    Acc
                            end
                        end, [], Postcnts),
                        Ncommentspl = lists:foldl(fun({Commentspl}, Acc)->
                            [{ncomments, proplists:get_value(count, Commentspl)}|Acc]
                        end, [], Comments),
                        {lists:append([Npostspl, Ncommentspl, Itempl])}
                end
            end, List)};
        {Eclass, Error} ->
            {Eclass, Error}
    end.

delete_blog(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_blog:update(Con, [{order, {desc, created}}, {isdeleted, true}|Params])
    end).

is_blog_owner(Uid, Oid)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_blog:is_owner(Con, Uid, Oid)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Посты
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% @doc Добавляет пост в блог.
%% Все действия в одной транзакции.
%%

repost_post(Params)->
    empdb_dao:with_connection(fun(Con)->
        case empdb_biz_doc:repost(
            empdb_dao_post,
            Con,
            [{fields, [owner_id, id]}|Params]
        ) of
            {ok, [{Postpl}]} ->
                empdb_daowp_event:feedfriends([
                    {eventobj_alias,    post},
                    {eventact_alias,    repost},
                    {pers_id,           proplists:get_value(owner_id,   Postpl)},
                    {doc_id,            proplists:get_value(id,         Postpl)},
                    {eventtype_alias,   repost_post}
                ]),
                {ok, [{Postpl}]};
            Else ->
                Else
        end
    end).

create_post(Params)->
    empdb_dao:with_transaction(fun(Con)->
        case empdb_dao_post:create(Con, [{fields, [id, owner_id]}|Params]) of
            {ok, [{Postpl}]} ->
                empdb_daowp_event:feedfriends([
                    {eventobj_alias,    post},
                    {eventact_alias,    create},
                    {pers_id,           proplists:get_value(owner_id, Postpl)},
                    {doc_id,            proplists:get_value(id,     Postpl)},
                    {eventtype_alias,   create_post}
                ]),
                {ok, [{Postpl}]};
            Else ->
                Else
        end
    end).

update_post(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_post:update(Con, Params)
    end).

%%
%% @doc Удаляет пост.
%% Все действия в одной транзакции.
%%
delete_post(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        %% Удаляем
        empdb_dao_post:update(Con, [
            {values, [{isdeleted, true}]},
            {filter, [{isdeleted, false}|Filter]}
        ])
    end).


get_post_top(Params)->
    empdb_dao:with_transaction(fun(Con)->
        get_post_adds(Con, empdb_dao_post:get_top(Con, [{order, {desc, 'post.created'}}, {isdeleted, false}|Params]))
    end).

get_post(Params)->
    empdb_dao:with_transaction(fun(Con)->
        get_post_adds(Con, empdb_dao_post:get(Con, [{order, {desc, 'post.created'}}, {isdeleted, false}|Params]))
    end).

get_post(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        get_post_adds(
            Con, empdb_dao_post:get(Con, [{order,  {desc, 'post.created'}}, {isdeleted, false}|Params], Fileds)
        )
    end).

get_post_adds(Con, Getresult) ->
    case Getresult of
        {ok, List} ->
            {ok, lists:map(fun({Itempl})->
                case proplists:get_value(id, Itempl) of
                    undefined ->
                        {Itempl};
                    Id ->
                        {ok, Comments}     = empdb_dao_post:count_comments(Con, [{id, Id}]),
                        Ncommentspl = lists:foldl(fun({Commentspl}, Acc)->
                            [{ncomments, proplists:get_value(count, Commentspl)}|Acc]
                        end, [], Comments),
                        {lists:append([Ncommentspl, Itempl])}
                end
            end, List)};
        {Eclass, Error} ->
            {Eclass, Error}
    end.

is_post_owner(Uid, Oid)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_post:is_owner(Con, Uid, Oid)
    end).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Kоменты
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% @doc Добавляет комментарий,
%% Все действия в одной транзакции.
%%

repost_comment(Params)->
    empdb_dao:with_connection(fun(Con)->
        empdb_biz_doc:repost(
            empdb_dao_comment,
            Con,
            Params
        )
    end).

create_comment(Params)->
    empdb_dao:with_transaction(fun(Con)->
        %% Создаем
        {ok, [{Parentpl}]} =
            empdb_dao_doc:get(Con, [
                {id, proplists:get_value(parent_id, Params, null)},
                {limit, 1},
                {fields, [owner_id]}
            ]),
        Wfoe =
            empdb_biz_pers:wfoe(
                fun(Con1)->
                    empdb_dao_comment:create(Con1, Params)
                end,
                [
                    {pers_id,   proplists:get_value(owner_id, Parentpl, null)},
                    {friend_id, proplists:get_value(owner_id, Params, null)}
                ]
            ),
        Wfoe(Con)
    end).

update_comment(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_comment:update(Con, Params)
    end).

%%
%% @doc Удаляет комментарий,
%% Все действия в одной транзакции.
%%
delete_comment(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_comment:update(Con, [
            {values, [{isdeleted, true}]},
            {filter, [{isdeleted, false}|Filter]},
            {fields, [parent_id]}
        ])
    end).

get_comment(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_comment:get(Con, [{order, {desc, created}}, {isdeleted, false}|Params])
    end).

get_comment(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_comment:get(Con, [{order, {desc, created}}, {isdeleted, false}|Params], Fileds)
    end).

is_comment_owner(Uid, Oid)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_comment:is_owner(Con, Uid, Oid)
    end).


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Чат-комнаты (комнаты)
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Сообщества
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Сообщения
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
% filterfoe(Function, Options)->
%     case {proplists:get_value(connection,      Options)} of
%         undefined ->
%             empdb_dao:with_transaction(
%                 fun(Connection)->
%                     filterfoe(Connection, Function, [{connection, Connection}|Options])
%                 end
%             );
%         Connection ->
%             filterfoe_(Connection, Function, Options)
%     end.
%
% filterfoe(Connection, Function, Options)->
%     Pers_id     = proplists:get_value(pers_id,      Options),
%     Pers_nick   = proplists:get_value(pers_nick,    Options),
%     Friend_id   = proplists:get_value(friend_id,    Options),
%     Friend_nick = proplists:get_value(friend_nick,  Options),
%     {ok, Objs} = empdb_dao_friend:get(Connection, [
%         {'or', [
%             {pers_id, Pers_id}
%             {pers_nick, Pers_nick}
%         ]},
%         {'or', [
%             {friend_id, Friend_id}
%             {friend_nick, Friend_nick}
%         ]},
%         {friendtype_alias, foe}
%     ]),
%
%     case Objs of
%         [] ->
%             Function()
%         _ ->
%             {error, forbiden}
%     end.
%


create_message(Params)->
    empdb_dao:with_transaction(empdb_biz_pers:wfoe(
        fun(Con)->
            case empdb_dao_message:create(Con, [{fields, [reader_id, id, owner_id]}|Params]) of
                {ok, [{Messpl}]} ->
                    empdb_dao_event:create(Con, [
                        {eventobj_alias,    message},
                        {eventact_alias,    create},
                        {owner_id,          proplists:get_value(reader_id, Messpl)},
                        {doc_id,            proplists:get_value(id, Messpl)},
                        {pers_id,           proplists:get_value(owner_id, Messpl)},
                        {eventtype_alias,   create_message}
                    ]),
                    {ok, [{Messpl}]};
                Else ->
                    Else
            end
        end,
        [
            {friend_id,     proplists:get_value(owner_id, Params)},
            {friend_nick,   proplists:get_value(owner_nick, Params)},
            {pers_id,       proplists:get_value(reader_id, Params)},
            {pers_nick,     proplists:get_value(reader_nick, Params)}
        ]
    )).

update_message(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:update(Con, Params)
    end).


is_message_owner(Uid, Oid)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:is_owner(Con, Uid, Oid)
    end).

mk_message_read(_con, undefined, _, _fields)->
    ok;

mk_message_read(_con, _, undefined, _fields)->
    ok;

mk_message_read(Con, all, Reader_id, _fields) ->
    empdb_dao_message:update(Con, [
        {filter, [
            {reader_id, Reader_id},
            {oktype_alias, {ne, ok}}
        ]},
        {values, [
            {oktype_alias, ok}
        ]}
    ]);

mk_message_read(Con, Id, Reader_id, Fields) ->
    case {Fields, lists:member(body, Fields)} of
        {[], _ } ->
            mk_message_read(Con, Id, Reader_id, [body]);
        {_, true} ->
            empdb_dao_message:update(Con, [
                {filter, [
                    {id,        Id},
                    {reader_id, Reader_id}
                ]},
                {values, [
                    {oktype_alias, ok}
                ]}
            ]);
        _ ->
            ok
    end.

get_message(Params)->
    empdb_dao:with_transaction(fun(Con)->
        mk_message_read(Con,
            proplists:get_value(id,         Params),
            proplists:get_value(reader_id,  Params),
            proplists:get_value(fields,     Params, [])
        ),
        empdb_dao_message:get(Con, [
            {order, {desc, created}},
            {isdeleted, false}
            |Params
        ])
    end).

get_message(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        mk_message_read(Con,
            proplists:get_value(id,         Params),
            proplists:get_value(reader_id,  Params),
            Fileds
        ),
        empdb_dao_message:get(Con,
            [   {order, {desc, created}},
                {isdeleted, false}
                |Params
            ],
            Fileds
        )
    end).

readall_message_for_me(Params)->
    Mparams =
        case proplists:get_value(pers_id, Params) of
            undefined ->
                Params;
            Reader_id ->
                [{reader_id, Reader_id}|Params]
        end,
    empdb_dao:with_transaction(fun(Con)->
        mk_message_read(Con,
            all,
            proplists:get_value(reader_id,  Mparams),
            []
        )
    end).

get_message_for_me(Params)->
    Mparams =
        case proplists:get_value(pers_id, Params) of
            undefined ->
                Params;
            Reader_id ->
                [{reader_id, Reader_id}|Params]
        end,
    empdb_dao:with_transaction(fun(Con)->
        mk_message_read(Con,
            proplists:get_value(id,         Mparams),
            proplists:get_value(reader_id,  Mparams),
            proplists:get_value(fields,     Mparams, [])
        ),
        empdb_dao_message:get(Con, [
            {order, {desc, created}},
            {isdfr,     false},
            {isdeleted, false}
            |Mparams
        ])
    end).

get_message_for_me(Params, Fields)->
    Mparams =
        case proplists:get_value(pers_id, Params) of
            undefined ->
                Params;
            Reader_id ->
                [{reader_id, Reader_id}|Params]
        end,
    empdb_dao:with_transaction(fun(Con)->
        mk_message_read(Con,
            proplists:get_value(id,         Mparams),
            proplists:get_value(reader_id,  Mparams),
            Fields
        ),
        empdb_dao_message:get(Con, [
            {order, {desc, created}},
            {isdfr,     false},
            {isdeleted, false}
            |Mparams
        ], Fields)
    end).

get_message_from_me(Params)->
    Mparams =
        case proplists:get_value(pers_id, Params) of
            undefined ->
                Params;
            Owner_id ->
                [{owner_id, Owner_id}|Params]
        end,
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:get(Con, [
            {order, {desc, created}},
            {isdfo,     false},
            {isdeleted, false}
            |Mparams
        ])
    end).

get_message_from_me(Params, Fields)->
    Mparams =
        case proplists:get_value(pers_id, Params) of
            undefined ->
                Params;
            Owner_id ->
                [{owner_id, Owner_id}|Params]
        end,
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:get(Con, [
            {order, {desc, created}},
            {isdfo,     false},
            {isdeleted, false}
            |Mparams
        ], Fields)
    end).

count_message(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:count(Con, [{isdeleted, false}|Filter])
    end).


count_message_types(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        {ok,[{[{count,Cm_for_me_ok}]}]}     =  count_message_for_me_(Con,   [
            {oktype_alias, ok}|Filter
        ]),
        {ok,[{[{count,Cm_from_me_ok}]}]}    =  count_message_from_me_(Con,  [
            {oktype_alias, ok}|Filter
        ]),
        {ok,[{[{count,Cm_for_me_new}]}]}    =  count_message_for_me_(Con,   [
            {oktype_alias, {neq, ok}}|Filter
        ]),
        {ok,[{[{count,Cm_from_me_new}]}]}   =  count_message_from_me_(Con,  [
            {oktype_alias, {neq, ok}}|Filter
        ]),
        {ok, [
            {[
                {for_me, {[
                    {ok, Cm_for_me_ok},
                    {new, Cm_for_me_new},
                    {all, Cm_for_me_ok + Cm_for_me_new}
                ]}}
            ]},
            {[
                {from_me,{[
                    {ok, Cm_from_me_ok},
                    {new, Cm_from_me_new},
                    {all, Cm_from_me_ok + Cm_from_me_new}
                ]}}
            ]}
        ]}
    end).

count_message_for_me(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        count_message_for_me_(Con, Filter)
    end).

count_message_for_me_(Con, Filter)->
    empdb_dao_message:count(Con,[
        {filter, [
            {isdfr,     false},
            {isdeleted, false}
            |case proplists:get_value(pers_id, Filter) of
                undefined ->
                    Filter;
                Reader_id ->
                    [{reader_id, Reader_id}|Filter]
            end
        ]}
    ]).


count_message_from_me(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        count_message_from_me_(Con, Filter)
    end).

count_message_from_me_(Con, Filter)->
    empdb_dao_message:count(Con,[
        {filter, [
            {isdfo,     false},
            {isdeleted, false}
            |case proplists:get_value(pers_id, Filter) of
                undefined ->
                    Filter;
                Owner_id ->
                    [{owner_id, Owner_id}|Filter]
            end
        ]}
    ]).

delete_message(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:update(Con, [
            {values, [{isdeleted, true}]},
            {filter, [{isdeleted, false}|Filter]}
        ])
    end).

delete_message_for_me(Filter)->
    io:format("~n <<<< Filter = ~p >>>> ~n", [Filter]),
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:update(Con, [
            {values, [{isdfr, true}]},
            {filter, [
                {isdfr,     false},
                {isdeleted, false}
                |case proplists:get_value(pers_id, Filter) of
                    undefined ->
                        Filter;
                    Reader_id ->
                        [{reader_id, Reader_id}|Filter]
                end
            ]},
            {fields,[id,doctype_id]}
        ])
    end).

delete_message_from_me(Filter)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_message:update(Con, [
            {values, [{isdfo, true}]},
            {filter, [
                {isdfo,     false},
                {isdeleted, false}
                |case proplists:get_value(pers_id, Filter) of
                    undefined ->
                        Filter;
                    Owner_id ->
                        [{owner_id, Owner_id}|Filter]
                end
            ]},
            {fields,[id,doctype_id]}
        ])
    end).

%%
%% Local Functions
%%

