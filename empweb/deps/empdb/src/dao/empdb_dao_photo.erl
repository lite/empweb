%% Author: w-495
%% Created: 25.07.2012
%% Description: TODO: Add description to biz_user
-module(empdb_dao_photo).
-behaviour(empdb_dao).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([
    table/1,
    table/0,
    create/2,
    update/2,
    count_comments/2,
    get_adds/2,
    get/2,
    get/3
]).


%%
%% API Functions
%%



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
    table({fields, all}) -- [id];

%%
%% @doc Возвращает полный список полей таблицы
%%
table({fields, all})->
    [
        doc_id,
        %path,
        file_id,
        is_cover
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
    photo.

table()->
    table(name).

get(Con, What) ->
    %     <<  "   select  fileinfo.path,fileinfo.dir from doc "
    %         "   join photo on photo.doc_id = doc.id "
    %         "   join file on file.id = photo.file_id "
    %         "   join fileinfo on fileinfo.file_id = file.id "
    %         "   where (fileinfo.fileinfotype_alias "
    %         "       = $`fileinfo.fileinfotype_alias@filter`)"   >>

%     Fields =
%         proplists:get_value(
%             fields,
%             What,
%             empdb_dao_photo:table({fields, select}
%         ),
% 
%     case empdb_dao:get([
%         {empdb_dao_doc, id},
%         {empdb_dao_photo, {doc_id, file_id}},
%         {empdb_dao_file, id},
%         {empdb_dao_fileinfo, file_id}
%     ],Con,[
%         {fileinfotype_alias, download},
%         {fields, [
%             fileinfo.path,
%             fileinfo.dir
%             | Fields
%         ]}
%         |proplists:delete(fields, What)
%     ]) of
%         {ok,Phobjs} ->
%             {ok, 
%                 lists:map(fun({Phpl})->
%                     case lists:member(path, Fields) of
%                         true ->
%                             {[
%                                 {path,
%                                     <<  (proplists:get_value(dir, Phpl))/binary,
%                                         $/,
%                                         (proplists:get_value(path, Phpl))/binary
%                                     >>
%                                 }
%                                 | Phpl
%                             ]};
%                         _ ->
%                             {Phpl}
%                     end
%                 end, Phobjs)
%             };
%         Error ->
%             Error
%     end.
%
    empdb_dao_doc:get(?MODULE, Con, What).

get(Con, What, Fields)->
    empdb_dao_doc:get(?MODULE, Con, What, Fields).

create(Con, Proplist)->
    empdb_dao_doc:create(?MODULE, Con, Proplist).

update(Con, Proplist)->
    empdb_dao_doc:update(?MODULE, Con, Proplist).

is_owner(Con, Owner_id, Obj_id) ->
    empdb_dao_doc:is_owner(Con, Owner_id, Obj_id).

count_comments(Con, Params)->
    empdb_dao:eqret(Con,
        " select "
            " count(doc_comment.id) "
        " from "
            " doc as doc_comment "
        " where "
            "       doc_comment.doctype_alias  = 'comment' "
            " and   doc_comment.isdeleted      = false "
            " and   doc_comment.parent_id      = $id ",
        Params
    ).

get_adds(Con, Getresult) ->
    case Getresult of
        {ok, List} ->
            {ok, lists:map(fun({Itempl})->
                case proplists:get_value(id, Itempl) of
                    undefined ->
                        {Itempl};
                    Id ->
                        {ok, Comments}     = ?MODULE:count_comments(Con, [{id, Id}]),
                        Ncommentspl = lists:foldl(fun({Commentspl}, Acc)->
                            [{ncomments, proplists:get_value(count, Commentspl)}|Acc]
                        end, [], Comments),
                        {lists:append([Ncommentspl, Itempl])}
                end
            end, List)};
        {Eclass, Error} ->
            {Eclass, Error}
    end.
