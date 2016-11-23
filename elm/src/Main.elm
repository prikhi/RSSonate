port module Main exposing (..)

import Commands exposing (..)
import Html exposing (Html)
import Messages exposing (Msg(..))
import Model exposing (Model, feedDecoder, feedItemDecoder)
import View exposing (view)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( { feeds = []
      , feedItems = []
      , addFeedInput = ""
      , currentFeed = Nothing
      , currentFeedItem = Nothing
      }
    , Cmd.batch [ fetchFeeds, fetchFeedItems ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddFeedInputChanged newUrl ->
            ( { model | addFeedInput = newUrl }, Cmd.none )

        AddFeedFormSubmitted ->
            ( model, addFeed model.addFeedInput )

        SetCurrentFeed id ->
            ( { model
                | currentFeed = Just id
                , currentFeedItem = Nothing
              }
            , fetchFeedItems
            )

        SetCurrentFeedItem id ->
            ( { model | currentFeedItem = Just id }
            , Cmd.batch [ triggerResize (), scrollContentToTop ]
            )

        ContentScrolledToTop _ ->
            ( model, Cmd.none )

        FeedAdded (Ok newFeed) ->
            ( { model
                | feeds = newFeed :: model.feeds
                , addFeedInput = ""
              }
            , Cmd.none
            )

        FeedAdded (Err _) ->
            ( model, Cmd.none )

        FeedsFetched (Ok feeds) ->
            ( { model | feeds = feeds }, Cmd.none )

        FeedsFetched (Err _) ->
            ( model, Cmd.none )

        FeedItemsFetched (Ok items) ->
            ( { model | feedItems = items }, Cmd.none )

        FeedItemsFetched (Err _) ->
            ( model, Cmd.none )
