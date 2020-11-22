# https://www.mediawiki.org/wiki/Help:Formatting
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=mediawiki %{
    require-module mediawiki
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window mediawiki-.+ }
}

hook -group mediawiki-load-languages global WinSetOption filetype=mediawiki %{
    hook -group mediawiki-load-languages window NormalIdle .* mediawiki-load-languages
    hook -group mediawiki-load-languages window InsertIdle .* mediawiki-load-languages
}

hook -group mediawiki-highlight global WinSetOption filetype=mediawiki %{
    add-highlighter window/mediawiki ref mediawiki
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/mediawiki }
}


provide-module mediawiki %§

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/mediawiki regions
add-highlighter shared/mediawiki/default default-region group

evaluate-commands %sh{
    languages="asciidoc awk cabal c cpp clojure cmake coffee coq crystal css
        cucumber cue dart dhall diff d dockerfile elixir elm eruby exherbo fish
        fsharp gas gluon go haml haskell hbs html i3 ini java javascript jinja
        json julia just kak kickstart latex ledger lisp lua makefile markdown
        mercurial meson mlb moon nim nix objc ocaml perl php pony protobuf pug
        python ragel restructuredtext r ruby rust sass scala scheme scss sh sml
        sql swift terraform toml troff tupfile yaml zig"
    for lang in $languages; do
        printf 'addhl shared/mediawiki/%s region <syntaxhighlight.*?lang\s*=\s*["'\'']?%s["'\'']?.*?> </syntaxhighlight> group\n' "$lang" "$lang"
        printf 'addhl shared/mediawiki/%s/r regions\n' "$lang"
        [ "$lang" = kak ] && ref=kakrc || ref="$lang"
        printf 'addhl shared/mediawiki/%s/r/ region >\K(.*) (?=<) ref %s\n' "$lang" "$ref"
        printf 'addhl shared/mediawiki/%s/tags regex (<(syntaxhighlight).*?>).*(</(syntaxhighlight)>) 1:string 2:+b 3:string 4:+b\n' "$lang"
    done
}

addhl shared/mediawiki/deflist      region '^[#*:;]*;' $ group
addhl shared/mediawiki/deflist/bold regex  '^[#*:]*;(.+)' 1:+b
addhl shared/mediawiki/deflist/bullet regex '^[#*:;]+' 0:bullet

addhl shared/mediawiki/boldital  region "'''''"  "('''''|$)" group
addhl shared/mediawiki/bold      region "'''"      "('''|$)" group
addhl shared/mediawiki/italics   region "''"  "((?<!')''(?!')|$)" group
addhl shared/mediawiki/boldital/ fill +bi
addhl shared/mediawiki/bold/     fill +b
addhl shared/mediawiki/italics/  fill +i
addhl shared/mediawiki/bold/italics regex "...(''[^\n]*?'')..." 1:+i
addhl shared/mediawiki/italics/bold regex "..('''[^\n]*?''').." 1:+b

addhl shared/mediawiki/comment  region <!-- --> fill comment

addhl shared/mediawiki/verbatim region -match-capture <(nowiki|pre).*?> </(nowiki|pre)> group
addhl shared/mediawiki/verbatim/tags regex (<(nowiki|pre).*?>).*(</(nowiki|pre)>) 1:string 2:+b 3:string 4:+b

# See https://en.wikipedia.org/wiki/WP:MATH
addhl shared/mediawiki/math region -match-capture '<(math( chem)?|chem).*?>' '</(math( chem)?|chem)>' group
addhl shared/mediawiki/math/macro regex '\\[a-zA-Z0-9]+\b' 0:keyword
addhl shared/mediawiki/math/option regex '\\[a-zA-Z0-9]+\b\[([^\]]+)\]' 1:value
addhl shared/mediawiki/math/tags regex '(<(math( chem)?|chem).*?>).*(</(math( chem)?|chem)>)' 1:string 2:+b 4:string 5:+b

