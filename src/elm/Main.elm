port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html               exposing (Html, article, button, div, h1, h2, h3, header, input, li, main_, section, text)
import Html.Attributes    exposing (value)
import Html.Events        exposing (onClick, onInput)
import Html.Keyed         as Keyed
import Html.Lazy          exposing (lazy)
import String.Format      as Format
import Url
import Url.Parser         exposing (Parser, (</>), map, oneOf, parse, s, string, top)

main : Program () Model Msg
main = Browser.application
    { init          = init
    , view          = view
    , update        = update
    , subscriptions = subscriptions
    , onUrlRequest  = UrlRequest
    , onUrlChange   = UrlChange
    }

type alias Model =
    { key         : Nav.Key
    , route       : Route
    , loading     : Bool
    , name        : String
    , helloText   : String
    , contentText : String
    , contents    : List String
    }

type Route
    = NotFoundPage
    | IndexPage
    | HelloPage String

type Msg
    = UrlRequest     Browser.UrlRequest
    | UrlChange      Url.Url
    | Navigate       String
    | SetLoading     Bool
    | SetName        String
    | SetContentText String
    | AddContent
    | RemoveContent  Int
    | SendHello      String
    | ReceiveHello   String

port loadingPort      : (Bool -> msg) -> Sub msg
port sendHelloPort    : String -> Cmd msg
port receiveHelloPort : (String -> msg) -> Sub msg

init : () -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
init _ url key =
    (Model key (toRoute url) True "world" (helloString "world") "content" [], Cmd.none)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        UrlRequest req ->
            case req of
                Browser.External href ->
                    (model, Nav.load href)
                Browser.Internal url ->
                    (model, Nav.pushUrl model.key (Url.toString url))
        UrlChange url ->
            let route = toRoute url in
                case route of
                    HelloPage name ->
                        ({ model | route = route, name = name }, Cmd.none)
                    _ ->
                        ({ model | route = route }, Cmd.none)
        Navigate url ->
            (model, Nav.pushUrl model.key url)
        SetLoading loading ->
            ({ model | loading = loading }, Cmd.none)
        SetName name ->
            ({ model | name = name }, Cmd.none)
        SetContentText text ->
            ({ model | contentText = text }, Cmd.none)
        AddContent ->
            ({ model | contents = model.contents ++ [ model.contentText] }, Cmd.none)
        RemoveContent index ->
            ({ model | contents = List.take index model.contents ++ List.drop (index + 1) model.contents }, Cmd.none)
        SendHello hello ->
            (model, sendHelloPort hello)
        ReceiveHello hello ->
            ({ model | helloText = hello }, Cmd.none)

toRoute : Url.Url -> Route
toRoute url =
    case parse routeParser url of
        Just page -> page
        Nothing   -> NotFoundPage

routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map IndexPage top
        , map (HelloPage "world") <| s "hello"
        , map HelloPage <| s "hello" </> string
        ]

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.batch [ loadingPort SetLoading, receiveHelloPort ReceiveHello ]

view : Model -> Browser.Document Msg
view model =
    { title =
        case model.route of
            NotFoundPage -> "Elm Page - Not Found"
            IndexPage    -> "Elm Page"
            HelloPage _  -> "Elm Page - {{ hello }}" |> Format.namedValue "hello" model.helloText
    , body =
        [ header []
            [ div []
                [ h1 [] [ text "Elm Page" ]
                ]
            ]
        , main_ []
            [
                if model.loading
                then lazy text "Loading..."
                else lazy viewRoute model
            ]
        ]
    }

viewRoute : Model -> Html Msg
viewRoute model =
    case model.route of
        NotFoundPage -> viewNotFoundPage model
        IndexPage    -> viewIndexPage    model
        HelloPage _  -> viewHelloPage    model

viewNotFoundPage : Model -> Html Msg
viewNotFoundPage _ =
    article []
        [ div []
            [ h1 [] [ text "Not Found" ]
            ]
        ]

viewIndexPage : Model -> Html Msg
viewIndexPage _ =
    article []
        [ div []
            [ button [ onClick <| Navigate "/hello" ] [ text "Hello" ]
            ]
        ]

viewHelloPage : Model -> Html Msg
viewHelloPage model =
    div []
        [ article []
            [ section []
                [ div []
                    [ h2 [] [ text <| model.helloText ]
                    , input [ value model.name, onInput SetName ] []
                    , button [ onClick <| SendHello <| helloString model.name ] [ text "Hello" ]
                    ]
                ]
            , section []
                [ div []
                    [ h3 [] [ text <| contentCountString <| List.length model.contents ]
                    , input [ value model.contentText, onInput SetContentText ] []
                    , button [ onClick AddContent ] [ text "Add one content" ]
                    , div []
                        [ lazy viewContents model
                        ]
                    ]
                ]
            ]
        ]

viewContents : Model -> Html Msg
viewContents model =
    Keyed.ul [] (List.indexedMap (\i content -> (content, li [ onClick <| RemoveContent i ] [ text content ])) model.contents)

helloString : String -> String
helloString name =
    "Hello, {{ name }}!"
    |> Format.namedValue "name"  name

contentCountString : Int -> String
contentCountString contentCount =
    "{{ count }} contents exist."
    |> Format.namedValue "count" (String.fromInt contentCount)
