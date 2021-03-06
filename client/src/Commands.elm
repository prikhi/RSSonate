port module Commands exposing (..)

import Auth
import Dom
import Dom.Scroll as Scroll
import Http
import HttpBuilder
import Json.Decode as Decode
import Json.Encode as Encode
import Messages exposing (Msg(..))
import Model exposing (Model, FeedId, FeedItemId, feedDecoder, feedItemDecoder)
import Set
import Task


port storeAuthToken : String -> Cmd msg


port removeAuthToken : () -> Cmd msg


port triggerResize : () -> Cmd msg


sendAnonRequest :
    (Result Http.Error a -> msg)
    -> Decode.Decoder a
    -> HttpBuilder.RequestBuilder
    -> Cmd msg
sendAnonRequest tagger decoder =
    HttpBuilder.withHeader "Accept" "application/json"
        >> HttpBuilder.toRequest (HttpBuilder.jsonReader decoder)
        >> Http.send (Result.map .data >> tagger)


sendAuthRequest :
    Auth.Token
    -> (Result Http.Error a -> msg)
    -> Decode.Decoder a
    -> HttpBuilder.RequestBuilder
    -> Cmd msg
sendAuthRequest token tagger decoder =
    HttpBuilder.withHeader "Authorization" ("Token " ++ token)
        >> sendAnonRequest tagger decoder


login : Auth.Form -> Cmd Msg
login form =
    HttpBuilder.post "/api/api-token-auth/"
        |> HttpBuilder.withJsonBody
            (Encode.object
                [ ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                ]
            )
        |> sendAnonRequest AuthCompleted (Decode.field "token" Decode.string)


register : Auth.Form -> Cmd Msg
register form =
    HttpBuilder.post "/api/users/"
        |> HttpBuilder.withJsonBody
            (Encode.object
                [ ( "username", Encode.string form.username )
                , ( "password", Encode.string form.password )
                , ( "password_again", Encode.string form.passwordAgain )
                ]
            )
        |> sendAnonRequest AuthCompleted (Decode.field "token" Decode.string)


addFeed : Auth.Token -> String -> Cmd Msg
addFeed token feedUrl =
    HttpBuilder.post "/api/feeds/"
        |> HttpBuilder.withJsonBody (Encode.object [ ( "feed_url", Encode.string feedUrl ) ])
        |> sendAuthRequest token FeedAdded feedDecoder


refreshFeed : Auth.Token -> FeedId -> Cmd Msg
refreshFeed token id =
    HttpBuilder.put ("/api/feeds/" ++ toString id ++ "/refresh/")
        |> sendAuthRequest token
            (FeedRefreshed id)
            (Decode.field "results" <| Decode.list feedItemDecoder)


fetchFeeds : Auth.Token -> Cmd Msg
fetchFeeds token =
    HttpBuilder.get "/api/feeds/"
        |> sendAuthRequest token FeedsFetched (Decode.list feedDecoder)


deleteFeed : Auth.Token -> FeedId -> Cmd Msg
deleteFeed token id =
    HttpBuilder.delete ("/api/feeds/" ++ toString id ++ "/")
        |> sendAuthRequest token FeedDeleted (Decode.succeed id)


fetchItemsForFeedOnce : Model -> FeedId -> Cmd Msg
fetchItemsForFeedOnce model id =
    if Set.member id model.fetchedFeeds then
        Cmd.none
    else
        Auth.mapToken model fetchItemsForFeed <| id


fetchItemsForFeed : Auth.Token -> FeedId -> Cmd Msg
fetchItemsForFeed token id =
    HttpBuilder.url "/api/feeditems/" [ ( "feed", toString id ) ]
        |> HttpBuilder.get
        |> sendAuthRequest token (FeedItemsFetched id) (Decode.list feedItemDecoder)


markFeedAsRead : Auth.Token -> FeedId -> Cmd Msg
markFeedAsRead token id =
    HttpBuilder.put ("/api/feeds/" ++ toString id ++ "/read/")
        |> sendAuthRequest token FeedMarkedRead (Decode.succeed id)


markItemAsRead : Auth.Token -> FeedItemId -> Cmd Msg
markItemAsRead token id =
    HttpBuilder.put ("/api/feeditems/" ++ toString id ++ "/read/")
        |> sendAuthRequest token FeedItemMarkedRead (Decode.succeed id)


markItemAsUnread : Auth.Token -> FeedItemId -> Cmd Msg
markItemAsUnread token id =
    HttpBuilder.put ("/api/feeditems/" ++ toString id ++ "/unread/")
        |> sendAuthRequest token FeedItemMarkedUnread (Decode.succeed id)


toggleItemFavorite : Auth.Token -> FeedItemId -> Cmd Msg
toggleItemFavorite token id =
    HttpBuilder.put ("/api/feeditems/" ++ toString id ++ "/favorite/")
        |> sendAuthRequest token FeedItemFavoriteToggled (Decode.succeed ())


focusItemsPanel : Cmd Msg
focusItemsPanel =
    Dom.focus "items-block"
        |> Task.andThen (\() -> Scroll.toTop "items-block")
        |> Task.attempt DomTaskCompleted


newContentCommands : Cmd Msg
newContentCommands =
    Dom.focus "content-block"
        |> Task.andThen (\() -> Scroll.toTop "content-block")
        |> Task.attempt DomTaskCompleted
