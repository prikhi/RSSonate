port module Main exposing (..)

import Auth
import Commands exposing (fetchFeeds, triggerResize)
import Html exposing (Html)
import Messages exposing (Msg)
import Model exposing (Model, initialModel)
import Update exposing (update)
import View exposing (view)


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


type alias Flags =
    { authToken : Maybe Auth.Token }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( initialModel flags.authToken
    , Cmd.batch
        [ triggerResize ()
        , flags.authToken |> Maybe.map fetchFeeds |> Maybe.withDefault Cmd.none
        ]
    )