# wikilink, e.g. [[Article|display text]] or [[File:logo.svg|thumb|description]]
addhl shared/mediawiki/wikilink region -recurse \[\[ \[\[ \]\] group
addhl shared/mediawiki/wikilink/link regex \[\[([^\]\[\|]+) 1:link
addhl shared/mediawiki/wikilink/brackets regex \]\]|\[\[ 0:+a@link

# external link, e.g. [https://www.example.com/ example.com]
# [a-z0-9.-]+: is the URI scheme, // is for protocol-relative URLs
addhl shared/mediawiki/extlink region \[([a-zA-Z0-9.-]+:|//)[^\n]+?(?=\]) \] group
addhl shared/mediawiki/extlink/link regex '\[([^ \]]+).*?\]' 1:link
addhl shared/mediawiki/extlink/brackets regex (\[).*?(\]) 1:+ab@link  2:+ab@link

# parameter in a template, e.g. {{{name|default}}}
addhl shared/mediawiki/parameter region -recurse \{\{\{ \{\{\{  \}\}\} group
addhl shared/mediawiki/parameter/ fill attribute
addhl shared/mediawiki/parameter/name regex \{\{\{(.*?)(\||\}\}\}) 1:+b

# template, e.g. {{template|argument|key=value}}
addhl shared/mediawiki/template region -recurse \{\{ \{\{ \}\} group
addhl shared/mediawiki/template/ fill value
addhl shared/mediawiki/template/name regex (?<!\{)\{\{(?!\{)\s*(((msg|raw|msgnw|(safe)?subst||):)?[^\n]*?)\n*[:|\}] 1:+bu
addhl shared/mediawiki/template/key  regex \|\s*\w+\h*= 0:+b

addhl shared/mediawiki/table region ^\h*\{\| ^\h*\|\} group
addhl shared/mediawiki/table/ fill type
addhl shared/mediawiki/table/theader regex ^\h*!.*?$ 0:+b

addhl shared/mediawiki/h6 region ^={6}[^\n]+?(?=======\n) (={6}$|$) group
addhl shared/mediawiki/h6/ fill header
addhl shared/mediawiki/h5 region ^={5}[^\n]+?(?======\n) (={5}$|$) group
addhl shared/mediawiki/h5/ fill header
addhl shared/mediawiki/h4 region ^={4}[^\n]+?(?=====\n) (={4}$|$) group
addhl shared/mediawiki/h4/ fill header
addhl shared/mediawiki/h3 region ^={3}[^\n]+?(?====\n) (={3}$|$) group
addhl shared/mediawiki/h3/ fill header
addhl shared/mediawiki/h2 region ^={2}[^\n]+?(?===\n) (={2}$|$) group
addhl shared/mediawiki/h2/ fill header
addhl shared/mediawiki/h1 region ^=[^\n]+?(?==\n) (=$|$) group
addhl shared/mediawiki/h1/ fill title

# Allow some highlighting in certain regions
evaluate-commands %sh¶
    all='deflist boldital bold italics h1 h2 h3 h4 h5 h6 wikilink extlink template table parameter'

    for region in default $all; do
        # See https://en.wikipedia.org/wiki/HTML_entity
        printf "addhl shared/mediawiki/%s/entity regex '&(#[0-9]{1,4}|#x[0-9a-fA-F]{1,4}|[a-zA-Z]+);' 0:string\n" "$region"
        printf "addhl shared/mediawiki/%s/tag    regex </?([a-zA-Z]+).*?> 0:string 1:+b\n" "$region"
        printf "addhl shared/mediawiki/%s/magic  regex __[A-Z]{3,}__|~~~~? 0:keyword\n" "$region"
    done

    for region in $all; do
        printf "addhl shared/mediawiki/%s/r regions\n" "$region"
        printf "addhl shared/mediawiki/%s/r/comment  region <!-- --> fill comment\n" "$region"
        printf "addhl shared/mediawiki/%s/r/verbatim region -match-capture <(nowiki|pre).*?> </(nowiki|pre)> ref mediawiki/verbatim\n" "$region"

        # prevent recursion
        [ "$region" != parameter ] && printf "addhl shared/mediawiki/%s/r/parameter region -recurse \{\{\{ \{\{\{  \}\}\} ref mediawiki/parameter\n" "$region"
        [ "$region" != template ] && printf "addhl shared/mediawiki/%s/r/template region -recurse \{\{ \{\{ \}\} ref mediawiki/template\n" "$region"
        [ "$region" != wikilink ] && printf "addhl shared/mediawiki/%s/r/wikilink region -recurse \[\[ \[\[ \]\] ref mediawiki/wikilink\n" "$region"
        [ "$region" != extlink  ] && printf "addhl shared/mediawiki/%s/r/extlink region (?<!\[)\[([a-zA-Z0-9.-]+:|//)[^\\\n]+?(?=\]) \] ref mediawiki/extlink\n" "$region"
    done

    for region in default parameter template table; do
        printf "addhl shared/mediawiki/%s/bullet regex '^[#*:;]+' 0:bullet\n" "$region"
        printf "addhl shared/mediawiki/%s/pre    regex '^ ' 0:default,rgb:666666\n" "$region"
        # whitespace is allowed before table start
        printf "addhl shared/mediawiki/%s/notpre regex '^\h*\{\|' 0:+g\n" "$region"
    done

    for region in parameter template table; do
        # whitespace is allowed before table marks and parameter seperator
        printf "addhl shared/mediawiki/%s/notpre2 regex '^\h*[|!]' 0:+g\n" "$region"
        printf "addhl shared/mediawiki/%s/r/deflist region '^[#*:]*;' $ ref mediawiki/deflist\n" "$region"
    done

    for region in wikilink template table deflist extlink h1 h2 h3 h4 h5 h6; do
        printf "addhl shared/mediawiki/%s/r/boldital region \"'''''\" \"'''''\" ref mediawiki/boldital\n" "$region"
        printf "addhl shared/mediawiki/%s/r/bold     region \"'''\"     \"'''\" ref mediawiki/bold\n" "$region"
        printf "addhl shared/mediawiki/%s/r/italics  region \"''\" \"(?<!')''(?!')\" ref mediawiki/italics\n" "$region"
    done

    for region in parameter wikilink table; do
        printf "addhl shared/mediawiki/%s/r/h6 region ^={6}[^\\\n]+?(?=======\\\n) (={6}$|$) ref mediawiki/h6\n" "$region"
        printf "addhl shared/mediawiki/%s/r/h5 region ^={5}[^\\\n]+?(?======\\\n)  (={5}$|$) ref mediawiki/h5\n" "$region"
        printf "addhl shared/mediawiki/%s/r/h4 region ^={4}[^\\\n]+?(?=====\\\n)   (={4}$|$) ref mediawiki/h4\n" "$region"
        printf "addhl shared/mediawiki/%s/r/h3 region ^={3}[^\\\n]+?(?====\\\n)    (={3}$|$) ref mediawiki/h3\n" "$region"
        printf "addhl shared/mediawiki/%s/r/h2 region ^={2}[^\\\n]+?(?===\\\n)     (={2}$|$) ref mediawiki/h2\n" "$region"
        printf "addhl shared/mediawiki/%s/r/h1 region ^=[^\\\n]+?(?==\\\n)            (=$|$) ref mediawiki/h1\n" "$region"
    done
¶

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden mediawiki-load-languages %{
    evaluate-commands -draft %{ try %{
        execute-keys 'gtGbGls<lt>syntaxhighlight.*?lang\s*=\s*["'']?\K[^"''\s>]+<ret>s[^"'']+<ret>'
        evaluate-commands -itersel %{ require-module %val{selection} }
    }}
}
§
