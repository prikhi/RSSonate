module Model exposing (..)

import Auth
import Date
import Json.Decode as Decode
import RemoteStatus
import Set


type alias Model =
    { feeds : List Feed
    , feedItems : List FeedItem
    , authForm : Auth.Form
    , authStatus : Auth.Model
    , addFeedInput : String
    , currentFeed : Maybe FeedId
    , currentFeedItem : Maybe FeedItemId
    , maximizeItemView : Bool
    , isRefreshingFeed : Bool
    , refreshingFeedsStatus : RemoteStatus.Model
    , fetchedFeeds : Set.Set FeedId
    }


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
    , published : Maybe Date.Date
    , isUnread : Bool
    }


feedItemDecoder : Decode.Decoder FeedItem
feedItemDecoder =
    Decode.map7 FeedItem
        (Decode.field "id" Decode.int)
        (Decode.field "feed" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "link" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "published" (Decode.nullable decodeDate))
        (Decode.field "is_unread" Decode.bool)


decodeDate : Decode.Decoder Date.Date
decodeDate =
    let
        resultToDecoder result =
            case result of
                Ok v ->
                    Decode.succeed v

                Err e ->
                    Decode.fail e
    in
        Decode.string |> Decode.andThen (Date.fromString >> resultToDecoder)
