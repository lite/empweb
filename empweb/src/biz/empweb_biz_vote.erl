%%
%%
-module(empweb_biz_vote).

%% ==========================================================================
%% Экспортируемые функции
%% ==========================================================================
%%
%% Списки языков
%%
-export([
    update/1,
    create/1,
    get/1,
    get/2
]).


%% ==========================================================================
%% Внешние функции
%% ==========================================================================

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Списки языков
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create(Params)->
    empdb_biz_vote:create(Params).

update(Params)->
    empdb_biz_vote:update(Params).

delete(Params)->
    empdb_biz_vote:delete(Params).

get(Params)->
    empdb_biz_vote:get(Params).

get(Params, Fields)->
    empdb_biz_vote:get(Params, Fields).
