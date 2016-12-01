module View exposing (view)

import Auth
import Date.Format
import Html exposing (..)
import Html.Attributes exposing (type_, value, placeholder, class, href, id, target, disabled, attribute, checked)
import Html.Events exposing (onSubmit, onInput, onClick)
import Markdown
import Messages exposing (Msg(..))
import Model exposing (Model, FeedId, Feed, FeedItemId, FeedItem)
import RemoteStatus


view : Model -> Html Msg
view model =
    case model.authStatus of
        Auth.Authorized token ->
            div []
                [ navbar model
                , div [ class "container-fluid" ]
                    [ div [ class "row" ] <| page model
                    ]
                ]

        _ ->
            div []
                [ Auth.view AuthFormMsg
                    AuthFormSubmitted
                    model.authStatus
                    model.authForm
                ]


navbar : Model -> Html Msg
navbar model =
    nav [ class "navbar navbarlight bg-faded" ]
        [ a [ class "navbar-brand" ] [ text "RSSonate" ]
        , form [ class "form-inline", onSubmit AddFeedFormSubmitted ]
            [ input
                [ type_ "url"
                , value model.addFeedInput
                , onInput AddFeedInputChanged
                , placeholder "Enter an RSS URL..."
                , class "form-control"
                ]
                []
            ]
        , a
            [ class "navbar-text float-xs-right"
            , href "#"
            , onClick LogoutButtonClicked
            ]
            [ text "Logout" ]
        ]


page : Model -> List (Html Msg)
page model =
    let
        findBy selector items val =
            List.filter (\i -> selector i == val) items

        findById =
            findBy .id

        maybeFeed =
            model.currentFeed
                |> Maybe.map (findById model.feeds)
                |> Maybe.andThen List.head

        maybeFeedItem =
            model.currentFeedItem
                |> Maybe.map (findById model.feedItems)
                |> Maybe.andThen List.head

        feedItems =
            model.currentFeed
                |> Maybe.map (findBy .feed model.feedItems)
                |> Maybe.withDefault []

        refreshFeedsButton =
            button
                [ class "float-xs-right btn btn-sm btn-success"
                , onClick RefreshFeedsClicked
                ]
                [ refreshIcon <| RemoteStatus.isInProgress model.refreshingFeedsStatus ]

        collapseClass =
            if model.maximizeItemView then
                " collapse"
            else
                ""
    in
        [ div [ class <| "col-sm-3" ++ collapseClass ]
            [ div [ id "feeds-panel", class "card card-inverse" ]
                [ div [ class "card-header card-primary clearfix" ]
                    [ text "Feeds", refreshFeedsButton ]
                , feedsPanel model.feeds model.currentFeed
                ]
            ]
        , div [ class <| "col-sm-9" ++ collapseClass ]
            [ div [ id "items-panel", class "card card-inverse" ] <|
                itemsPanel maybeFeed
                    model.currentFeedItem
                    feedItems
                    model.isRefreshingFeed
                    model.refreshingFeedsStatus
            ]
        , div [ class "col-sm-12" ]
            [ div [ id "content-panel", class "card card-inverse" ] <|
                itemPanel maybeFeedItem feedItems
            ]
        ]


feedsPanel : List Feed -> Maybe FeedId -> Html Msg
feedsPanel feeds maybeFeedId =
    let
        feedItem feed =
            li [ class "nav-item", onClick <| SetCurrentFeed feed.id ]
                [ a [ class <| linkClass feed, href "#" ] [ text feed.title ] ]

        linkClass feed =
            if Just feed.id == maybeFeedId then
                "nav-link active"
            else
                "nav-link"
    in
        ul [ class "nav nav-pills nav-stacked" ] <|
            List.map feedItem feeds


itemsPanel : Maybe Feed -> Maybe FeedId -> List FeedItem -> Bool -> RemoteStatus.Model -> List (Html Msg)
itemsPanel maybeFeed maybeFeedItemId feedItems isRefreshingFeed refreshingFeedsStatus =
    let
        headerText =
            maybeFeed
                |> Maybe.map .title
                |> Maybe.withDefault "Select a Feed"

        refreshButton feed =
            button
                [ class "float-xs-right btn btn-sm btn-success"
                , onClick <| RefreshFeedClicked feed.id
                ]
                [ refreshIcon isRefreshingFeed ]

        refreshFeedsProgressBar percentage =
            div [ id "items-refresh-progress" ]
                [ div [ class "text-xs-center" ] [ text "Fetching the latest items..." ]
                , progress
                    [ class "progress"
                    , value <| toString percentage
                    , attribute "max" "100"
                    ]
                    []
                ]

        content =
            RemoteStatus.percentageCompleted refreshingFeedsStatus
                |> Maybe.map refreshFeedsProgressBar
                |> Maybe.withDefault (feedItemTable maybeFeedItemId feedItems)
    in
        [ div [ class "card-header card-primary clearfix" ]
            [ text headerText
            , maybeFeed |> Maybe.map refreshButton |> Maybe.withDefault (text "")
            ]
        , div [ class "card-block" ] [ content ]
        ]


