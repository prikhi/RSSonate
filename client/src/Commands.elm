port module Commands exposing (..)

import Dom
import Dom.Scroll as Scroll
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Messages exposing (Msg(..))
import Model exposing (FeedId, feedDecoder, feedItemDecoder)
import Process
import Task
import Time


port triggerResize : () -> Cmd msg


addFeed : String -> Cmd Msg
addFeed feedUrl =
    HttpBuilder.post "/api/feeds/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.withJsonBody (Encode.object [ ( "feed_url", Encode.string feedUrl ) ])
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader feedDecoder)
        |> Http.send (Result.map .data >> FeedAdded)


refreshFeed : FeedId -> Cmd Msg
refreshFeed id =
    HttpBuilder.put ("/api/feeds/" ++ toString id ++ "/refresh/")
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.field "results" <| Decode.list feedItemDecoder)
        |> Http.send (Result.map .data >> FeedRefreshed)


fetchFeeds : Cmd Msg
fetchFeeds =
    HttpBuilder.get "/api/feeds/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.list feedDecoder)
        |> Http.send (Result.map .data >> FeedsFetched)


fetchItemsForFeed : FeedId -> Cmd Msg
fetchItemsForFeed id =
    HttpBuilder.url "/api/feeditems/" [ ( "feed", toString id ) ]
        |> HttpBuilder.get
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.list feedItemDecoder)
        |> Http.send (Result.map .data >> FeedItemsFetched id)


scrollContentToTop : Cmd Msg
scrollContentToTop =
    Scroll.toTop "content-block"
        |> Task.attempt ContentScrolledToTop


focusContent : Cmd Msg
focusContent =
    Process.sleep (Time.millisecond * 100)
        |> Task.andThen (\_ -> Dom.focus "content-block")
        |> Task.attempt ContentFocused
