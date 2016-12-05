port module Main exposing (..)

import Auth exposing (mapToken)
import Commands exposing (..)
import Html exposing (Html)
import Messages exposing (Msg(..))
import Model exposing (Model, Feed, FeedId, FeedItemId)
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
      , itemsShown = Model.None
      , currentFeedItem = Nothing
      , maximizeItemView = False
      , isRefreshingFeed = False
      , refreshingFeedsStatus = RemoteStatus.initial
      , fetchedFeeds = Set.empty
      }
    , Cmd.batch
        [ triggerResize ()
        , flags.authToken |> Maybe.map fetchFeeds |> Maybe.withDefault Cmd.none
        ]
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
            ( model, mapToken model addFeed <| model.addFeedInput )

        LogoutButtonClicked ->
            let
                ( initialModel, initialCmd ) =
                    init { authToken = Nothing }
            in
                ( initialModel, Cmd.batch [ removeAuthToken (), initialCmd ] )

        SetCurrentFeed id ->
            ( { model | itemsShown = Model.FromFeed id, currentFeedItem = Nothing }
            , Cmd.batch [ fetchItemsForFeedOnce model id, focusItemsPanel ]
            )

        SetCurrentFeedItem id ->
            ( setItemRead id { model | currentFeedItem = Just id }
            , Cmd.batch
                [ triggerResize ()
                , newContentCommands
                , mapToken model markItemAsRead <| id
                ]
            )

        FavoritesButtonClicked ->
            ( { model | itemsShown = Model.Favorites, currentFeedItem = Nothing }
            , Cmd.batch <|
                List.map (.id >> fetchItemsForFeedOnce model) model.feeds
            )

        RefreshFeedsClicked ->
            ( { model
                | refreshingFeedsStatus =
                    RemoteStatus.enqueue (RemoteStatus.start model.refreshingFeedsStatus) <|
                        List.length model.feeds
              }
            , Cmd.batch <| List.map (\feed -> mapToken model refreshFeed <| feed.id) model.feeds
            )

        RefreshFeedClicked id ->
            ( { model | isRefreshingFeed = True }, mapToken model refreshFeed <| id )

        ToggleItemViewMaximized ->
            ( { model | maximizeItemView = not model.maximizeItemView }
            , triggerResize ()
            )

        ToggleItemIsFavorite id ->
            let
                updateItem items =
                    case items of
                        [] ->
                            []

                        x :: xs ->
                            if x.id == id then
                                { x | isFavorite = not x.isFavorite } :: xs
                            else
                                x :: updateItem xs
            in
                ( { model | feedItems = updateItem model.feedItems }
                , mapToken model toggleItemFavorite <| id
                )

        MarkUnreadButtonClicked id ->
            ( setItemUnread id { model | currentFeedItem = Nothing }
            , mapToken model markItemAsUnread <| id
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
                , Cmd.batch [ cmd, fetchFeeds token, triggerResize () ]
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

        FeedItemMarkedUnread _ ->
            ( model, Cmd.none )

        FeedItemMarkedRead _ ->
            ( model, Cmd.none )

        FeedItemFavoriteToggled _ ->
            ( model, Cmd.none )


setItemRead : FeedItemId -> Model -> Model
setItemRead =
    updateItemIsUnread False


setItemUnread : FeedItemId -> Model -> Model
setItemUnread =
    updateItemIsUnread True


updateItemIsUnread : Bool -> FeedItemId -> Model -> Model
updateItemIsUnread newUnreadStatus id model =
    let
        ( maybeItem, updatedItems ) =
            getAndUpdate (\x -> { x | isUnread = newUnreadStatus }) id model.feedItems

        unreadChange =
            if newUnreadStatus then
                1
            else
                -1

        updatedFeeds =
            maybeItem
                |> Maybe.map (.feed >> updateUnreadCount model.feeds unreadChange)
                |> Maybe.withDefault model.feeds
    in
        { model | feedItems = updatedItems, feeds = updatedFeeds }


updateUnreadCount : List Feed -> Int -> FeedId -> List Feed
updateUnreadCount feeds amount id =
    case feeds of
        [] ->
            []

        x :: xs ->
            if x.id == id then
                { x | unreadCount = x.unreadCount + amount } :: xs
            else
                x :: updateUnreadCount xs amount id


getAndUpdate :
    ({ a | id : b } -> { a | id : b })
    -> b
    -> List { a | id : b }
    -> ( Maybe { a | id : b }, List { a | id : b } )
getAndUpdate f id items =
    case items of
        [] ->
            ( Nothing, [] )

        x :: xs ->
            if x.id == id && f x /= x then
                ( Just <| f x, f x :: xs )
            else
                getAndUpdate f id xs
                    |> \( updated, updatedItems ) -> ( updated, x :: updatedItems )


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
