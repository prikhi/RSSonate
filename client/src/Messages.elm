module Messages exposing (..)

import Dom
import Http
import Model exposing (FeedId, Feed, FeedItemId, FeedItem)


type alias HttpData a =
    Result Http.Error a


type Msg
    = AddFeedInputChanged String
    | AddFeedFormSubmitted
    | SetCurrentFeed FeedId
    | SetCurrentFeedItem FeedItemId
    | RefreshFeedsClicked
    | RefreshFeedClicked FeedId
    | ToggleItemViewMaximized
    | ContentScrolledToTop (Result Dom.Error ())
    | ContentFocused (Result Dom.Error ())
    | FeedAdded (HttpData Feed)
    | FeedRefreshed (HttpData (List FeedItem))
    | FeedsFetched (HttpData (List Feed))
    | FeedItemsFetched FeedId (HttpData (List FeedItem))
