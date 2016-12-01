port module Commands exposing (..)

import Auth
import Dom
import Dom.Scroll as Scroll
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Messages exposing (Msg(..))
import Model exposing (FeedId, feedDecoder, feedItemDecoder)
import Task


port storeAuthToken : String -> Cmd msg


port removeAuthToken : () -> Cmd msg


port triggerResize : () -> Cmd msg


login : Auth.Form -> Cmd Msg
login form =
    HttpBuilder.post "/api/api-token-auth/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.withJsonBody
            (Encode.object
                [ ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                ]
            )
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.field "token" Decode.string)
        |> Http.send (Result.map .data >> AuthCompleted)


register : Auth.Form -> Cmd Msg
register form =
    HttpBuilder.post "/api/users/"
        |> HttpBuilder.withHeader "Accept" "application/json"
        |> HttpBuilder.withJsonBody
            (Encode.object
                [ ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                , ( "password_again", Encode.string form.passwordAgain )
                ]
            )
        |> HttpBuilder.toRequest (HttpBuilder.jsonReader <| Decode.field "token" Decode.string)
        |> Http.send (Result.map .data >> AuthCompleted)


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


newContentCommands : Cmd Msg
newContentCommands =
    Dom.focus "content-block"
        |> Task.andThen (\() -> Scroll.toTop "content-block")
        |> Task.attempt DomTaskCompleted
