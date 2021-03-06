%%
%% @file    empweb_jsonapi_pers.erl
%%          "Контроллер" для функций работы с системными настройками,
%%          языками, и связанными с ними объектами.
%%

-module(empweb_jsonapi_communityhisttype).
-behavior(empweb_http_hap).

%% ===========================================================================
%% Заголовочные файлы
%% ===========================================================================

%%
%% Определения общие для всего приложения
%%
-include("empweb.hrl").

%%
%% Описание структур нормировки полей
%%
-include_lib("norm/include/norm.hrl").

%%
%% Описание записей событий и макросов
%%
-include_lib("evman/include/events.hrl").


%%
%% Трансформация для получения имени функции.
%%
-include_lib("evman/include/evman_transform.hrl").


%% ===========================================================================
%% Экспортируемые функции
%% ===========================================================================

-export([
    init/3,
    handle/2,
    terminate/2
]).

%% ===========================================================================
%% Внешние функции
%% ===========================================================================

map(<<"get_communityhisttype">>, Eh)->
    Eh#empweb_hap{
        handler         =   empweb_jsonapi_communityhisttype,
        action          =   'get'
    };

map(<<"get_all_communityhisttypes">>, Eh)->
    Eh#empweb_hap{
        handler         =   empweb_jsonapi_communityhisttype,
        action          =   'get'
    };

map(<<"create_communityhisttype">>, Eh)->
    Eh#empweb_hap{
        handler         =   empweb_jsonapi_communityhisttype,
        action          =   'create'
    };

map(<<"update_communityhisttype">>, Eh)->
    Eh#empweb_hap{
        handler         =   empweb_jsonapi_communityhisttype,
        action          =   'update'
    };

map(<<"delete_communityhisttype">>, Eh)->
    Eh#empweb_hap{
        handler         =   empweb_jsonapi_communityhisttype,
        action          =   'delete'
    };

map(Function, Eh)->
    Eh.


%%
%% @doc Инициализация запроса
%%
init(_, Req, #empweb_hap{
        action          =   Action,
        params          =   Params,
        is_auth         =   Is_auth,
        pers_id         =   Pid,
        pers_perm_names =   Pns
    } = Hap)->
    %%%
    %%% Это нужно, чтобы понять, какая функция дальше выполнится
    %%%
    ?evman_notice({hap, [
        {action,            Action},
        {params,            Params},
        {is_auth,           Is_auth},
        {pers_id,           Pid},
        {pers_perm_names,   Pns}
    ]}, <<" = Hap">>),

    {ok,
        Req,
        #empweb_hap{
            action          =   Action,
            params          =   Params,
            is_auth         =   Is_auth,
            pers_id         =   Pid,
            pers_perm_names =   Pns
        }
    }.

handle(_req, #empweb_hap{
        action='get', params=Params, pers_id=Pers_id
    } = Hap) ->
    ?evman_args([Hap], <<" = get communityhisttype">>),

    empweb_jsonapi:handle_params(
        %% проверка входных параметров и приведение к нужному типу
        norm:norm(Params, empweb_norm_opt:norm('get')),
        fun(Data)->
            ?evman_debug(Data, <<" = Data">>),
            {ok,
                empweb_jsonapi:resp(
                    empweb_biz_communityhisttype:get(Data#norm.return)
                ),
                Hap
            }
        end
    );

handle(_req, #empweb_hap{
        action=create, params=Params, pers_id=Pers_id
    } = Hap) ->
    ?evman_args([Hap], <<" = create communityhisttype">>),
    empweb_jsonapi:handle_params(
        %% проверка входных параметров и приведение к нужному типу
        norm:norm(Params,empweb_norm_opt:norm('create')),
        fun(Data)->
            ?evman_debug(Data, <<" = Data">>),

            io:format("Data#norm.return =  ~p~n", [Data#norm.return]),
            
            {ok,
                empweb_jsonapi:resp(
                    empweb_biz_communityhisttype:create(Data#norm.return)
                ),
                Hap
            }
        end
    );

handle(_req, #empweb_hap{
        action=update, params=Params, pers_id=Pers_id
    } = Hap) ->
    ?evman_args([Hap], <<" = update communityhisttype">>),

    empweb_jsonapi:handle_params(
        %% проверка входных параметров и приведение к нужному типу
        norm:norm(Params,empweb_norm_opt:norm('update')),
        fun(Data)->
            ?evman_debug(Data, <<" = Data">>),
            {ok,
                empweb_jsonapi:resp(
                    empweb_biz_communityhisttype:update(Data#norm.return)
                ),
                Hap
            }
        end
    );

handle(_req, #empweb_hap{
        action=delete, params=Params, pers_id=Pers_id
    } = Hap) ->
    ?evman_args([Hap], <<" = delete communityhisttype">>),

    empweb_jsonapi:handle_params(
        %% проверка входных параметров и приведение к нужному типу
        norm:norm(Params, empweb_norm_opt:norm('update')),
        fun(Data)->
            ?evman_debug(Data, <<" = Data">>),
            {ok,
                empweb_jsonapi:resp(
                    empweb_biz_communityhisttype:delete(Data#norm.return)
                ),
                Hap
            }
        end
    );
    
handle(_req, #empweb_hap{
        action=Action, params=Params, is_auth=Is_auth, pers_id=Pers_id
    } = Hap) ->
    ?evman_notice({hap, [
        {forbidden,     true},
        {action,        Action},
        {params,        Params},
        {pers_id,       Pers_id},
        {is_auth,       Is_auth}
    ]}, <<" = forbidden">>),
    {ok,empweb_jsonapi:forbidden(), Hap}.


terminate(_req, Hap)->
    ?evman_args([Hap], <<" = terminate">>),
    ok.
