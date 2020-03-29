module Main exposing (main)

import Browser
import Html            exposing (Html, div, h1, input, text)
import Html.Attributes exposing (value)
import Html.Events     exposing (onInput)
import String.Format

main : Program () Model Msg
main = Browser.sandbox
    { init   = init
    , update = update
    , view   = view
    }

type alias Model =
    { greeting     : String
    , name         : String
    , greetingName : String
    }

init : Model
init = greet <| Model "Hello" "world" ""

greet : Model -> Model
greet model = { model | greetingName =
    "{{ greeting }}, {{ name }}!"
    |> String.Format.namedValue "greeting" model.greeting
    |> String.Format.namedValue "name"     model.name
    }

type Msg
    = SetGreeting String
    | SetName     String

update : Msg -> Model -> Model
update msg model =
    case msg of
        SetGreeting greeting ->
            greet { model | greeting = greeting }

        SetName name ->
            greet { model | name = name }

view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text <| model.greetingName ]
        , input [ value model.greeting, onInput SetGreeting ] []
        , input [ value model.name    , onInput SetName     ] []
        ]
