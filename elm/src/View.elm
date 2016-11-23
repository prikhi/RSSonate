module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (type_, value, placeholder, class, href, id, target, disabled)
import Html.Events exposing (onSubmit, onInput, onClick)
import Markdown
import Messages exposing (Msg(..))
import Model exposing (Model, FeedId, Feed, FeedItemId, FeedItem)


view : Model -> Html Msg
view model =
    div []
        [ navbar model
        , div [ class "container-fluid" ]
            [ div [ class "row" ] <| page model
            ]
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
        ]


page : Model -> List (Html Msg)
page model =
    let
        maybeFeed =
            model.currentFeed
                |> Maybe.map (\feedId -> List.filter (\feed -> feed.id == feedId) model.feeds)
                |> Maybe.andThen List.head

        maybeFeedItem =
            model.currentFeedItem
                |> Maybe.map (\itemId -> List.filter (\item -> item.id == itemId) model.feedItems)
                |> Maybe.andThen List.head

        feedItems =
            model.currentFeed
                |> Maybe.map (\feedId -> List.filter (\feedItem -> feedItem.feed == feedId) model.feedItems)
                |> Maybe.withDefault []
    in
        [ div [ class "col-sm-3" ]
            [ div [ id "feeds-panel", class "card card-inverse" ]
                [ div [ class "card-header card-primary" ] [ text "Feeds" ]
                , feedsPanel model.feeds model.currentFeed
                ]
            ]
        , div [ class "col-sm-9" ]
            [ div [ id "items-panel", class "card card-inverse" ] <|
                itemsPanel maybeFeed model.currentFeedItem feedItems
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


itemsPanel : Maybe Feed -> Maybe FeedId -> List FeedItem -> List (Html Msg)
itemsPanel maybeFeed maybeFeedItemId feedItems =
    let
        itemsHeader =
            maybeFeed
                |> Maybe.map .title
                |> Maybe.withDefault "Select a Feed"
    in
        [ div [ class "card-header card-primary" ] [ text itemsHeader ]
        , div [ class "card-block" ] [ feedItemTable maybeFeedItemId feedItems ]
        ]


feedItemTable : Maybe FeedItemId -> List FeedItem -> Html Msg
feedItemTable maybeItemId items =
    let
        rowClass item =
            if Just item.id == maybeItemId then
                "active clickable"
            else
                "clickable"

        itemRow item =
            tr [ class <| rowClass item, onClick <| SetCurrentFeedItem item.id ]
                [ td [] [ text item.title ] ]
    in
        if List.isEmpty items then
            text ""
        else
            table [ class "table table-sm table-striped table-hover" ]
                [ thead [] [ tr [] [ th [] [ text "Title" ] ] ]
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

        itemHeader =
            maybeItem
                |> Maybe.map .title
                |> Maybe.withDefault "Select an Item"

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
        [ div [ class "card-header card-primary" ] [ text itemHeader ]
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


safeHtmlString : String -> Html msg
safeHtmlString =
    Markdown.toHtml []
