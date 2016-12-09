module Utils exposing (..)

{-| Utility functions used throughout the application.
-}

import Date exposing (Month(..))
import Html exposing (Html, node, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode


{- Html -}


{-| Return a FontAwesome icon, given it's name(`star`, `envelope-o`, etc.).
-}
icon : String -> Html msg
icon name =
    node "i" [ class <| "fa fa-" ++ name ] []


{-| Turn a Maybe value into Html or a blank Html node.
-}
maybeToHtml : Maybe a -> (a -> Html msg) -> Html msg
maybeToHtml maybeValue view =
    maybeValue |> Maybe.map view |> Maybe.withDefault (text "")



{- JSON -}
{- Decode a Date from a String. -}


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



{- Results -}


{-| Given a Result with the same types for it's Err & Ok states, return the nested value.
-}
mergeResult : Result a a -> a
mergeResult result =
    case result of
        Ok val ->
            val

        Err val ->
            val



{- Lists -}


{-| Update the first item that fulfills the predicate.
-}
updateOneWhere : (a -> Bool) -> (a -> a) -> List a -> List a
updateOneWhere pred update items =
    case items of
        [] ->
            []

        x :: xs ->
            if pred x then
                update x :: xs
            else
                x :: updateOneWhere pred update xs


{-| Update all items that fulfill the predicate.
-}
updateAllWhere : (a -> Bool) -> (a -> a) -> List a -> List a
updateAllWhere pred update items =
    case items of
        [] ->
            []

        x :: xs ->
            if pred x then
                update x :: updateAllWhere pred update xs
            else
                x :: updateAllWhere pred update xs


{-| Filter by a selector & target value.
-}
filterEquals : (a -> b) -> List a -> b -> List a
filterEquals selector items val =
    List.filter (\i -> selector i == val) items


{-| Given a selector, list & target value, return the first item matching the target value
-}
findBy : (a -> b) -> List a -> b -> Maybe a
findBy selector items val =
    case items of
        [] ->
            Nothing

        x :: xs ->
            if selector x == val then
                Just x
            else
                findBy selector xs val


{-| Update an item with the given id, returning the item if it was modified.
-}
getAndUpdateById :
    ({ a | id : b } -> { a | id : b })
    -> b
    -> List { a | id : b }
    -> ( Maybe { a | id : b }, List { a | id : b } )
getAndUpdateById f id items =
    case items of
        [] ->
            ( Nothing, [] )

        x :: xs ->
            if x.id == id && f x /= x then
                ( Just <| f x, f x :: xs )
            else
                getAndUpdateById f id xs
                    |> \( updated, updatedItems ) -> ( updated, x :: updatedItems )


{-| Given an `id`, return the item that comes before it in a List.
-}
previousItem : List { a | id : b } -> b -> Maybe b
previousItem list currentId =
    case list of
        [] ->
            Nothing

        x :: [] ->
            Nothing

        x :: y :: ys ->
            if y.id == currentId then
                Just x.id
            else
                previousItem (y :: ys) currentId


{-| Given an `id`, return the item that comes after it in a List.
-}
nextItem : List { a | id : b } -> b -> Maybe b
nextItem list currentId =
    case list of
        [] ->
            Nothing

        x :: [] ->
            Nothing

        x :: y :: ys ->
            if x.id == currentId then
                Just y.id
            else
                nextItem (y :: ys) currentId



{- Dates -}


{-| Return the number of the Month.
-}
monthNumber : Month -> Int
monthNumber month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12
