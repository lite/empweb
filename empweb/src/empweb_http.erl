-module(empweb_http).
-include("empweb.hrl").
-include_lib("cowboy/include/http.hrl").


-export([
    auth/1,
    make_auth/1,
    auth_cookie/1,
    make_auth_cookie/1,
    call/2,
    resp/1
]).

-export([
    reply/2,
    method/1,
    body_qs/1,
    multipart_data/1
]).

-define(AUTH_COOKIE_NAME, <<"empire_100829481802076318">>).


multipart_data(Req) ->
    cowboy_http_req:multipart_data(Req).


multipart_data_c(Req) ->
    case cowboy_http_req:parse_header('Transfer-Encoding', Req) of
        {[<<"chunked">>], Req2} ->
            io:format("~n~n~n chunked ~n~n~n"),
            io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
            multipart_data_chunked(Req2);
        {[<<"identity">>], Req2} ->
            io:format("~n~n~n chunked ~n~n~n"),
            io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
            cowboy_http_req:multipart_data(Req)
    end.

multipart_data_chunked(Req) ->
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    multipart_data(Req#http_req{body_state=waiting}, []).

multipart_data_chunked_({ok, Bodydata, Req}) ->
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    multipart_data(Req#http_req{body_state=waiting}, []);

multipart_data_chunked_({error, Error}) ->
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {error, Error}.

multipart_data(Req=#http_req{body_state=waiting}, Bodydata) ->
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {{<<"multipart">>, _SubType, Params}, Req2} =
        cowboy_http_req:parse_header('Content-Type', Req),
    {_, Boundary} = lists:keyfind(<<"boundary">>, 1, Params),
    {Length, Req3} =
        case cowboy_http_req:parse_header('Content-Length',Req2) of
            {undefined, Req2_} ->
                {undefined, L, Req2__} = cowboy_http_req:parse_header(<<"X-Content-Length">>,Req2_),
                {erlang:list_to_integer(erlang:binary_to_list(L)), Req2__};
            {Length_, Req2_}->
                {Length_, Req2_}
        end,
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    multipart_data(Req3, Length, {more, cowboy_multipart:parser(Boundary)}, Bodydata);

multipart_data(Req=#http_req{body_state={multipart, Length, Cont}}, Bodydata) ->
    io:format("~n~n 2 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    multipart_data(Req, Length, Cont(), Bodydata);

multipart_data(Req=#http_req{body_state=done}, Bodydata) ->
    io:format("~n~n 3 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {eof, Req}.

multipart_data(Req, Length, {headers, Headers, Cont}, Bodydata) ->
    io:format("~n~n 4 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {{headers, Headers}, Req#http_req{body_state={multipart, Length, Cont}}};

multipart_data(Req, Length, {body, Data, Cont}, Bodydata) ->
    io:format("~n~n 5 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {{body, Data}, Req#http_req{body_state={multipart, Length, Cont}}};

multipart_data(Req, Length, {end_of_part, Cont}, Bodydata) ->
    io:format("~n~n 6 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {end_of_part, Req#http_req{body_state={multipart, Length, Cont}}};

multipart_data(Req, 0, eof, Bodydata) ->
    io:format("~n~n 7 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {eof, Req#http_req{body_state=done}};

multipart_data(Req=#http_req{socket=Socket, transport=Transport}, _Length, eof, Bodydata) ->
    io:format("~n~n 8 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {eof, Req#http_req{body_state=done}};

multipart_data(Req=#http_req{socket=Socket, transport=Transport}, 0, _, Bodydata) ->
    io:format("~n~n 8 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    {eof, Req#http_req{body_state=done}};


multipart_data(Req, Length, {more, Parser}, Bodydata) when Length > 0 ->
    io:format("~n~n 9 ~n~n"),
    io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
    case cowboy_http_req:stream_body(Req) of
        {ok, << Data:Length/binary, Buffer/binary >>, Req2} ->
            io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
            multipart_data(Req2#http_req{buffer=Buffer}, 0, Parser(Data), Bodydata);
        {ok, Data, Req2} ->
            io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
            io:format("~n~n 9.1 ~n~n"),
            io:format("~n~n 9.1  Length = ~p ~n~n", [Length]),
            io:format("~n~n 9.1  byte_size(Data) = ~p ~n~n", [byte_size(Data)]),
            io:format("~n~n~n ~p in ~p ~n~n~n", [?MODULE, ?LINE]),
            multipart_data(Req2, Length - byte_size(Data), Parser(Data), Bodydata);
        %{error, timeout} ->
            %{eof, Req#http_req{body_state=done}};
        {done, Req2} ->
            {eof, Req2#http_req{body_state=done}}
    end.



body_qs(Req) ->
    cowboy_http_req:body_qs(Req).

method(Req) ->
    cowboy_http_req:method(Req).


auth(Req)->
    {Res, Req1} = auth_cookie(Req),
    {{session_id, Res}, Req1}.

auth_cookie(Req)->
    {Res, Req1} = cowboy_http_req:cookie(?AUTH_COOKIE_NAME, Req),
    {Res, Req1}.

make_auth(Body)->
    make_auth_cookie(Body).

make_auth_cookie([{Body}])->
    make_auth_cookie(Body);

make_auth_cookie(Body) ->
    {
        ?AUTH_COOKIE_NAME,
        proplists:get_value(session_id, Body),
        [
            {max_age, 1800000},

            %%
            %% see also empweb_biz_session
            %%
            {local_time, calendar:local_time()},
            {path, <<"/">>}
        ]
    }.


%%
%% В старом стиле для классических контроллеров
%%
call(Req, {Ctl,Act,Opt}) ->
    call(Req, #empweb_ctl{ctl=Ctl,act=Act,opt=Opt});

%%
%% В новом стиле для хендлеров
%%
call(Req, {Handler,{Action,Params}} = Hao) ->
    call(
        Req,
        #empweb_hap{
            handler=Handler,
            action=Action,
            params=Params
        }
    );

call(Req, {Handler,{Action,Params,Is_auth}}=Hao) ->
    call(
        Req,
        #empweb_hap{
            handler=Handler,
            action=Action,
            params=Params,
            is_auth=Is_auth
        }
    );

%%
%% В старом стиле для классических контроллеров
%%
call(Req, #empweb_ctl{ctl=Ctl,act=Act,opt=Opt} = Action) ->
    case call_init(Req, Action) of
        {ok, Nreq, State} ->
            call_handle(Nreq, Action, State);
        {error, Error} ->
            {error, Error}
    end;

%%
%% В новом стиле для хендлеров
%%
call(Req, #empweb_hap{handler=Handler,action=Action,params=Params} = Hao) ->
    case call_init(Req, Hao) of
        {ok, Nreq, State} ->
            call_handle(Nreq, Hao, State);
        {error, Error} ->
            {error, Error}
    end;


call(Req, #empweb_hap{handler=undefined} = Hao) ->
    {error, unknown_function};

call(Req, #empweb_hap{action=undefined} = Hao) ->
    {error, unknown_function};


call(Req, Some) ->
    {error, unknown_function}.


%%
%% В старом стиле для классических контроллеров
%%
call_init(Req, #empweb_ctl{ctl=Ctl,opt=Opt} = Action) ->
    %% Третий аргумент оставлен для совместимости с cowboy
    Ctl:init([], Req, Opt);

%%
%% В новом стиле для хендлеров
%%
call_init(Req, #empweb_hap{handler=Handler}=Hao) ->
    %% Третий аргумент оставлен для совместимости с cowboy
    Handler:init([], Req, Hao).

%%
%% В старом стиле для классических контроллеров
%%
call_handle(Req, #empweb_ctl{ctl=Ctl,act=Act}=Action, State) ->
    case Ctl:Act(Req, State) of
        {ok, Reply, Nstate} ->
            ok = Ctl:terminate(Req, Nstate),
            {ok, Reply};
        Error ->
            Ctl:ternimate(Req, State),
            {error, Error}
    end;

%%
%% В новом стиле для хендлеров
%%
call_handle(Req, #empweb_hap{handler=Handler,action=Action}=Hap, State) ->
    case Handler:handle(Req, State) of
        {ok, Reply, Nstate} ->
            ok = Handler:terminate(Req, Nstate),
            {ok, Reply};
        Error ->
            Handler:ternimate(Req, State),
            {error, Error}
    end.


reply(#http_resp{} = Http_resp, Req) ->
    {ok, Reply} =
        cowboy_http_req:reply(
            Http_resp#http_resp.status,
            Http_resp#http_resp.headers,
            Http_resp#http_resp.body,
            Req
        ),
    Reply.

resp(#empweb_resp{cookies=Cookies} = Empweb_resp)
    when erlang:is_tuple(Cookies) ->
    resp(Empweb_resp#empweb_resp{cookies=[Cookies]});

resp(#empweb_resp{status={redirect, Location},cookies=Icookies,format=Format,body=Body,headers=Headers})
    when erlang:is_list(Icookies) ->


    Cookies = lists:map(fun
            ({Name, Value})->
                cowboy_cookies:cookie(Name, Value, []);
            ({Name, Value, Params})->
                cowboy_cookies:cookie(Name, Value, Params)
        end, Icookies),


    #http_resp{
        status=status(redirect),
        headers=[
            resp_format(Format),
            {<<"Location">>, Location}
            |lists:append(Cookies, Headers)
        ],
        body=Body
    };

resp(#empweb_resp{status=Status,cookies=Icookies,format=Format,body=Body,headers=Headers})
    when erlang:is_atom(Status) and erlang:is_list(Icookies) ->

    Cookies = lists:map(fun
            ({Name, Value})->
                cowboy_cookies:cookie(Name, Value, []);
            ({Name, Value, Params})->
                cowboy_cookies:cookie(Name, Value, Params)
        end, Icookies),

    #http_resp{
        status=status(Status),
        headers=[resp_format(Format)|lists:append(Cookies, Headers)],
        body=Body
    };

resp(#empweb_resp{status=Status,cookies=Icookies,format=Format,body=Body,headers=Headers})
    when erlang:is_integer(Status) and erlang:is_list(Icookies) ->

    io:format(" ~n~n~n Some = ~p ~n~n~n", [Status]),

    Cookies = lists:map(fun
            ({Name, Value})->
                cowboy_cookies:cookie(Name, Value, []);
            ({Name, Value, Params})->
                cowboy_cookies:cookie(Name, Value, Params)
        end, Icookies),


    #http_resp{
        status=Status,
        headers=[resp_format(Format)|lists:append(Cookies, Headers)],
        body=Body
    };

resp(Empwebresplist) when erlang:is_list(Empwebresplist) ->

    Resresp_ =
        lists:foldl(
            fun
                (Empwebresp, #http_resp{body=Bodies})->
                    Httpresp = #http_resp{body = Body} = resp(Empwebresp),
                    Httpresp#http_resp{
                        body    = [Body|Bodies]
                    }
            end,
            #http_resp{},
            Empwebresplist
        ),

    Resresp_#http_resp{
        body    = lists:reverse(Resresp_#http_resp.body)
    }.


resp_format(json) ->    ?OUTPUT_JSON_HEADER_CTYPE;

resp_format(html) ->    ?OUTPUT_HTML_HEADER_CTYPE;

resp_format(X) -> X.


status(continue) ->                             100;
status(switching_protocols) ->                  101;
status(processing) ->                           102;
status(ok) ->                                   200;
status(created) ->                              201;
status(accepted) ->                             202;
status(non_authoritative_information) ->        203;
status(no_content) ->                           204;
status(reset_content) ->                        205;
status(partial_content) ->                      206;
status(multi_status) ->                         207;
status(im_used) ->                              226;

status(multiple_choices) ->     300;
status(moved_permanently) ->    301;
status(found) ->                302;
status(see_other) ->            303;
status(not_modified) ->         304;
status(use_proxy) ->            305;
status(switch_proxy) ->         306;
status(temporary_redirect) ->   306;

status(bad_request) ->                      400;
status(unauthorized) ->                     401;
status(payment_required) ->                 402;
status(forbidden) ->                        403;
status(not_found) ->                        404;
status(method_not_allowed) ->               405;
status(not_acceptable) ->                   406;
status(proxy_authentication_required) ->    407;
status(request_timeout) ->                  408;
status(conflict) ->                         409;
status(gone) ->                             410;
status(length_required) ->                  411;
status(precondition_failed) ->              412;
status(request_entity_too_large) ->         413;
status(request_uri_too_long) ->             414;
status(unsupported_media_type) ->           415;
status(requested_range_not_satisfiable) ->  416;
status(expectation_failed) ->               417;
status(im_a_teapot) ->                      418;
status(unprocessable_entity) ->             420;
status(locked) ->                           423;
status(failed_dependency) ->                424;
status(unordered_collection) ->             425;
status(upgrade_required) ->                 426;
status(precondition_required) ->            428;
status(too_many_requests) ->                429;
status(request_header_fields_too_large) ->  431;

status(error) ->            500;

status(internal_server_error) ->            500;
status(not_implemented) ->                  501;
status(bad_gateway) ->                      502;
status(service_unavailable) ->              503;
status(gateway_timeout) ->                  504;
status(http_version_not_supported) ->       505;
status(variant_also_negotiates) ->          506;
status(insufficient_storage) ->             507;
status(not_extended) ->                     510;
status(network_authentication_required) ->  511;


status(Status) when erlang:is_integer(Status) ->
    Status;

status(X) ->                                   0.
