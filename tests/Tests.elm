module Tests exposing (all)

import Expect
import I18Next
    exposing
        ( Delims(..)
        , Replacements
        , Translations
        , initialTranslations
        , t
        , tf
        , tr
        , translationsDecoder
        , trf
        )
import Json.Decode as Decode
import Test exposing (..)


translationJsonEn : String
translationJsonEn =
    """{
    "buttons": {
      "save": "Save",
      "cancel": "Cancel"
    },
    "greetings": {
      "hello": "Hello",
      "goodDay": "Good Day {{firstName}} {{lastName}}"
    },
    "englishOnly": "This key only exists in english",
    "englishOnlyPlaceholder": "Only english with {{firstName}} {{lastName}}"
  }"""


translationJsonDe : String
translationJsonDe =
    """{
    "buttons": {
      "save": "Speichern",
      "cancel": "Abbrechen"
    },
    "greetings": {
      "hello": "Hallo",
      "goodDay": "Guten Tag {{firstName}} {{lastName}}"
    }
  }"""


invalidTranslationJson : String
invalidTranslationJson =
    """{ "age": 12  }"""


translationsEn : Translations
translationsEn =
    Decode.decodeString translationsDecoder translationJsonEn
        |> Result.withDefault initialTranslations


translationsDe : Translations
translationsDe =
    Decode.decodeString translationsDecoder translationJsonDe
        |> Result.withDefault initialTranslations


langList : List Translations
langList =
    [ translationsDe, translationsEn ]


delims =
    ( "{{", "}}" )


replacements : Replacements
replacements =
    [ ( "firstName", "Peter" ), ( "lastName", "Griffin" ) ]


invalidReplacements : Replacements
invalidReplacements =
    [ ( "nonExstingPlaceholder", "Peter" )
    , ( "nonExstingPlaceholder", "Griffin" )
    ]


all : Test
all =
    describe "The I18Next Module"
        [ decode
        , translate
        , translateWithPlaceholders
        , translateWithFallback
        , translateWithPlaceholdersAndFallback
        ]


decode : Test
decode =
    describe "translationsDecoder"
        [ test "decodes a translation JSON" <|
            \() ->
                case Decode.decodeString translationsDecoder translationJsonEn of
                    Ok _ ->
                        Expect.pass

                    Err err ->
                        Expect.fail <| Decode.errorToString err
        , test "fails if it gets an invalid translations JSON" <|
            \() ->
                case Decode.decodeString translationsDecoder invalidTranslationJson of
                    Ok _ ->
                        Expect.fail "Decoding passed but should have failed."

                    Err err ->
                        Expect.pass
        ]


translate : Test
translate =
    describe "the t function"
        [ test "returns the translation for a key if it exists" <|
            \() ->
                t translationsEn "buttons.save" |> Expect.equal "Save"
        , test "returns the key if it doesn not exists" <|
            \() ->
                t translationsEn "some.non-existing.key"
                    |> Expect.equal "some.non-existing.key"
        ]


translateWithPlaceholders : Test
translateWithPlaceholders =
    describe "the tr function"
        [ test "translates and replaces placeholders" <|
            \() ->
                tr translationsEn Curly "greetings.goodDay" replacements
                    |> Expect.equal "Good Day Peter Griffin"
        , test "tr does not replace if the match can't be found" <|
            \() ->
                tr translationsEn Curly "greetings.goodDay" invalidReplacements
                    |> Expect.equal "Good Day {{firstName}} {{lastName}}"
        , test "tr returns the key if it doesn not exists" <|
            \() ->
                tr translationsEn Curly "some.non-existing.key" replacements
                    |> Expect.equal "some.non-existing.key"
        ]


translateWithFallback : Test
translateWithFallback =
    describe "the tf function"
        [ test "uses the german when the key exists" <|
            \() ->
                tf langList "greetings.hello"
                    |> Expect.equal "Hallo"
        , test "uses english as a fallback" <|
            \() ->
                tf langList "englishOnly"
                    |> Expect.equal "This key only exists in english"
        , test "uses the key if none is found" <|
            \() ->
                tf langList "some.non-existing.key"
                    |> Expect.equal "some.non-existing.key"
        ]


translateWithPlaceholdersAndFallback : Test
translateWithPlaceholdersAndFallback =
    describe "the trf function"
        [ test "uses the german when the key exists" <|
            \() ->
                trf langList Curly "greetings.hello" replacements
                    |> Expect.equal "Hallo"
        , test "uses english as a fallback" <|
            \() ->
                trf langList Curly "englishOnly" replacements
                    |> Expect.equal "This key only exists in english"
        , test "uses the key if none is found" <|
            \() ->
                trf langList Curly "some.non-existing.key" replacements
                    |> Expect.equal "some.non-existing.key"
        , test "translates and replaces in german when key is found" <|
            \() ->
                trf langList Curly "greetings.goodDay" replacements
                    |> Expect.equal "Guten Tag Peter Griffin"
        , test "translates and replaces in fallback when key is not found" <|
            \() ->
                trf langList Curly "englishOnlyPlaceholder" replacements
                    |> Expect.equal "Only english with Peter Griffin"
        ]
