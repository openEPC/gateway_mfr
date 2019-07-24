-module(gateway_mfr_cli_ecc).

-behavior(clique_handler).

-export([register_cli/0]).

register_cli() ->
    register_all_usage(),
    register_all_cmds().


register_all_usage() ->
    lists:foreach(fun(Args) ->
                          apply(clique, register_usage, Args)
                  end,
                  [
                   ecc_usage(),
                   ecc_test_usage(),
                   ecc_provision_usage(),
                   ecc_onboarding_usage()
                  ]).

register_all_cmds() ->
    lists:foreach(fun(Cmds) ->
                          [apply(clique, register_command, Cmd) || Cmd <- Cmds]
                  end,
                  [
                   ecc_cmd(),
                   ecc_test_cmd(),
                   ecc_provision_cmd(),
                   ecc_onboarding_cmd()
                  ]).

%%
%% ecc
%%

ecc_usage() ->
    [["ecc"],
     ["ECC commands\n\n",
      "  test - Validates that the attached ECC is working and locked correctly.\n"
      "  provision - Validates that the attached ECC is working and locked correctly.\n"
     ]
    ].

ecc_cmd() ->
    [
     [["ecc"], [], [], fun(_, _, _) -> usage end]
    ].


%%
%% ecc test
%%

ecc_test_cmd() ->
    [
     [["ecc", "test"], [], [], fun ecc_test/3]
    ].

ecc_test_usage() ->
    [["ecc", "test"],
     ["ecc test \n\n",
      "  Tests the attached ECC for correct shipment configuration.\n"
     ]
    ].

ecc_test(["ecc", "test"], [], Flags) ->
    AllServices = gateway_config:wifi_services(),
    Services = case proplists:get_value(gatt, Flags, false) of
                   false ->
                       AllServices;
                   _ ->
                       {ok, S, _} = gateway_gatt_char_wifi_services:encode_services(AllServices),
                       S
               end,
    FormatService = fun({Name, Strength}) ->
                            [{name, Name}, {strength, Strength}]
                    end,
    [clique_status:table([FormatService(S) || S <- Services])];
ecc_test([_, _, _], [], []) ->
    usage.


%%
%% ecc provision
%%

ecc_provision_cmd() ->
    [
     [["ecc", "provision"], [],
      [],
      fun ecc_provision/3]
    ].

ecc_provision_usage() ->
    [["ecc", "provision"],
     ["ecc provision \n\n",
      "  Provision the ECC chip on the hotspot for production use.\n"
      "  This prints out the public onboarding key.\n\n"
      "  WARNING: This locks the ECC after provisioning! \n"
      "           This procedure is NOT reversible\n"
     ]
    ].

ecc_provision(["ecc", "provision"], [], []) ->
    case gateway_mfr_worker:ecc_provision() of
        {ok, B58Key} ->
            [clique_status:text(B58Key)];
        {error, Error} ->
            lager:error("Failed to provision ECC ~p", [Error])
    end;
ecc_provision([_, _], [], []) ->
    usage.



%%
%% ecc onboarding
%%


ecc_onboarding_cmd() ->
    [
     [["ecc", "onboarding"], [],
      [],
      fun ecc_onboarding/3]
    ].

ecc_onboarding_usage() ->
    [["ecc", "onboarding"],
     ["ecc onboarding \n\n",
      "  Retrieves the onboarding key of a _provisioned ECC.\n"
     ]
    ].

ecc_onboarding(["ecc", "onboarding"], [], []) ->
    case gateway_mfr_worker:ecc_onboarding() of
        {ok, B58Key} ->
            [clique_status:text(B58Key)];
        {error, Error} ->
            lager:error("Failed to onboarding ECC ~p", [Error])
    end;
ecc_onboarding([_, _], [], []) ->
    usage.