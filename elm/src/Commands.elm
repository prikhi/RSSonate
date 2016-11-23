port module Commands exposing (..)

import Dom.Scroll as Scroll
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Messages exposing (Msg(..))
import Model exposing (feedDecoder, feedItemDecoder)
import Task


port triggerResize : () -> Cmd msg


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


scrollContentToTop : Cmd Msg
scrollContentToTop =
    Scroll.toTop "content-block"
        |> Task.attempt ContentScrolledToTop
