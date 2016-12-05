module Messages exposing (..)

import Auth
import Dom
import Http
import Model exposing (FeedId, Feed, FeedItemId, FeedItem)


type alias HttpData a =
    Result Http.Error a


type Msg
    = AuthFormMsg Auth.Msg
    | AuthFormSubmitted
    | AddFeedInputChanged String
    | AddFeedFormSubmitted
    | LogoutButtonClicked
    | SetCurrentFeed FeedId
    | SetCurrentFeedItem FeedItemId
    | FavoritesButtonClicked
    | RefreshFeedsClicked
    | RefreshFeedClicked FeedId
    | MarkFeedReadClicked FeedId
    | ToggleItemViewMaximized
    | ToggleItemIsFavorite FeedItemId
    | MarkUnreadButtonClicked FeedItemId
    | DomTaskCompleted (Result Dom.Error ())
    | AuthCompleted (HttpData Auth.Token)
    | FeedAdded (HttpData Feed)
    | FeedRefreshed FeedId (HttpData (List FeedItem))
    | FeedsFetched (HttpData (List Feed))
    | FeedMarkedRead (HttpData FeedId)
    | FeedItemsFetched FeedId (HttpData (List FeedItem))
    | FeedItemMarkedRead (HttpData FeedItemId)
    | FeedItemMarkedUnread (HttpData FeedItemId)
    | FeedItemFavoriteToggled (HttpData ())
