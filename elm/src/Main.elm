module Main exposing (..)

import Html exposing (Html)
import Html.Attributes exposing (type_, value, placeholder)
import Html.Events exposing (onSubmit, onInput, onClick)
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Markdown


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }



{- Model -}


type alias Model =
    { feeds : List Feed
    , feedItems : List FeedItem
    , addFeedInput : String
    , currentFeed : Maybe FeedId
    , currentFeedItem : Maybe FeedItemId
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


type alias FeedId =
    Int


type alias Feed =
    { id : FeedId
    , feedUrl : String
    , title : String
    , description : String
    , channelLink : String
    }


feedDecoder : Decode.Decoder Feed
feedDecoder =
    Decode.map5 Feed
        (Decode.field "id" Decode.int)
        (Decode.field "feed_url" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "channel_link" Decode.string)


type alias FeedItemId =
    Int


type alias FeedItem =
    { id : FeedItemId
    , feed : FeedId
    , title : String
    , link : String
    , description : String
    }


feedItemDecoder : Decode.Decoder FeedItem
feedItemDecoder =
    Decode.map5 FeedItem
        (Decode.field "id" Decode.int)
        (Decode.field "feed" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "link" Decode.string)
        (Decode.field "description" Decode.string)



{- Update -}


type alias HttpData a =
    Result Http.Error a


type Msg
    = AddFeedInputChanged String
    | AddFeedFormSubmitted
    | SetCurrentFeed FeedId
    | SetCurrentFeedItem FeedItemId
    | FeedAdded (HttpData Feed)
    | FeedsFetched (HttpData (List Feed))
    | FeedItemsFetched (HttpData (List FeedItem))


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
            ( { model | currentFeedItem = Just id }, Cmd.none )

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


addFeed : String -> Cmd Msg
addFeed feedUrl =
    HttpBuilder.post "/api/feeds/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.withJsonBody (Encode.object [ ( "feed_url", Encode.string feedUrl ) ])
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader feedDecoder)
        |> Http.send (Result.map .data >> FeedAdded)


fetchFeeds : Cmd Msg
fetchFeeds =
    HttpBuilder.get "/api/feeds/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.field "results" <| Decode.list feedDecoder)
        |> Http.send (Result.map .data >> FeedsFetched)


fetchFeedItems : Cmd Msg
fetchFeedItems =
    HttpBuilder.get "/api/feeditems/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.field "results" <| Decode.list feedItemDecoder)
        |> Http.send (Result.map .data >> FeedItemsFetched)



{- View -}


view : Model -> Html Msg
view model =
    let
        feeds =
            Html.ul [] <| List.map feedListItem model.feeds

        items =
            model.currentFeed
                |> Maybe.map (feedItemsList model)
                |> Maybe.withDefault (Html.text "")

        item =
            model.currentFeedItem
                |> Maybe.andThen (itemDisplay model)
                |> Maybe.withDefault (Html.text "")
    in
        Html.div []
            [ Html.form [ onSubmit AddFeedFormSubmitted ]
                [ Html.input
                    [ type_ "url"
                    , value model.addFeedInput
                    , onInput AddFeedInputChanged
                    , placeholder "Enter an RSS URL..."
                    ]
                    []
                ]
            , feeds
            , items
            , item
            ]


feedListItem : Feed -> Html Msg
feedListItem feed =
    Html.li [ onClick <| SetCurrentFeed feed.id ] [ Html.text feed.title ]


feedItemsList : Model -> FeedId -> Html Msg
feedItemsList model feedId =
    let
        items =
            List.filter (\fi -> fi.feed == feedId) model.feedItems

        itemLi i =
            Html.li [ onClick <| SetCurrentFeedItem i.id ] [ Html.text i.title ]
    in
        Html.ul [] <| List.map itemLi items


itemDisplay : Model -> FeedItemId -> Maybe (Html Msg)
itemDisplay model itemId =
    let
        mItem =
            List.filter (\fi -> fi.id == itemId) model.feedItems |> List.head
    in
        Maybe.map (\item -> Html.p [] [ safeHtmlString item.description ]) mItem


safeHtmlString : String -> Html msg
safeHtmlString =
    Markdown.toHtml []
