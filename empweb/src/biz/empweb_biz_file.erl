%%
%%
-module(empweb_biz_file).

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
    empdb_biz_file:create(Params).

update(Params)->
    empdb_biz_file:update(Params).

delete(Params)->
    empdb_biz_file:delete(Params).

get(Params)->
    empdb_biz_file:get(Params).

get(Params, Fields)->
    empdb_biz_file:get(Params, Fields).
