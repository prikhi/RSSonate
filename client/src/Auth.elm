module Auth
    exposing
        ( Token
        , Model(..)
        , fromToken
        , toToken
        , Form
        , initalForm
        , Msg(..)
        , update
        , view
        )

{-| The `Auth` module is used to track the current token authentication state.

-}

import Html exposing (..)
import Html.Attributes exposing (type_, value, checked, class, id, placeholder, required, href, name)
import Html.Events exposing (onSubmit, onInput, onClick)


{-| An API Authentication Token
-}
type alias Token =
    String


{-| Possible Authentication States
-}
type Model
    = LoggingIn
    | Registering
    | Authorized Token


{-| Generate an Authentication State from a potential API Token.
-}
fromToken : Maybe Token -> Model
fromToken =
    Maybe.map Authorized >> Maybe.withDefault LoggingIn


{-| Generate a potential API Token from an Authentication State
-}
toToken : Model -> Maybe Token
toToken model =
    case model of
        Authorized token ->
            Just token

        _ ->
            Nothing


{-| The Login/Registration Form
-}
type alias Form =
    { username : String
    , password : String
    , passwordAgain : String
    , remember : Bool
    }


{-| Default to blank fields & not saving the session
-}
initalForm : Form
initalForm =
    { username = "", password = "", passwordAgain = "", remember = False }


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | PasswordAgainChanged String
    | RememberToggled
    | RegisterLinkClicked
    | LoginLinkClicked


{-| Update the Authentication State & the Login/Registraton Form.
-}
update : Msg -> Model -> Form -> ( Model, Form )
update msg model form =
    case msg of
        UsernameChanged newUser ->
            ( model, { form | username = newUser } )

        PasswordChanged newPass ->
            ( model, { form | password = newPass } )

        PasswordAgainChanged newPass ->
            ( model, { form | passwordAgain = newPass } )

        RememberToggled ->
            ( model, { form | remember = not form.remember } )

        RegisterLinkClicked ->
            ( Registering, { form | remember = False } )

        LoginLinkClicked ->
            ( LoggingIn, form )


{-| Render the Login/Registration Forms.
-}
view : (Msg -> msg) -> msg -> Model -> Form -> Html msg
view tagger submitMsg model form =
    div [ class "container" ]
        [ Html.form [ class "auth-form", onSubmit submitMsg ] <|
            [ h1 [ class "text-xs-center" ] [ text "RSSonate" ]
            , div [ class "text-muted text-xs-center" ]
                [ text "Your Friendly Neighboorhood RSS Reader" ]
            , inputs tagger model form
            ]
        ]


inputs : (Msg -> msg) -> Model -> Form -> Html msg
inputs tagger model form =
    let
        isRegistering =
            model == Registering

        againInput =
            if isRegistering then
                input
                    [ type_ "password"
                    , name "password_again"
                    , placeholder "Verify Password"
                    , class "form-control"
                    , onInput <| tagger << PasswordAgainChanged
                    , value form.passwordAgain
                    ]
                    []
            else
                text ""

        ( buttonText, formId ) =
            if isRegistering then
                ( "Register", "register-form" )
            else
                ( "Login", "login-form" )

        ( linkText, linkClick ) =
            if isRegistering then
                ( "Login", LoginLinkClicked )
            else
                ( "Register", RegisterLinkClicked )
    in
        div [ id formId ]
            [ input
                [ type_ "text"
                , placeholder "Username"
                , class "form-control mt-1"
                , onInput <| tagger << UsernameChanged
                , value form.username
                ]
                []
            , input
                [ type_ "password"
                , name "password"
                , placeholder "Password"
                , class "form-control"
                , onInput <| tagger << PasswordChanged
                , value form.password
                ]
                []
            , againInput
            , label [ class "mt-1" ]
                [ input
                    [ type_ "checkbox"
                    , checked form.remember
                    , onClick <| tagger RememberToggled
                    ]
                    []
                , text " Stay Logged In"
                ]
            , button [ class "btn btn-lg btn-primary btn-block", type_ "submit" ]
                [ text buttonText ]
            , div [ class "mt-1 float-xs-right" ]
                [ a [ href "#", onClick <| tagger linkClick ]
                    [ text linkText ]
                ]
            ]
