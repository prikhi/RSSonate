port module Main exposing (..)

import Auth
import Commands exposing (..)
import Html exposing (Html)
import Messages exposing (Msg(..))
import Model exposing (Model, feedDecoder, feedItemDecoder)
import RemoteStatus
import Set
import View exposing (view)


type alias Flags =
    { authToken : Maybe Auth.Token }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { feeds = []
      , feedItems = []
      , authStatus = Auth.fromToken flags.authToken
      , authForm = Auth.initalForm
      , addFeedInput = ""
      , currentFeed = Nothing
      , currentFeedItem = Nothing
      , maximizeItemView = False
      , isRefreshingFeed = False
      , refreshingFeedsStatus = RemoteStatus.initial
      , fetchedFeeds = Set.empty
      }
    , Cmd.batch [ fetchFeeds, triggerResize () ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthFormMsg subMsg ->
            let
                ( newStatus, newForm ) =
                    Auth.update subMsg model.authStatus model.authForm
            in
                ( { model | authForm = newForm, authStatus = newStatus }
                , Cmd.none
                )

        AuthFormSubmitted ->
            case model.authStatus of
                Auth.LoggingIn ->
                    ( model, login model.authForm )

                Auth.Registering ->
                    ( model, register model.authForm )

                _ ->
                    ( model, Cmd.none )

        AddFeedInputChanged newUrl ->
            ( { model | addFeedInput = newUrl }, Cmd.none )

        AddFeedFormSubmitted ->
            ( model, addFeed model.addFeedInput )

        LogoutButtonClicked ->
            ( { model | authStatus = Auth.LoggingIn }, removeAuthToken () )

        SetCurrentFeed id ->
            let
                cmd =
                    if Set.member id model.fetchedFeeds then
                        Cmd.none
                    else
                        fetchItemsForFeed id
            in
                ( { model | currentFeed = Just id, currentFeedItem = Nothing }
                , cmd
                )

        SetCurrentFeedItem id ->
            ( { model | currentFeedItem = Just id }
            , Cmd.batch [ triggerResize (), newContentCommands ]
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

        DomTaskCompleted _ ->
            ( model, Cmd.none )

        AuthCompleted (Ok token) ->
            let
                cmd =
                    if model.authForm.remember then
                        storeAuthToken token
                    else
                        Cmd.none
            in
                ( { model
                    | authStatus = Auth.Authorized token
                    , authForm = Auth.initalForm
                  }
                , Cmd.batch [ cmd, triggerResize () ]
                )

        AuthCompleted (Err _) ->
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

        FeedItemsFetched id (Ok items) ->
            ( { model
                | feedItems = items ++ model.feedItems
                , fetchedFeeds = Set.insert id model.fetchedFeeds
              }
            , Cmd.none
            )

        FeedItemsFetched _ (Err _) ->
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
