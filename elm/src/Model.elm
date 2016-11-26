module Model exposing (..)

import Json.Decode as Decode
import RemoteStatus


type alias Model =
    { feeds : List Feed
    , feedItems : List FeedItem
    , addFeedInput : String
    , currentFeed : Maybe FeedId
    , currentFeedItem : Maybe FeedItemId
    , maximizeItemView : Bool
    , isRefreshingFeed : Bool
    , refreshingFeedsStatus : RemoteStatus.Model
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
    }


feedItemDecoder : Decode.Decoder FeedItem
feedItemDecoder =
    Decode.map5 FeedItem
        (Decode.field "id" Decode.int)
        (Decode.field "feed" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "link" Decode.string)
        (Decode.field "description" Decode.string)
