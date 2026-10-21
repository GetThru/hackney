%%%-------------------------------------------------------------------
%%% @author benoitc
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Apr 2018 11:42
%%%-------------------------------------------------------------------
-module(hackney_ssl_tests).
-author("benoitc").

-include_lib("eunit/include/eunit.hrl").
-include("hackney_lib.hrl").


setup() -> ok.

teardown(_) -> ok.

empty_clen_test_() ->
  {
    "test SSL",
    {
      setup,
      fun start/0, fun stop/1,
      {
        foreach,
        fun setup/0, fun teardown/1,
        [
          fun wildcard_cert/1
        ]
      }
    }
  }.

start() ->
  error_logger:tty(false),
  {ok, _} = application:ensure_all_started(hackney),
  ok.

stop(_) ->
  application:stop(hackney),
  error_logger:tty(true),
  ok.

cacertfile_test_() ->
  {setup, fun write_cacertfile/0, fun delete_cacertfile/1,
   fun({File, [Cert | _]}) ->
       [?_assertEqual(certifi:cacerts(), hackney_ssl:cacerts()),
        ?_test(begin
                 application:set_env(hackney, cacertfile, File),
                 try
                   ?assertEqual([Cert], hackney_ssl:cacerts()),
                   Opts = hackney_ssl:check_hostname_opts("example.com"),
                   ?assertEqual([Cert], proplists:get_value(cacerts, Opts))
                 after
                   application:unset_env(hackney, cacertfile)
                 end
               end)]
   end}.

write_cacertfile() ->
  Certs = certifi:cacerts(),
  File = filename:join(os:getenv("TMPDIR", "/tmp"), "hackney_cacertfile_test.pem"),
  Pem = public_key:pem_encode([{'Certificate', hd(Certs), not_encrypted}]),
  ok = file:write_file(File, Pem),
  {File, Certs}.

delete_cacertfile({File, _}) ->
  file:delete(File).

wildcard_cert(_) ->
    URL = <<"https://friendpaste.com">>,
    Resp = case hackney:get(URL) of
             {ok, _, _, _} -> valid;
             _ -> error
           end,
    ?_assertEqual(Resp, valid).

