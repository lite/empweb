%% Author: w-495
%% Created: 25.07.2012
%% Description: TODO: Add description to biz_user
-module(empdb_biz_roombet).

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
    update/1
]).

-define(EMPDB_BIZ_ROOMBET_EPSILON, 0.001).

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%                          ЗНАЧИМЫЕ ОБЪЕКТЫ
%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Блоги
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nowsec() ->
    {Mgs,Sec, _mis} = erlang:now(),
    Now = Mgs * 1000000 + Sec,
    Now.

create(Params)->
    empdb_dao:with_transaction(fun(Con)->
        Roomlot_id  = proplists:get_value(roomlot_id, Params),
        Owner_id    = proplists:get_value(owner_id, Params),
        Price       = proplists:get_value(price, Params, 0),
        Now         = nowsec(),
        case {
            %%
            %% Выясним информацию о покупателе и о лоте.
            %%
            empdb_dao_roomlot:get(Con, [
                {isdeleted, false},
                {id, Roomlot_id},
                {fields, [
                    room_id,
                    owner_id,
                    dtstart,
                    dtstop,
                    betmin,
                    betmax
                ]},
                {limit, 1}
            ]),
            empdb_dao_pers:get(Con, [
                {isdeleted, false},
                {'or', [
                    {id,    proplists:get_value(owner_id,   Params)},
                    {nick,  proplists:get_value(owner_nick, Params)}
                ]},
                {fields, [
                    id,
                    money
                ]},
                {limit, 1}
            ])
        } of
            {   {ok, [{Roomlotpl}]},
                {ok, [{Userpl}]}
            } ->
                Roomlot_owner_id    = proplists:get_value(owner_id, Roomlotpl),
                Room_id             = proplists:get_value(room_id,  Roomlotpl),
                Betmin              = proplists:get_value(betmin,   Roomlotpl),
                Betmax              = proplists:get_value(betmax,   Roomlotpl),
                Dtstart             = proplists:get_value(dtstart,  Roomlotpl),
                Dtstop              = proplists:get_value(dtstop,   Roomlotpl),
                Money               = proplists:get_value(money,    Userpl),
                Newmoney            = Money - Price,
                %%
                %% Вычисляем, кто до этого, сделал ставку.
                %%
                Mbmaxprev = empdb_dao_roombet:get(Con, [
                    {isdeleted, false},
                    {price, {lte, Price}},
                    {roomlot_id, Roomlot_id},
                    {limit, 1},
                    {order, [
                        {desc, price},
                        {asc, created}
                    ]}
                ]),
                %%
                %% Вычисляем минимально возможную цену ставки.
                %% Она должна быть больше и равна минимальной ставки за лот,
                %% и больше предцыдущей ставки
                %%
                Betminc =
                    case Mbmaxprev of
                        {ok, [{Maxprev1}]} ->
                            proplists:get_value(price, Maxprev1)
                            + ?EMPDB_BIZ_ROOMBET_EPSILON;
                        _ ->
                            Betmin
                    end,
                case (
                    (
                        Price =< Money
                    ) and (
                        (Betminc    =< Price) and (Price    =<  Betmax)
                    ) and (
                        (Dtstart    =< Now  ) and (Now      =<  Dtstop)
                    )
                ) of
                    true ->
                        case Mbmaxprev of
                            {ok, [{Maxprev}]} ->
                                Maxprev_owner_id    =
                                    proplists:get_value(owner_id, Maxprev),
                                Maxprev_price       =
                                    proplists:get_value(price, Maxprev),
                                %%
                                %% Возвращаем деньги пользователю.
                                %%
                                {ok, _} = empdb_dao_pers:update(Con,[
                                    {id,    Maxprev_owner_id},
                                    {money, {incr, Maxprev_price}}
                                ]),
                                ok;
                            Some ->
                                ok
                        end,
                        %%
                        %% Списываем деньги у участника аукциона.
                        %% Если он станет победителем, 
                        %% то это будет плата за товар.
                        %% Если кто-то сделает большую ставку,
                        %% то эти деньги вернем на следующей итерации.
                        %%
                        {ok, _} = empdb_dao_pers:update(Con,[
                            {id,    proplists:get_value(id,   Userpl)},
                            {money, {decr, Price}}
                        ]),
                        Roombet = empdb_dao_roombet:create(Con, Params),
                        case Price =:= Betmax of
                            true ->
                                %% 
                                %% Назначена цена выкупа. 
                                %% Человек автоматически становится победителем.
                                %% 
                                %% 1) Старому владельцу зачисляются деньги.
                                %% 2) Меняется владельца страны.
                                %% 
                                {ok, _} = empdb_dao_pers:update(Con, [
                                    {id,        Roomlot_owner_id},
                                    {money,     {incr, Price}}
                                ]),
                                {ok, _} = empdb_dao_room:update(Con, [
                                    {id,        Room_id},
                                    {owner_id,  Owner_id}
                                ]),
                                Roombet;
                            false -> 
                                %%
                                %% Штатная ситуация. 
                                %% Человек (пока) не победил.
                                %%
                                Roombet
                        end;
                    _ ->
                        {error, {something_wrong, {[
                            {'now',     Now},
                            {money,     Money},
                            {price,     Price},
                            {betmin,    Betmin},
                            {betmax,    Betmax},
                            {dtstart,   Dtstart},
                            {dtstop,    Dtstop}
                        ]}}}
                end;
            {_, _} ->
                {ok, []}
        end
    end).


update(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_roombet:update(Con, Params)
    end).

get(Params)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_roombet:get(Con, [{isdeleted, false}|Params])
    end).

get(Params, Fileds)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_roombet:get(Con, [{isdeleted, false}|Params], Fileds)
    end).

is_blog_owner(Uid, Oid)->
    empdb_dao:with_transaction(fun(Con)->
        empdb_dao_roombet:is_owner(Con, Uid, Oid)
    end).