feedItemTable : Maybe FeedItemId -> List FeedItem -> Html Msg
feedItemTable maybeItemId items =
    let
        rowClass item =
            if Just item.id == maybeItemId then
                "active clickable"
            else
                "clickable"

        formatDate =
            Maybe.map (Date.Format.format "%m/%d/%Y") >> Maybe.withDefault ""

        itemRow item =
            tr [ class <| rowClass item, onClick <| SetCurrentFeedItem item.id ]
                [ td [] [ a [ href "#" ] [ text item.title ] ]
                , td [] [ text <| formatDate item.published ]
                ]
    in
        if List.isEmpty items then
            text ""
        else
            table [ class "table table-sm table-striped table-hover" ]
                [ thead []
                    [ tr []
                        [ th [] [ text "Title" ]
                        , th [] [ text "Date" ]
                        ]
                    ]
                , tbody [] <| List.map itemRow items
                ]


itemPanel : Maybe FeedItem -> List FeedItem -> List (Html Msg)
itemPanel maybeItem feedItems =
    let
        itemLink =
            case maybeItem of
                Nothing ->
                    text ""

                Just item ->
                    a [ class "btn btn-primary", href item.link, target "_blank" ]
                        [ text "View on Site" ]

        headerText =
            maybeItem
                |> Maybe.map .title
                |> Maybe.withDefault "Select an Item"

        maximizeButton =
            if maybeItem == Nothing then
                text ""
            else
                button
                    [ class "btn btn-sm btn-default float-xs-right"
                    , onClick ToggleItemViewMaximized
                    ]
                    [ icon "arrows-alt" ]

        itemFooter =
            maybeItem
                |> Maybe.map (.id >> itemButtonGroup)
                |> Maybe.withDefault (text "")

        itemButton content mId =
            case mId of
                Nothing ->
                    button [ class "btn btn-primary", disabled True ]
                        [ text content ]

                Just id ->
                    button [ class "btn btn-primary", onClick <| SetCurrentFeedItem id ]
                        [ text content ]

        itemButtonGroup itemId =
            div [ class "card-footer text-xs-center" ]
                [ div [ class "btn-group" ]
                    [ previousItem feedItems itemId |> itemButton "Previous"
                    , itemLink
                    , nextItem feedItems itemId |> itemButton "Next"
                    ]
                ]
    in
        [ div [ class "card-header card-primary clearfix" ]
            [ text headerText
            , maximizeButton
            ]
        , itemDisplay maybeItem
        , itemFooter
        ]


itemDisplay : Maybe FeedItem -> Html Msg
itemDisplay maybeItem =
    let
        content =
            maybeItem
                |> Maybe.map (.description >> safeHtmlString)
                |> Maybe.withDefault (text "")
    in
        div [ class "card-block", id "content-block" ]
            [ content ]


previousItem : List { a | id : b } -> b -> Maybe b
previousItem list currentId =
    case list of
        [] ->
            Nothing

        x :: [] ->
            Nothing

        x :: y :: ys ->
            if y.id == currentId then
                Just x.id
            else
                previousItem (y :: ys) currentId


nextItem : List { a | id : b } -> b -> Maybe b
nextItem list currentId =
    case list of
        [] ->
            Nothing

        x :: [] ->
            Nothing

        x :: y :: ys ->
            if x.id == currentId then
                Just y.id
            else
                nextItem (y :: ys) currentId


refreshIcon : Bool -> Html msg
refreshIcon isRefreshing =
    if isRefreshing then
        icon "refresh fa-spin"
    else
        icon "refresh"


icon : String -> Html msg
icon name =
    node "i" [ class <| "fa fa-" ++ name ] []


safeHtmlString : String -> Html msg
safeHtmlString =
    Markdown.toHtml []
