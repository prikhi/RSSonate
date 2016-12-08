module Update exposing (update)

import Auth exposing (mapToken)
import Commands exposing (..)
import Messages exposing (Msg(..))
import Model exposing (Model, Feed, FeedId, FeedItemId, initialModel)
import RemoteStatus
import Set
import Utils


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
            ( initialModel Nothing, removeAuthToken () )

        SetCurrentFeed id ->
            ( { model | itemsShown = Model.FromFeed id, currentFeedItem = Nothing }
            , Cmd.batch [ fetchItemsForFeedOnce model id, focusItemsPanel ]
            )

        SetCurrentFeedItem id ->
            let
                ( updatedModel, cmd ) =
                    setItemRead id { model | currentFeedItem = Just id }
            in
                ( updatedModel
                , Cmd.batch
                    [ triggerResize ()
                    , newContentCommands
                    , cmd
                    ]
                )

        ToggleEditingFeedsClicked ->
            ( { model | editingFeeds = not model.editingFeeds }, Cmd.none )

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

        MarkFeedReadClicked id ->
            let
                setZeroUnreadCount =
                    Utils.updateOneWhere (\x -> x.id == id)
                        (\x -> { x | unreadCount = 0 })

                setItemsAsRead =
                    Utils.updateAllWhere (\x -> x.feed == id && x.isUnread)
                        (\x -> { x | isUnread = False })
            in
                ( { model
                    | feeds = setZeroUnreadCount model.feeds
                    , feedItems = setItemsAsRead model.feedItems
                  }
                , mapToken model markFeedAsRead <| id
                )

        ToggleItemViewMaximized ->
            ( { model | maximizeItemView = not model.maximizeItemView }
            , triggerResize ()
            )

        ToggleItemIsFavorite id ->
            let
                updateItem =
                    Utils.updateOneWhere (\x -> x.id == id)
                        (\x -> { x | isFavorite = not x.isFavorite })
            in
                ( { model | feedItems = updateItem model.feedItems }
                , mapToken model toggleItemFavorite <| id
                )

        MarkUnreadButtonClicked id ->
            ( setItemUnread id
                { model | currentFeedItem = Nothing, maximizeItemView = False }
            , mapToken model markItemAsUnread <| id
            )

        DeleteFeedClicked id ->
            ( { model
                | feeds = List.filter (\f -> f.id /= id) model.feeds
                , feedItems = List.filter (\i -> i.feed /= id) model.feedItems
              }
            , mapToken model deleteFeed <| id
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
            let
                addFeedToModel currentModel =
                    if List.any (\x -> x.id == newFeed.id) currentModel.feeds then
                        currentModel
                    else
                        { currentModel | feeds = newFeed :: currentModel.feeds }
            in
                ( addFeedToModel { model | addFeedInput = "" }, Cmd.none )

        FeedAdded (Err _) ->
            ( model, Cmd.none )

        FeedRefreshed id (Ok newItems) ->
            ( markFeedAsRefreshed
                { model
                    | feedItems = newItems ++ model.feedItems
                    , feeds = updateUnreadCount model.feeds (List.length newItems) id
                }
            , Cmd.none
            )

        FeedRefreshed _ (Err _) ->
            ( markFeedAsRefreshed model, Cmd.none )

        FeedsFetched (Ok feeds) ->
            ( { model | feeds = feeds }, Cmd.none )

        FeedsFetched (Err _) ->
            ( model, Cmd.none )

        FeedDeleted _ ->
            ( model, Cmd.none )

        FeedMarkedRead _ ->
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


setItemRead : FeedItemId -> Model -> ( Model, Cmd Msg )
setItemRead id model =
    let
        ( isUpdated, updatedModel ) =
            updateItemIsUnread False id model

        cmd =
            if isUpdated then
                mapToken model markItemAsRead <| id
            else
                Cmd.none
    in
        ( updatedModel, cmd )


setItemUnread : FeedItemId -> Model -> Model
setItemUnread id model =
    updateItemIsUnread True id model |> Tuple.second


updateItemIsUnread : Bool -> FeedItemId -> Model -> ( Bool, Model )
updateItemIsUnread newUnreadStatus id model =
    let
        ( maybeItem, updatedItems ) =
            Utils.getAndUpdateById (\x -> { x | isUnread = newUnreadStatus })
                id
                model.feedItems

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
        ( maybeItem /= Nothing
        , { model | feedItems = updatedItems, feeds = updatedFeeds }
        )


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
