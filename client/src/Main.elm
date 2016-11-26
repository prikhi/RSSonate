port module Main exposing (..)

import Commands exposing (..)
import Html exposing (Html)
import Messages exposing (Msg(..))
import Model exposing (Model, feedDecoder, feedItemDecoder)
import RemoteStatus
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
      , maximizeItemView = False
      , isRefreshingFeed = False
      , refreshingFeedsStatus = RemoteStatus.initial
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
            , Cmd.batch [ triggerResize (), scrollContentToTop, focusContent ]
            )

        RefreshFeedsClicked ->
            ( { model
                | refreshingFeedsStatus =
                    RemoteStatus.enqueue (RemoteStatus.start model.refreshingFeedsStatus) <|
                        List.length model.feeds
              }
            , Cmd.batch <| List.map (\feed -> refreshFeed feed.id) model.feeds
            )

        RefreshFeedClicked id ->
            ( { model | isRefreshingFeed = True }, refreshFeed id )

        ToggleItemViewMaximized ->
            ( { model | maximizeItemView = not model.maximizeItemView }
            , triggerResize ()
            )

        ContentScrolledToTop _ ->
            ( model, Cmd.none )

        ContentFocused _ ->
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

        FeedRefreshed (Ok newItems) ->
            ( markFeedAsRefreshed { model | feedItems = newItems ++ model.feedItems }
            , Cmd.none
            )

        FeedRefreshed (Err _) ->
            ( markFeedAsRefreshed model, Cmd.none )

        FeedsFetched (Ok feeds) ->
            ( { model | feeds = feeds }, Cmd.none )

        FeedsFetched (Err _) ->
            ( model, Cmd.none )

        FeedItemsFetched (Ok items) ->
            ( { model | feedItems = items }, Cmd.none )

        FeedItemsFetched (Err _) ->
            ( model, Cmd.none )


markFeedAsRefreshed : Model -> Model
markFeedAsRefreshed model =
    let
        incrementedRefreshingStatus =
            RemoteStatus.finishOne model.refreshingFeedsStatus

        updatedRefreshingStatus =
            if RemoteStatus.isFinished incrementedRefreshingStatus then
                RemoteStatus.initial
            else
                incrementedRefreshingStatus
    in
        { model
            | isRefreshingFeed = False
            , refreshingFeedsStatus = updatedRefreshingStatus
        }