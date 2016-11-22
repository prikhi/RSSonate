module Main exposing (..)

import Html exposing (Html)
import Http
import Json.Decode as Decode


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
    }


init : ( Model, Cmd Msg )
init =
    ( { feeds = []
      , feedItems = []
      }
    , fetchFeeds
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



{- Update -}


type Msg
    = FeedsFetched (Result Http.Error (List Feed))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FeedsFetched (Ok feeds) ->
            ( { model | feeds = feeds }, Cmd.none )

        FeedsFetched (Err _) ->
            ( model, Cmd.none )


fetchFeeds : Cmd Msg
fetchFeeds =
    Http.get "//localhost:8000/feeds/"
        (Decode.field "results" (Decode.list feedDecoder))
        |> Http.send FeedsFetched



{- View -}


view : Model -> Html Msg
view model =
    Html.ul [] <| List.map (\f -> Html.li [] [ Html.text f.title ]) model.feeds
