% -----------------------------------------------------------------------------
%% common defines
% -----------------------------------------------------------------------------

-define( FMT(F,P), lists:flatten(io_lib:format(F,P)) ).
-define( APP, application:get_application()).
-define( CFG_PROCS, [{gen_server, m_pinger},
                     {gen_event, error_logger}]
       ).
